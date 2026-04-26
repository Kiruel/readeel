#!/usr/bin/env python3
"""
Readeel — Best Sellers Import Script
======================================
Imports best-selling book metadata from NYT and Google Books APIs.
Uses a local Ollama model to transform descriptions into engaging vertical feed excerpts.

Requirements:
  pip install psycopg2-binary requests python-dotenv

Usage:
  export NYT_API_KEY="your_api_key_here"  # Or put it in .env
  python import_bestsellers.py
"""

import os
import requests
import psycopg2
from dotenv import load_dotenv
import logging
import time
from typing import Optional

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("readeel-bestsellers")

# Load environment variables (from .env if present)
load_dotenv()

# ─── Configuration ────────────────────────────────────────────────────────────

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 8090)),
    "dbname": os.getenv("DB_NAME", "readeel"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "jRIpX1MqCjy8qKhmml3Kk-GZXr-x_1fT"),
}

NYT_API_KEY = os.getenv("NYT_API_KEY")
NYT_LISTS = [
    "hardcover-fiction",
    "hardcover-nonfiction",
    "young-adult-hardcover"
]

# Ollama settings
_ollama_host = os.getenv("OLLAMA_HOST", "localhost")
OLLAMA_URL = f"http://{_ollama_host}:11434/api/generate"
OLLAMA_MODEL = "gemma4:latest"
OLLAMA_TIMEOUT = 120

EXCERPT_MAX_WORDS = 150

# ─── Database Setup ───────────────────────────────────────────────────────────

def get_connection():
    return psycopg2.connect(**DB_CONFIG)

# ─── Ollama Excerpt Generation ────────────────────────────────────────────────

def check_ollama() -> bool:
    """Verify the Ollama server is running and the model is available."""
    try:
        base_url = OLLAMA_URL.rsplit('/', 2)[0]
        r = requests.get(base_url, timeout=5)
        if r.status_code != 200:
            return False
        r = requests.post(OLLAMA_URL, json={
            "model": OLLAMA_MODEL,
            "prompt": "Hello",
            "stream": False
        }, timeout=60)
        return r.status_code == 200
    except requests.RequestException as e:
        log.error(f"Cannot reach Ollama at {OLLAMA_URL}: {e}")
        return False

def generate_hook_via_ollama(description: str, book_title: str, book_author: str) -> Optional[str]:
    """
    Ask the local Ollama model to transform the book description into an engaging hook.
    """
    if not description or len(description) < 50:
        return None

    prompt = f"""You are an expert literary editor writing high-impact, dramatic hooks for 'Readeel', a premium mobile app. Readeel features a swipeable, vertical feed of book excerpts (similar to Reels/TikTok).

TASK:
Craft exactly ONE captivating, dramatic passage using the provided book description/synopsis below. It should feel like an engaging, tense narrative hook that makes the reader instantly want to dive into the book. It must read like an excerpt from a professionally written hook or the dramatic back-cover blurb.

STRICT CONSTRAINTS:
1. MAX LENGTH: Exactly {EXCERPT_MAX_WORDS} words maximum. Keep it punchy.
2. TONE: Adapt the tone of the description. If it's a thriller, make it tense. If romance, make it sweeping and emotional.
3. STANDALONE QUALITY: Must draw the reader in immediately.
4. CLEANLINESS: Return ONLY the hook text. Do not include chapter titles, intro text, surrounding quotes, or any commentary. No "Here is the excerpt".

BOOK DETAILS:
Title: "{book_title}"
Author: {book_author}

DESCRIPTION / SYNOPSIS:
{description}
"""
    try:
        response = requests.post(OLLAMA_URL, json={
            "model": OLLAMA_MODEL,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": 0.7,
                "top_p": 0.9,
            }
        }, timeout=OLLAMA_TIMEOUT)

        if response.status_code == 200:
            text = response.json().get("response", "").strip()
            
            # Clean up potential leading/trailing quotes inserted by the model
            if text.startswith('"') and text.endswith('"'):
                text = text[1:-1].strip()
            return text
        else:
            log.error(f"Ollama returned HTTP {response.status_code}")
    except Exception as e:
        log.error(f"Ollama error on hook generation for '{book_title}': {e}")
    return None


# ─── APIs Fetching ─────────────────────────────────────────────────────────────

def fetch_nyt_bestsellers(list_name: str) -> list[dict]:
    """Fetch best sellers from NYT."""
    log.info(f"Fetching NYT Best Sellers for list: {list_name}")
    url = f"https://api.nytimes.com/svc/books/v3/lists/current/{list_name}.json?api-key={NYT_API_KEY}"
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            data = response.json()
            books = data.get("results", {}).get("books", [])
            log.info(f"  -> Found {len(books)} books.")
            return books
        else:
            log.error(f"  -> Failed to fetch NYT list {list_name}: {response.status_code} {response.text}")
    except Exception as e:
        log.error(f"  -> Error fetching NYT list {list_name}: {e}")
    
    return []

def fetch_google_books_metadata(title: str, author: str) -> Optional[dict]:
    """Fetch description and cover image from Google Books API."""
    url = f"https://www.googleapis.com/books/v1/volumes?q=intitle:{requests.utils.quote(title)}+inauthor:{requests.utils.quote(author)}&langRestrict=en"
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            data = response.json()
            items = data.get("items", [])
            if items:
                info = items[0].get("volumeInfo", {})
                
                # Best quality image
                image_links = info.get("imageLinks", {})
                cover_url = image_links.get("extraLarge") or image_links.get("large") or image_links.get("thumbnail")
                if cover_url and "http:" in cover_url:
                    cover_url = cover_url.replace("http:", "https:")

                # Replace &edge=curl
                if cover_url:
                    cover_url = cover_url.replace("&edge=curl", "")

                description = info.get("description", "")
                isbn = None
                for idx in info.get("industryIdentifiers", []):
                    if idx.get("type") == "ISBN_13":
                        isbn = idx.get("identifier")
                
                return {
                    "cover_url": cover_url,
                    "description": description,
                    "isbn": isbn,
                    "published_year": info.get("publishedDate", "")[:4] if info.get("publishedDate") else None
                }
    except Exception as e:
        log.error(f"  -> Google Books API error for {title}: {e}")
    
    return None

# ─── Main Pipeline ────────────────────────────────────────────────────────────

def main():
    log.info("🚀 Readeel Bestsellers Import Script starting...")

    if not NYT_API_KEY:
        log.error("❌ NYT_API_KEY environment variable is not set. Please get a free key from developer.nytimes.com and add it to your .env file or environment.")
        return

    log.info(f"🔍 Checking Ollama ({OLLAMA_MODEL}) at {OLLAMA_URL}...")
    if not check_ollama():
        log.error("❌ Ollama is not available. Please run: ollama serve")
        return
    log.info("✅ Ollama is ready.")

    conn = get_connection()
    stats = {"inserted": 0, "excerpts": 0, "skipped": 0}

    with conn.cursor() as cur:
        for list_name in NYT_LISTS:
            books = fetch_nyt_bestsellers(list_name)
            
            for b in books:
                title = b.get("title", "").title()
                author = b.get("author", "")
                primary_isbn = b.get("primary_isbn13")
                external_id = f"nyt_{primary_isbn}"

                # Check if already imported
                cur.execute("""SELECT id FROM books WHERE source='nyt' AND "externalId"=%s""", (external_id,))
                if cur.fetchone():
                    log.info(f"  [SKIPPED] {title} by {author} (Already in DB)")
                    stats["skipped"] += 1
                    continue

                log.info(f"  [PROCESSING] {title} by {author}")
                
                # Fetch metadata
                gb_meta = fetch_google_books_metadata(title, author)
                if not gb_meta:
                    log.warning("    -> Could not fetch Google Books metadata. Skipping.")
                    stats["skipped"] += 1
                    time.sleep(1) # avoid spamming
                    continue

                cover_url = gb_meta["cover_url"]
                description = gb_meta["description"]
                published_year = gb_meta["published_year"]

                try:
                    published_year = int(published_year) if published_year else None
                except:
                    published_year = None

                # Generate engaging hook via LLM
                hook_excerpt = generate_hook_via_ollama(description, title, author)
                
                if hook_excerpt:
                    # Insert book
                    cur.execute("""
                        INSERT INTO books (title, author, description, "coverUrl", isbn, "publishedYear", language, source, "externalId", "isPublicDomain")
                        VALUES (%s, %s, %s, %s, %s, %s, 'en', 'nyt', %s, FALSE)
                        RETURNING id
                    """, (title, author, description, cover_url, primary_isbn, published_year, external_id))
                    
                    book_id = cur.fetchone()[0]
                    stats["inserted"] += 1

                    # Insert excerpt
                    cur.execute("""
                        INSERT INTO excerpts ("bookId", content, position)
                        VALUES (%s, %s, %s)
                    """, (book_id, hook_excerpt, 0))
                    
                    stats["excerpts"] += 1
                    conn.commit()
                    log.info("    -> Hook generated and saved!")
                else:
                    log.warning("    -> Failed to generate hook (Description might be too short). Escaping insertion.")
                    stats["skipped"] += 1
                    conn.rollback()

                # Rate limiting to respect public APIs
                time.sleep(2)

    conn.close()

    log.info("")
    log.info("📊 Final stats:")
    log.info(f"   Books Inserted: {stats['inserted']}")
    log.info(f"   Hooks Inserted: {stats['excerpts']}")
    log.info(f"   Skipped       : {stats['skipped']}")
    log.info("")
    log.info("✅ Import complete!")

if __name__ == "__main__":
    main()

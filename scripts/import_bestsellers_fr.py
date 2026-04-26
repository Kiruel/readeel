#!/usr/bin/env python3
"""
Readeel — French Best Sellers Import Script
===========================================
Imports best-selling book metadata from SensCritique (French market) and Google Books APIs.
Uses a local Ollama model to transform descriptions into engaging vertical feed excerpts.

Requirements:
  pip install psycopg2-binary requests python-dotenv beautifulsoup4

Usage:
  python import_bestsellers_fr.py
"""

import os
import re
import requests
import psycopg2
from bs4 import BeautifulSoup
from dotenv import load_dotenv
import logging
import time
from typing import Optional

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("readeel-bestsellers-fr")

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

SENSCRITIQUE_LISTS = [
    "https://www.senscritique.com/liste/Les_50_meilleures_ventes_livres_de_la_semaine/72033",
    "https://www.senscritique.com/livres/tops/top100-des-top10",
    "https://www.senscritique.com/livres/tops/top111",
    "https://www.senscritique.com/liste/les_100_livres_qu_il_faut_avoir_lus/1825852",
    "https://www.senscritique.com/liste/les_100_romans_preferes_des_francais/3175819",
    "https://www.senscritique.com/liste/Le_maitre_du_suspense_Thrillers_Polars/2967115"
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

def generate_hook_via_ollama(description: str, book_title: str) -> Optional[str]:
    """
    Ask the local Ollama model to transform the book description into an engaging hook.
    """
    if not description or len(description) < 50:
        return None

    prompt = f"""Tu es un expert en édition littéraire spécialisé dans la rédaction de pitchs très courts et percutants pour 'Readeel', une application premium. Readeel propose un flux vertical de pitchs de livres (façon Reels/TikTok).

TACHE:
Rédige EXACTEMENT UN court passage narratif dramatique et accrocheur en utilisant la description du livre ci-dessous. Le résultat doit donner instantanément envie de lire le livre, comme une accroche de quatrième de couverture très tendue. Il doit être rédigé en FRANÇAIS.

CONTRAINTES:
1. LONGUEUR: Strictement {EXCERPT_MAX_WORDS} mots maximum. Sois percutant.
2. TON: Adapte-toi au contenu. Thriller = tendu, Romance = émotionnel.
3. AUTONOMIE: Le texte doit se suffire à lui-même.
4. PROPRETÉ: Renvoie UNIQUEMENT le texte de l'accroche. Aucun commentaire, aucun "Voici l'accroche".

LIVRE: "{book_title}"

DESCRIPTION:
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
            if text.startswith('"') and text.endswith('"'):
                text = text[1:-1].strip()
            return text
        else:
            log.error(f"Ollama returned HTTP {response.status_code}")
    except Exception as e:
        log.error(f"Ollama error on hook generation for '{book_title}': {e}")
    return None


# ─── APIs Fetching ─────────────────────────────────────────────────────────────

def fetch_french_bestsellers() -> list[str]:
    """Fetch best sellers and popular books from SensCritique by scraping the DOM."""
    log.info(f"Fetching French Popular Books from SensCritique lists...")
    headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'}
    books = []
    
    for url in SENSCRITIQUE_LISTS:
        log.info(f"  -> Scraping: {url}")
        try:
            response = requests.get(url, headers=headers, timeout=10)
            if response.status_code == 200:
                soup = BeautifulSoup(response.text, 'html.parser')
                links = soup.select('a[href^="/livre/"]')
                for link in links:
                    title_raw = link.text.strip()
                    if title_raw and title_raw.lower() != "livres":
                        # Clean e.g. "Une unique lueur (2026)" -> "Une unique lueur"
                        clean_title = re.sub(r'\s*\(\d{4}\)$', '', title_raw).strip()
                        if clean_title and clean_title not in books:
                            books.append(clean_title)
            else:
                log.error(f"    -> Failed to fetch SensCritique list: {response.status_code}")
        except Exception as e:
            log.error(f"    -> Error fetching SensCritique list: {e}")
        time.sleep(1) # respectful delay between scrapes
    
    log.info(f"  -> Total Found: {len(books)} unique books across all lists.")
    return books

def fetch_google_books_metadata(title: str) -> Optional[dict]:
    """Fetch description, author, and cover image from Google Books API."""
    url = f"https://www.googleapis.com/books/v1/volumes?q=intitle:{requests.utils.quote(title)}&langRestrict=fr"
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            data = response.json()
            items = data.get("items", [])
            if items:
                info = items[0].get("volumeInfo", {})
                
                authors = info.get("authors", ["Unknown Author"])
                author = authors[0] if authors else "Unknown Author"

                # Best quality image
                image_links = info.get("imageLinks", {})
                cover_url = image_links.get("extraLarge") or image_links.get("large") or image_links.get("thumbnail")
                if cover_url and "http:" in cover_url:
                    cover_url = cover_url.replace("http:", "https:")
                if cover_url:
                    cover_url = cover_url.replace("&edge=curl", "")

                description = info.get("description", "")
                isbn = None
                for idx in info.get("industryIdentifiers", []):
                    if idx.get("type") == "ISBN_13":
                        isbn = idx.get("identifier")
                
                return {
                    "title": info.get("title", title),
                    "author": author,
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
    log.info("🚀 Readeel French Bestsellers Import Script starting...")

    log.info(f"🔍 Checking Ollama ({OLLAMA_MODEL}) at {OLLAMA_URL}...")
    if not check_ollama():
        log.error("❌ Ollama is not available. Please run: ollama serve")
        return
    log.info("✅ Ollama is ready.")

    conn = get_connection()
    stats = {"inserted": 0, "excerpts": 0, "skipped": 0}

    with conn.cursor() as cur:
        book_titles = fetch_french_bestsellers()
        
        for raw_title in book_titles:
            # We don't have primary ISBN yet, but we'll use title for deduplication temporarily
            # Better to use externalId properly once GB returns ISBN
            log.info(f"  [PROCESSING] {raw_title}")
            
            gb_meta = fetch_google_books_metadata(raw_title)
            if not gb_meta:
                log.warning(f"    -> Could not fetch Google Books metadata for '{raw_title}'. Skipping.")
                stats["skipped"] += 1
                time.sleep(1)
                continue

            title = gb_meta["title"]
            author = gb_meta["author"]
            cover_url = gb_meta["cover_url"]
            description = gb_meta["description"]
            primary_isbn = gb_meta["isbn"]
            published_year = gb_meta["published_year"]

            # If no ISBN, we make one up from title hashing or use title
            external_id = f"fr_{primary_isbn}" if primary_isbn else f"fr_{abs(hash(title))}"

            try:
                published_year = int(published_year) if published_year else None
            except:
                published_year = None

            # Check if already imported
            cur.execute("""SELECT id FROM books WHERE source='senscritique' AND "externalId"=%s""", (external_id,))
            if cur.fetchone():
                log.info(f"    -> [SKIPPED] {title} by {author} (Already in DB)")
                stats["skipped"] += 1
                continue

            # Generate engaging hook via LLM
            hook_excerpt = generate_hook_via_ollama(description, title)
            
            if hook_excerpt:
                cur.execute("""
                    INSERT INTO books (title, author, description, "coverUrl", isbn, "publishedYear", language, source, "externalId", "isPublicDomain")
                    VALUES (%s, %s, %s, %s, %s, %s, 'fr', 'senscritique', %s, FALSE)
                    RETURNING id
                """, (title[:500], author[:300], description, cover_url, primary_isbn, published_year, external_id))
                
                book_id = cur.fetchone()[0]
                stats["inserted"] += 1

                cur.execute("""
                    INSERT INTO excerpts ("bookId", content, position)
                    VALUES (%s, %s, %s)
                """, (book_id, hook_excerpt, 0))
                
                stats["excerpts"] += 1
                conn.commit()
                log.info("    -> Hook generated and saved!")
            else:
                log.warning("    -> Failed to generate hook (Description might be too short). Skipping insertion.")
                stats["skipped"] += 1
                conn.rollback()

            time.sleep(1.5)

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

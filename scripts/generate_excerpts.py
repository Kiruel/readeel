#!/usr/bin/env python3
"""
Readeel — Excerpt Generation Script
=====================================
Reads books with content from the database and uses a local Ollama model
to generate engaging, self-contained excerpts for the Readeel vertical feed.

Requirements:
  pip install psycopg2-binary requests tqdm

Usage:
  ollama serve   # in a separate terminal
  python generate_excerpts.py
"""

import os
import requests
import psycopg2
from psycopg2.extras import execute_values
from tqdm import tqdm
import threading
from concurrent.futures import ThreadPoolExecutor
from psycopg2 import pool
import logging
import time

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("readeel-excerpts")

# ─── Configuration ────────────────────────────────────────────────────────────

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 8090)),
    "dbname": os.getenv("DB_NAME", "readeel"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "jRIpX1MqCjy8qKhmml3Kk-GZXr-x_1fT"),
}

# Ollama settings
# Tip: Set OLLAMA_HOST environment variable to point to another machine
# Example: export OLLAMA_HOST=192.168.1.50
_ollama_host = os.getenv("OLLAMA_HOST", "localhost")
OLLAMA_URL = f"http://{_ollama_host}:11434/api/generate"
OLLAMA_MODEL = "gemma4:latest"
OLLAMA_TIMEOUT = 180  # seconds per excerpt request

# How many excerpts to generate per book
EXCERPTS_PER_BOOK = 3

# Max number of books to process in this run
# Set to an integer to limit (e.g. 5 for testing), or None to process ALL books with content
MAX_BOOKS_TO_PROCESS = 1000

# Chunk size (chars) fed to the model per excerpt request (~2000 words)
# Increased to give the model more context to find a high-quality standalone passage.
CHUNK_SIZE = 12000

# Only regenerate excerpts for books that have none yet
SKIP_BOOKS_WITH_EXCERPTS = True

# Excerpt word count bounds used in the LLM prompt
EXCERPT_MAX_WORDS = 250

# Language filter (e.g., 'fr', 'en', or None for all)
TARGET_LANGUAGE = "fr"


# ─── Ollama ───────────────────────────────────────────────────────────────────

def check_ollama() -> bool:
    """Verify the Ollama server is running and the model is available."""
    try:
        # Check base URL
        base_url = OLLAMA_URL.rsplit('/', 2)[0]
        r = requests.get(base_url, timeout=5)
        if r.status_code != 200:
            return False
        # Warm-up ping to ensure model is loaded
        r = requests.post(OLLAMA_URL, json={
            "model": OLLAMA_MODEL,
            "prompt": "Hello",
            "stream": False
        }, timeout=60)
        return r.status_code == 200
    except requests.RequestException as e:
        log.error(f"Cannot reach Ollama at {OLLAMA_URL}: {e}")
        return False


def find_in_source(excerpt: str, content: str, tolerance: int = 50) -> str | None:
    """
    Verify that the excerpt exists verbatim (or near-verbatim) in the source content.
    Returns the verified excerpt or None if not found.
    """
    # Try exact match first
    if excerpt in content:
        return excerpt

    # Try trimming whitespace/newlines from both ends gradually
    stripped = excerpt.strip()
    if stripped in content:
        return stripped

    # Try matching on just the first and last sentences as anchors
    lines = [l.strip() for l in stripped.split("\n") if l.strip()]
    if not lines:
        return None

    first_line = lines[0][:80]
    start_pos = content.find(first_line)
    if start_pos == -1:
        return None

    # Found the start anchor — extract a slice of similar length from source
    end_pos = start_pos + len(stripped) + tolerance
    return content[start_pos:end_pos].strip()


def generate_excerpt_via_ollama(chunk: str, book_title: str, book_author: str, position: int, total: int) -> str | None:
    """
    Ask the local Ollama model to extract one compelling, self-contained excerpt
    from the given text chunk.
    """
    prompt = f"""You are an expert literary editor selecting high-impact passages for 'Readeel', a premium mobile app. Readeel features a swipeable, vertical feed of book excerpts (similar to Reels/TikTok).

TASK:
Identify and extract EXACTLY ONE continuous passage from the SOURCE TEXT below that works as a standalone, engaging reading experience.

STRICT CONSTRAINTS:
1. VERBATIM COPY: You must copy the text WORD FOR WORD, CHARACTER FOR CHARACTER. No editing, no paraphrasing, no summarizing.
2. LENGTH: The excerpt MUST be at most {EXCERPT_MAX_WORDS} words total.
3. STANDALONE QUALITY: The passage must be compelling and make sense to someone who has never heard of this book. It should draw the reader in immediately.
4. BOUNDARIES:
   - Start EXACTLY at the beginning of a sentence (Capital letter).
   - End EXACTLY at the end of a sentence (with punctuation like . ! or ?).
5. CLEANLINESS: Return ONLY the raw text. Do not include chapter titles, page numbers, intro text ("Here is your excerpt"), or any commentary.

BOOK DETAILS:
Title: "{book_title}"
Author: {book_author}

SOURCE TEXT:
{chunk}
"""
    try:
        response = requests.post(OLLAMA_URL, json={
            "model": OLLAMA_MODEL,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": 0.4,
                "top_p": 0.9,
            }
        }, timeout=OLLAMA_TIMEOUT)

        if response.status_code == 200:
            raw_text = response.json().get("response", "").strip()

            # Verify it is genuinely from the source — not hallucinated
            verified = find_in_source(raw_text, chunk)
            if verified and len(verified) >= 150:
                return verified
            else:
                log.warning(f"  Excerpt {position} not verified in source — falling back to raw chunk slice.")
                # Fallback: extract a clean slice directly from the chunk
                para_end = chunk.find("\n\n", 200)
                end = para_end if 200 < para_end < 2500 else 2000
                return chunk[:end].strip()
        else:
            log.error(f"  Ollama returned HTTP {response.status_code}")
    except requests.Timeout:
        log.error(f"  Ollama timed out on excerpt {position}")
    except Exception as e:
        log.error(f"  Ollama error on excerpt {position}: {e}")
    return None


# ─── Excerpt Generation ───────────────────────────────────────────────────────

def pick_chunks(content: str, n: int) -> list[str]:
    """
    Split the book content into n evenly-spaced chunks, each of CHUNK_SIZE chars.
    Tries to start at a paragraph boundary for cleaner input.
    """
    content = content.strip()
    total = len(content)
    step = total // (n + 1)
    chunks = []

    for i in range(1, n + 1):
        start = step * i
        # Snap to nearest paragraph break (max 500 chars seeking)
        para = content.find("\n\n", start)
        if para == -1 or para > start + 500:
            para = start
        end = para + CHUNK_SIZE
        chunk = content[para:end].strip()
        if chunk:
            chunks.append(chunk)

    return chunks


def clean_excerpt(text: str) -> str | None:
    """
    Ensure the excerpt starts with an uppercase letter, ends with punctuation,
    and is within the configured word count bounds.
    Returns None if the excerpt cannot be salvaged.
    """
    import re
    text = text.strip()
    if not text:
        return None

    # ── Trim the START to the first uppercase letter ──────────────────────────
    match = re.search(r'(?:^|(?<=[.!?"»\n])\s*)([A-ZÀÂÄÉÈÊËÎÏÔÙÛÜÇ«"])', text)
    if match:
        text = text[match.start():].strip()
    else:
        text = text[0].upper() + text[1:] if text else text

    # ── If too many words, trim to the last sentence ≤ EXCERPT_MAX_WORDS ──────
    words = text.split()
    if len(words) > EXCERPT_MAX_WORDS:
        # Build a version capped at EXCERPT_MAX_WORDS words
        truncated = " ".join(words[:EXCERPT_MAX_WORDS])
        last_punct = max(truncated.rfind('.'), truncated.rfind('!'), truncated.rfind('?'), truncated.rfind('»'))
        if last_punct > len(truncated) // 2:
            text = truncated[:last_punct + 1].strip()
        else:
            text = truncated.strip()

    # ── Trim the END to the last sentence-ending punctuation ──────────────────
    last_punct = max(text.rfind('.'), text.rfind('!'), text.rfind('?'), text.rfind('»'))
    if last_punct > len(text) // 2:
        text = text[:last_punct + 1].strip()

    # ── Final check ───────────────────────────────────────────────────────────
    word_count = len(text.split())
    log.info(f"    📏 Word count: {word_count} (max: {EXCERPT_MAX_WORDS})")
    return text


def process_single_excerpt_task(task, db_pool, stats):
    """Worker function to process a single excerpt task."""
    book_id = task["book_id"]
    title = task["title"]
    author = task["author"]
    chunk = task["chunk"]
    idx = task["idx"]
    total_chunks = task["total_chunks"]

    # Try up to 3 times in case of network/timeout errors
    for attempt in range(3):
        conn = db_pool.getconn()
        try:
            with conn.cursor() as cur:
                excerpt_text = generate_excerpt_via_ollama(chunk, title, author, idx + 1, total_chunks)

                if excerpt_text:
                    excerpt_text = clean_excerpt(excerpt_text)
                    
                    if excerpt_text:
                        cur.execute("""
                            INSERT INTO excerpts ("bookId", content, position)
                            VALUES (%s, %s, %s)
                            ON CONFLICT ("bookId", position) DO UPDATE SET content = EXCLUDED.content
                        """, (book_id, excerpt_text, idx))
                        conn.commit()
                        
                        with stats["lock"]:
                            stats["generated"] += 1
                        return  # Success
        except Exception as e:
            log.warning(f"  Attempt {attempt + 1} failed for '{title}' (chunk {idx}): {e}")
            if attempt < 2:
                time.sleep(2) # Wait before retry
        finally:
            db_pool.putconn(conn)


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    log.info("🚀 Readeel Excerpt Generation Script starting...")

    # 1. Verify Ollama
    log.info(f"🔍 Checking Ollama ({OLLAMA_MODEL}) at {OLLAMA_URL}...")
    if not check_ollama():
        log.error("❌ Ollama is not available. Please run: ollama serve")
        log.error(f"   Then ensure the model is pulled: ollama pull {OLLAMA_MODEL}")
        return
    log.info("✅ Ollama is ready.")

    # 2. Connect to DB
    conn = psycopg2.connect(**DB_CONFIG)

    # 3. Fetch books
    with conn.cursor() as cur:
        # Base query parts
        where_clauses = ["b.content IS NOT NULL"]
        query_params = []

        if TARGET_LANGUAGE:
            where_clauses.append("b.language = %s")
            query_params.append(TARGET_LANGUAGE)

        if SKIP_BOOKS_WITH_EXCERPTS:
            where_clauses.append("""
                NOT EXISTS (
                    SELECT 1 FROM excerpts e WHERE e."bookId" = b.id
                )
            """)

        where_str = " AND ".join(where_clauses)
        query = f"""
            SELECT b.id, b.title, b.author, b.content
            FROM books b
            WHERE {where_str}
            ORDER BY b.id
            LIMIT %s
        """
        query_params.append(MAX_BOOKS_TO_PROCESS)

        cur.execute(query, tuple(query_params))
        books = cur.fetchall()

    log.info(f"📚 Found {len(books)} books to process.")

    # 4. Prepare tasks (flatten all book chunks into a single task list)
    tasks = []
    for book in books:
        book_id, title, author, content = book
        if not content or len(content) < 500:
            log.warning(f"  Skipping '{title}' — content too short.")
            continue
            
        chunks = pick_chunks(content, EXCERPTS_PER_BOOK)
        for idx, chunk in enumerate(chunks):
            tasks.append({
                "book_id": book_id,
                "title": title,
                "author": author,
                "chunk": chunk,
                "idx": idx,
                "total_chunks": len(chunks)
            })

    if not tasks:
        log.info("Done: No new chunks to process.")
        return

    log.info(f"⚡ Processing {len(tasks)} excerpts in parallel...")

    # 5. Initialize Connection Pool
    # We allocate up to 'threads' connections. 
    # High concurrency can crash Ollama with large models; 2 is a safe default.
    threads = 2 
    db_pool = pool.ThreadedConnectionPool(1, threads + 1, **DB_CONFIG)

    stats = {
        "generated": 0,
        "lock": threading.Lock()
    }

    # 6. Run parallel executor
    try:
        with ThreadPoolExecutor(max_workers=threads) as executor:
            # Wrap in list() to consume the generator and wait for completion
            list(tqdm(executor.map(lambda t: process_single_excerpt_task(t, db_pool, stats), tasks), 
                      total=len(tasks), desc="Excerpts", unit="excerpt"))
    finally:
        db_pool.closeall()

    total_excerpts = stats["generated"]

    # Final stats
    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM books")
        book_count = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM excerpts")
        excerpt_count = cur.fetchone()[0]

    log.info("")
    log.info("📊 Final stats:")
    log.info(f"   Books in DB      : {book_count:,}")
    log.info(f"   Excerpts in DB   : {excerpt_count:,}")
    log.info(f"   Generated this run: {total_excerpts:,}")
    log.info("")
    log.info("✅ Excerpt generation complete!")

    conn.close()


if __name__ == "__main__":
    main()

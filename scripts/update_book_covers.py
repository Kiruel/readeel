#!/usr/bin/env python3
"""
Readeel — Update Book Covers Script
===================================
Fetches and updates only the coverUrl for existing Gutenberg books in the database.
"""

import os
import requests
import psycopg2
from psycopg2 import pool
from concurrent.futures import ThreadPoolExecutor
from tqdm import tqdm
import threading
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("update-covers")

# ─── Configuration ────────────────────────────────────────────────────────────

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 8090)),
    "dbname": os.getenv("DB_NAME", "readeel"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "jRIpX1MqCjy8qKhmml3Kk-GZXr-x_1fT"),
}

# ─── Gutendex API ─────────────────────────────────────────────────────────────

GUTENDEX_CACHE: dict = {}
cache_lock = threading.Lock()

# Use a connection pool per thread to avoid DNS resolution errors
thread_local = threading.local()

def get_session():
    if not hasattr(thread_local, "session"):
        thread_local.session = requests.Session()
        # Optional: configure retries to be robust
        adapter = requests.adapters.HTTPAdapter(pool_connections=1, pool_maxsize=1, max_retries=3)
        thread_local.session.mount("https://", adapter)
    return thread_local.session

def fetch_gutendex_cover(gutenberg_id: str) -> str | None:
    """Generate the standard Gutenberg cover URL directly without API limits."""
    # Gutenberg strictly uses this standard folder structure for cover images
    # By mathematically formatting the URL, we skip the 429 Too Many Requests bans!
    cover_url = f"https://www.gutenberg.org/cache/epub/{gutenberg_id}/pg{gutenberg_id}.cover.medium.jpg"
    print(f"Generated URL: {cover_url}")
    return cover_url

# ─── Update Process ───────────────────────────────────────────────────────────

def process_single_book(book, db_pool, stats):
    """Worker function to process a single book."""
    conn = db_pool.getconn()

    try:
        db_id = book[0]
        gutenberg_id = str(book[1])
        current_cover = book[2]
        cover_url = fetch_gutendex_cover(gutenberg_id)
        
        if cover_url and cover_url != current_cover:
            with conn.cursor() as cur:
                cur.execute("""
                    UPDATE books SET "coverUrl"=%s WHERE id=%s
                """, (cover_url, db_id))
            conn.commit()
            with stats["lock"]:
                stats["updated"] += 1
            log.info(f"  [{gutenberg_id}] Updated cover: {cover_url}")
        else:
            with stats["lock"]:
                stats["skipped"] += 1
            log.info(f"  [{gutenberg_id}] Skipped (no cover or already set)")
                
    except Exception as e:
        log.warning(f"Error processing Gutenberg book {gutenberg_id}: {e}")
        with stats["lock"]:
            stats["skipped"] += 1
    finally:
        db_pool.putconn(conn)


def main():
    log.info("🚀 Starting cover updates...")

    conn = psycopg2.connect(**DB_CONFIG)
    with conn.cursor() as cur:
        # We only target rows that are from gutenberg and currently lack a cover URL.
        # If you want to force an update on all books, remove the `AND "coverUrl" IS NULL` condition.
        cur.execute("""
            SELECT id, "externalId", "coverUrl" 
            FROM books 
            WHERE source = 'gutenberg' AND "coverUrl" IS NULL
        """)
        books = cur.fetchall()
    conn.close()

    log.info(f"Found {len(books)} Gutenberg books missing covers in DB.")
    
    if not books:
        log.info("No books to process. Exiting.")
        return

    # Initialize connection pool for threads
    db_pool = pool.ThreadedConnectionPool(1, 20, **DB_CONFIG)
    
    stats = {
        "updated": 0,
        "skipped": 0,
        "lock": threading.Lock()
    }

    # Process in parallel using 20 threads to apply the mathematically generated URL fast
    threads = 20
    with ThreadPoolExecutor(max_workers=threads) as executor:
        list(tqdm(executor.map(lambda b: process_single_book(b, db_pool, stats), books), 
                  total=len(books), desc="Updating Covers"))

    db_pool.closeall()
    log.info(f"✅ Finished: {stats['updated']} updated, {stats['skipped']} skipped")

if __name__ == "__main__":
    main()

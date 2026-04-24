#!/usr/bin/env python3
"""
Readeel — Data Import Script
=============================
Imports books and excerpts from:
  1. Project Gutenberg (full text, public domain)
  2. Open Library Data Dumps (metadata)

Requirements:
  pip install psycopg2-binary requests gutenbergpy tqdm
"""

import os
import json
import gzip
import requests
import psycopg2
from psycopg2.extras import execute_values
from tqdm import tqdm
from gutenbergpy.gutenbergcache import GutenbergCache
from gutenbergpy.textget import get_text_by_id, strip_headers
import threading
from concurrent.futures import ThreadPoolExecutor
from psycopg2 import pool
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("readeel-import")

# ─── Configuration ────────────────────────────────────────────────────────────

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 8090)),
    "dbname": os.getenv("DB_NAME", "readeel"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "jRIpX1MqCjy8qKhmml3Kk-GZXr-x_1fT"),
}

OPEN_LIBRARY_WORKS_DUMP = "ol_dump_works_latest.txt.gz"
OPEN_LIBRARY_DUMP_URL = "https://openlibrary.org/data/ol_dump_works_latest.txt.gz"

# Max books to import per source (set to None for all)
MAX_BOOKS_GUTENBERG = 80000
MAX_BOOKS_OPENLIBRARY = 10


# ─── Database Setup ───────────────────────────────────────────────────────────

def get_connection():
    return psycopg2.connect(**DB_CONFIG)


def create_tables(conn):
    """Create tables if they don't exist (mirrors Serverpod models)."""
    with conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS books (
                id SERIAL PRIMARY KEY,
                title TEXT NOT NULL,
                author TEXT NOT NULL,
                description TEXT,
                cover_url TEXT,
                isbn TEXT,
                published_year INT,
                language TEXT NOT NULL DEFAULT 'en',
                source TEXT NOT NULL,
                external_id TEXT NOT NULL,
                is_public_domain BOOLEAN NOT NULL DEFAULT FALSE,
                UNIQUE(source, external_id)
            );

            CREATE INDEX IF NOT EXISTS books_title_idx ON books(title);
            CREATE INDEX IF NOT EXISTS books_author_idx ON books(author);
            CREATE INDEX IF NOT EXISTS books_language_idx ON books(language);

            CREATE TABLE IF NOT EXISTS excerpts (
                id SERIAL PRIMARY KEY,
                book_id INT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
                content TEXT NOT NULL,
                position INT NOT NULL,
                chapter_title TEXT,
                UNIQUE(book_id, position)
            );

            CREATE INDEX IF NOT EXISTS excerpts_book_idx ON excerpts(book_id);
        """)
        conn.commit()
    log.info("✅ Tables created/verified")




# ─── Gutendex API (correct book metadata) ─────────────────────────────────────

GUTENDEX_CACHE: dict = {}  # In-memory cache to avoid duplicate API calls
cache_lock = threading.Lock()

def fetch_gutendex_metadata(gutenberg_id: str) -> dict | None:
    """
    Fetch accurate title + author from the Gutendex API (gutendex.com).
    Falls back to None if the request fails.
    """
    with cache_lock:
        if gutenberg_id in GUTENDEX_CACHE:
            return GUTENDEX_CACHE[gutenberg_id]
            
    try:
        url = f"https://gutendex.com/books/{gutenberg_id}"
        r = requests.get(url, timeout=10)
        if r.status_code == 200:
            data = r.json()
            authors = data.get("authors", [])
            author_name = authors[0]["name"] if authors else "Unknown Author"
            formats = data.get("formats", {}) or {}
            result = {
                "title": data.get("title", ""),
                "author": author_name,
                "languages": data.get("languages", []),
                "coverUrl": formats.get("image/jpeg"),
            }
            with cache_lock:
                GUTENDEX_CACHE[gutenberg_id] = result
            return result
    except Exception as e:
        log.warning(f"Gutendex lookup failed for {gutenberg_id}: {e}")
    return None


# ─── Project Gutenberg Import ─────────────────────────────────────────────────

def process_single_book(book, db_pool, stats):
    """Worker function to process a single book."""
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            gutenberg_id = str(book[0])
            local_title  = book[1] if book[1] else "Unknown Title"
            local_author = book[2] if book[2] else "Unknown Author"
            language     = book[3] if book[3] else "en"

            # Fetch accurate metadata
            meta = fetch_gutendex_metadata(gutenberg_id)
            cover_url = None
            if meta:
                title  = meta["title"] or local_title
                author = meta["author"] or local_author
                cover_url = meta.get("coverUrl")
                if meta["languages"]:
                    language = meta["languages"][0]
                log.info(f"  [{gutenberg_id}] '{title[:50]}' ({language}) {cover_url} — Gutendex ✓")
            else:
                title  = local_title
                author = local_author
                log.info(f"  [{gutenberg_id}] '{title[:50]}' ({language}) — local cache fallback")

            # Insert book
            cur.execute("""
                INSERT INTO books (title, author, language, "coverUrl", source, "externalId", "isPublicDomain")
                VALUES (%s, %s, %s, %s, 'gutenberg', %s, TRUE)
                ON CONFLICT (source, "externalId") DO UPDATE 
                SET "coverUrl" = EXCLUDED."coverUrl" 
                WHERE books."coverUrl" IS NULL AND EXCLUDED."coverUrl" IS NOT NULL
                RETURNING id
            """, (title[:500], author[:300], language[:10], cover_url, gutenberg_id))

            row = cur.fetchone()
            if not row:
                cur.execute("""
                    SELECT id FROM books WHERE source='gutenberg' AND "externalId"=%s
                """, (gutenberg_id,))
                row = cur.fetchone()
                if not row:
                    with stats["lock"]:
                        stats["skipped"] += 1
                    return

            book_id = row[0]

            # Download full text
            try:
                raw = get_text_by_id(int(gutenberg_id))
                if raw:
                    content = strip_headers(raw).decode("utf-8", errors="ignore")
                    cur.execute("""
                        UPDATE books SET content=%s WHERE id=%s
                    """, (content, book_id))
            except Exception as e:
                log.warning(f"Could not download text for book {gutenberg_id}: {e}")

            conn.commit()
            with stats["lock"]:
                stats["imported"] += 1

    except Exception as e:
        log.warning(f"Error processing Gutenberg book {book[0]}: {e}")
        with stats["lock"]:
            stats["skipped"] += 1
    finally:
        db_pool.putconn(conn)


def import_gutenberg(conn):
    log.info("📚 Starting Gutenberg import...")

    # Build local cache if needed
    if not GutenbergCache.exists():
        log.info("Building Gutenberg cache (first time, ~2 min)...")
        GutenbergCache.create()

    cache = GutenbergCache.get_cache()

    # Query all books
    query = """
        SELECT 
            b.gutenbergbookid,
            MAX(t.name) as title,
            MAX(a.name) as author,
            MAX(l.name) as language
        FROM books b
        LEFT JOIN titles t ON b.id = t.bookid
        LEFT JOIN book_authors ba ON b.id = ba.bookid
        LEFT JOIN authors a ON ba.authorid = a.id
        LEFT JOIN languages l ON b.languageid = l.id
        GROUP BY b.gutenbergbookid
    """
    books = cache.native_query(query).fetchall()
    log.info(f"  {len(books)} books found in Gutenberg cache")

    import random
    random.shuffle(books)
    if MAX_BOOKS_GUTENBERG:
        books = books[:MAX_BOOKS_GUTENBERG]

    log.info(f"Found {len(books)} Gutenberg books to process in parallel")

    # Initialize connection pool for threads
    db_pool = pool.ThreadedConnectionPool(1, 20, **DB_CONFIG)
    
    stats = {
        "imported": 0,
        "skipped": 0,
        "lock": threading.Lock()
    }

    # Process in parallel
    threads = 20
    with ThreadPoolExecutor(max_workers=threads) as executor:
        list(tqdm(executor.map(lambda b: process_single_book(b, db_pool, stats), books), 
                  total=len(books), desc="Gutenberg"))

    db_pool.closeall()
    log.info(f"✅ Gutenberg: {stats['imported']} imported, {stats['skipped']} skipped")


# ─── Open Library Import ──────────────────────────────────────────────────────

def download_openlibrary_dump():
    """Download Open Library works dump if not present."""
    if os.path.exists(OPEN_LIBRARY_WORKS_DUMP):
        log.info("Open Library dump already downloaded, skipping.")
        return

    log.info(f"Downloading Open Library dump (~5GB)...")
    response = requests.get(OPEN_LIBRARY_DUMP_URL, stream=True)
    total = int(response.headers.get("content-length", 0))

    with open(OPEN_LIBRARY_WORKS_DUMP, "wb") as f, tqdm(
        total=total, unit="B", unit_scale=True, desc="Downloading"
    ) as bar:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)
            bar.update(len(chunk))

    log.info("✅ Download complete")


def import_openlibrary(conn):
    log.info("📖 Starting Open Library import...")
    download_openlibrary_dump()

    imported = 0
    skipped = 0
    batch = []
    BATCH_SIZE = 500

    def flush_batch(cur, batch):
        if not batch:
            return
        execute_values(cur, """
            INSERT INTO books (title, author, description, "coverUrl", "publishedYear", language, source, "externalId", "isPublicDomain")
            VALUES %s
            ON CONFLICT (source, "externalId") DO NOTHING
        """, batch)
        conn.commit()

    with conn.cursor() as cur:
        with gzip.open(OPEN_LIBRARY_WORKS_DUMP, "rt", encoding="utf-8") as f:
            for line in tqdm(f, desc="Open Library", unit=" works"):
                if MAX_BOOKS_OPENLIBRARY and imported >= MAX_BOOKS_OPENLIBRARY:
                    break

                try:
                    parts = line.strip().split("\t")
                    if len(parts) < 5:
                        continue

                    ol_id = parts[1]          # e.g. /works/OL45804W
                    data = json.loads(parts[4])

                    title = data.get("title", "").strip()
                    if not title:
                        skipped += 1
                        continue

                    # Author
                    authors = data.get("authors", [])
                    author = authors[0].get("author", {}).get("key", "Unknown") if authors else "Unknown"
                    # Strip /authors/ prefix
                    author = author.replace("/authors/", "")

                    # Description
                    desc = data.get("description", "")
                    if isinstance(desc, dict):
                        desc = desc.get("value", "")

                    # Cover
                    covers = data.get("covers", [])
                    cover_url = f"https://covers.openlibrary.org/b/id/{covers[0]}-L.jpg" if covers else None

                    # Year
                    first_publish = data.get("first_publish_date", "")
                    year = None
                    if first_publish:
                        try:
                            year = int(first_publish[-4:])
                        except Exception:
                            pass

                    # Language (OL works don't always have language — default en)
                    language = "en"

                    # Public domain: published before 1928
                    is_public_domain = bool(year and year < 1928)

                    batch.append((
                        title[:500],
                        author[:300],
                        desc[:2000] if desc else None,
                        cover_url,
                        year,
                        language,
                        "openlibrary",
                        ol_id,
                        is_public_domain,
                    ))

                    imported += 1

                    if len(batch) >= BATCH_SIZE:
                        flush_batch(cur, batch)
                        batch = []

                except Exception as e:
                    skipped += 1
                    continue

        flush_batch(cur, batch)

    log.info(f"✅ Open Library: {imported} imported, {skipped} skipped")


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    log.info("🚀 Readeel Import Script starting...")

    conn = get_connection()
    # create_tables(conn) # Now managed by Serverpod migrations

    import_gutenberg(conn)
    # import_openlibrary(conn)

    # Stats
    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM books")
        book_count = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM excerpts")
        excerpt_count = cur.fetchone()[0]

    log.info(f"")
    log.info(f"📊 Final stats:")
    log.info(f"   Books    : {book_count:,}")
    log.info(f"   Excerpts : {excerpt_count:,}")
    log.info(f"")
    log.info(f"✅ Import complete! Readeel database is ready.")

    conn.close()


if __name__ == "__main__":
    main()

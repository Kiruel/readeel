#!/usr/bin/env python3
"""
Readeel — Fetch Amazon Links via Creators / PA-API
===================================================
Fetches Amazon Affiliate links/ASINs for books in the local database.

Requirements:
  pip install psycopg2-binary python-amazon-paapi python-dotenv
"""

import os
import time
import logging
from dotenv import load_dotenv
import psycopg2
from psycopg2 import pool
from amazon_paapi import AmazonApi

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("amazon-links")

# Load environment variables from .env if present
load_dotenv()

AMAZON_ACCESS_KEY = os.getenv("AMAZON_ACCESS_KEY", "")
AMAZON_SECRET_KEY = os.getenv("AMAZON_SECRET_KEY", "")
AMAZON_TAG = os.getenv("AMAZON_TAG", "readeel-21")
AMAZON_COUNTRY = os.getenv("AMAZON_COUNTRY", "FR") # Set to US, FR, etc. based on target market

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 8090)),
    "dbname": os.getenv("DB_NAME", "readeel"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "jRIpX1MqCjy8qKhmml3Kk-GZXr-x_1fT"),
}

# Throttle setting to prevent getting instantly banned by API limits
# Amazon PA-API limits new accounts initially to ~1 request per second
REQUESTS_DELAY_SECONDS = 1.1

def get_connection():
    return psycopg2.connect(**DB_CONFIG)

def main():
    if not AMAZON_ACCESS_KEY or not AMAZON_SECRET_KEY:
        log.error("Missing Amazon credentials! Please set AMAZON_ACCESS_KEY and AMAZON_SECRET_KEY in a .env file.")
        return

    log.info("Initializing Amazon API Client...")
    try:
        amazon = AmazonApi(
            AMAZON_ACCESS_KEY,
            AMAZON_SECRET_KEY,
            AMAZON_TAG,
            AMAZON_COUNTRY
        )
    except Exception as e:
        log.error(f"Failed to initialize Amazon Client: {e}")
        return

    log.info("Connecting to Database...")
    conn = get_connection()
    
    with conn.cursor() as cur:
        # Fetch books that lack an amazonLink
        cur.execute("""
            SELECT id, title, author 
            FROM books 
            WHERE "amazonLink" IS NULL
            ORDER BY id ASC
        """)
        books = cur.fetchall()

    if not books:
        log.info("✅ All books already have an Amazon Link! Nothing to do.")
        conn.close()
        return

    log.info(f"Found {len(books)} books waiting for an Amazon link. Starting processing...")
    
    success_count = 0
    fail_count = 0

    for book_id, title, author in books:
        keyword = f"{title} {author}".strip()
        log.info(f"Searching for [{book_id}]: {keyword}")

        try:
            # Throttle to avoid 429 Too Many Requests
            time.sleep(REQUESTS_DELAY_SECONDS)

            search_result = amazon.search_items(
                keywords=keyword,
                search_index="Books"
            )
            
            if search_result and search_result.items:
                best_item = search_result.items[0]
                asin = best_item.asin
                url = best_item.detail_page_url
                
                with conn.cursor() as cur:
                    # Update database with new link!
                    cur.execute("""
                        UPDATE books 
                        SET "amazonLink" = %s, "amazonAsin" = %s
                        WHERE id = %s
                    """, (url, asin, book_id))
                conn.commit()
                
                log.info(f" ✓ Found! ASIN: {asin}")
                success_count += 1
            else:
                log.warning(f" ✗ No books found on Amazon for: {keyword}")
                fail_count += 1

        except Exception as e:
            # The Amazon API raises errors on TooManyRequests.
            if 'TooManyRequests' in str(e):
                log.error("Throttled by Amazon API! We are querying too fast. Pausing for 10 seconds...")
                time.sleep(10)
                fail_count += 1
            else:
                log.error(f"Error querying {keyword}: {e}")
                fail_count += 1
            
            # Continue trying the next books to not completely break the loop
            continue

    conn.close()
    log.info(f"✅ Finished Processing. Success: {success_count}, Failed/Not Found: {fail_count}")

if __name__ == "__main__":
    main()

BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "books" (
    "id" bigserial PRIMARY KEY,
    "title" text NOT NULL,
    "author" text NOT NULL,
    "description" text,
    "coverUrl" text,
    "isbn" text,
    "publishedYear" bigint,
    "language" text NOT NULL,
    "source" text NOT NULL,
    "externalId" text NOT NULL,
    "isPublicDomain" boolean NOT NULL
);

-- Indexes
CREATE INDEX "books_title_idx" ON "books" USING btree ("title");
CREATE INDEX "books_author_idx" ON "books" USING btree ("author");
CREATE INDEX "books_language_idx" ON "books" USING btree ("language");
CREATE UNIQUE INDEX "books_source_idx" ON "books" USING btree ("source", "externalId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "excerpts" (
    "id" bigserial PRIMARY KEY,
    "bookId" bigint NOT NULL,
    "content" text NOT NULL,
    "position" bigint NOT NULL,
    "chapterTitle" text
);

-- Indexes
CREATE INDEX "excerpts_book_idx" ON "excerpts" USING btree ("bookId");
CREATE UNIQUE INDEX "excerpts_position_idx" ON "excerpts" USING btree ("bookId", "position");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "excerpts"
    ADD CONSTRAINT "excerpts_fk_0"
    FOREIGN KEY("bookId")
    REFERENCES "books"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR readeel
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('readeel', '20260409120216383', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260409120216383', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260213194423028', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260213194423028', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260129181112269', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129181112269', "timestamp" = now();


COMMIT;

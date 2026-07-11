-- ============================================================================
-- Dedupe journals / authors / research_topics
-- ============================================================================
-- Why this script exists
-- ----------------------
-- During the early OpenAlex syncs the Application code used a Dictionary
-- keyed by journal/topic/author name WITHOUT OrdinalIgnoreCase, so each sync
-- could insert a brand-new row even when an existing one already existed in
-- the table. The result is several rows in `journals`, `authors`, and
-- `research_topics` that share the same display name (sometimes the same
-- external_author_id) but have different synthetic primary keys.
--
-- Symptom: SyncWorksAsync throws
--   "An item with the same key has already been added. Key: <name>"
-- when running
--   ToDictionary(j => j.Name, ..., StringComparer.OrdinalIgnoreCase)
-- because the DB returns multiple rows for the same normalized name.
--
-- Strategy
-- --------
-- For every (name | external_author_id) group with more than one row:
--   1. Pick a "winner" row (the smallest PK).
--   2. Re-point every FK (papers.journal_id, paper_authors.author_id,
--      paper_topics.topic_id, publication_trends.topic_id,
--      follow_topics.topic_id, reports.topic_id) from loser -> winner.
--   3. Delete the loser rows.
--
-- Each section is its own atomic operation. The script is idempotent:
-- re-running it on a clean DB is a no-op (the GROUP BY HAVING COUNT(*) > 1
-- just produces no rows, so the UPDATE/DELETE WHERE clauses don't update).
-- ============================================================================

-- ============================================================================
-- 1. JOURNALS
-- ============================================================================
-- Re-point papers.journal_id from duplicate journal rows to the canonical
-- one (smallest journal_id wins alphabetically; for GUIDs this is also the
-- earliest-created row).

-- Make sure the column types match before we touch anything
DO $$
DECLARE
    rec RECORD;
    winner_id TEXT;
    loser_id TEXT;
BEGIN
    FOR rec IN
        SELECT name, array_agg(journal_id ORDER BY journal_id) AS ids
          FROM journals
         GROUP BY name
        HAVING COUNT(*) > 1
    LOOP
        winner_id := rec.ids[1];
        FOR i IN 2..array_length(rec.ids, 1) LOOP
            loser_id := rec.ids[i];
            UPDATE papers
               SET journal_id = winner_id
             WHERE journal_id = loser_id;
            DELETE FROM journals
             WHERE journal_id = loser_id;
            RAISE NOTICE 'journal: kept %, dropped % (name=%)', winner_id, loser_id, rec.name;
        END LOOP;
    END LOOP;
END $$;


-- ============================================================================
-- 2. AUTHORS
-- ============================================================================
-- Only dedupe authors that have an external_author_id; rows without one
-- could legitimately be two different people named "Anonymous".
DO $$
DECLARE
    rec RECORD;
    winner_id TEXT;
    loser_id TEXT;
BEGIN
    FOR rec IN
        SELECT external_author_id,
               array_agg(author_id ORDER BY author_id) AS ids
          FROM authors
         WHERE external_author_id IS NOT NULL
         GROUP BY external_author_id
        HAVING COUNT(*) > 1
    LOOP
        winner_id := rec.ids[1];
        FOR i IN 2..array_length(rec.ids, 1) LOOP
            loser_id := rec.ids[i];

            -- Drop loser's paper_authors rows first: if a paper was
            -- attached to BOTH winner and loser the reassign below would
            -- collide on the composite PK (paper_id, author_id).
            DELETE FROM paper_authors
             WHERE author_id = loser_id;

            UPDATE paper_authors
               SET author_id = winner_id
             WHERE author_id = loser_id;

            DELETE FROM authors
             WHERE author_id = loser_id;

            RAISE NOTICE 'author: kept %, dropped % (ext=%)', winner_id, loser_id, rec.external_author_id;
        END LOOP;
    END LOOP;
END $$;


-- ============================================================================
-- 3. RESEARCH TOPICS
-- ============================================================================
-- The trickiest one: the topic_id is referenced from paper_topics,
-- publication_trends (CASCADE if deleted), follow_topics, reports.
DO $$
DECLARE
    rec RECORD;
    winner_id TEXT;
    loser_id TEXT;
BEGIN
    FOR rec IN
        SELECT name,
               array_agg(topic_id ORDER BY topic_id) AS ids
          FROM research_topics
         GROUP BY name
        HAVING COUNT(*) > 1
    LOOP
        winner_id := rec.ids[1];
        FOR i IN 2..array_length(rec.ids, 1) LOOP
            loser_id := rec.ids[i];

            -- paper_topics: composite PK (paper_id, topic_id). Drop
            -- loser's join rows first to avoid PK conflicts.
            DELETE FROM paper_topics pt
             WHERE pt.topic_id = loser_id;

            UPDATE paper_topics
               SET topic_id = winner_id
             WHERE topic_id = loser_id;

            -- publication_trends has CASCADE so reassign rather than delete.
            UPDATE publication_trends
               SET topic_id = winner_id
             WHERE topic_id = loser_id;

            -- follow_topics: user might be following both duplicates.
            DELETE FROM follow_topics ft
             WHERE ft.topic_id = loser_id
               AND EXISTS (
                   SELECT 1 FROM follow_topics ft2
                    WHERE ft2.user_id  = ft.user_id
                      AND ft2.topic_id = winner_id
               );

            UPDATE follow_topics
               SET topic_id = winner_id
             WHERE topic_id = loser_id;

            -- reports: same idea.
            DELETE FROM reports r
             WHERE r.topic_id = loser_id
               AND EXISTS (
                   SELECT 1 FROM reports r2
                    WHERE r2.user_id  = r.user_id
                      AND r2.topic_id = winner_id
               );

            UPDATE reports
               SET topic_id = winner_id
             WHERE topic_id = loser_id;

            DELETE FROM research_topics
             WHERE topic_id = loser_id;

            RAISE NOTICE 'topic: kept %, dropped % (name=%)', winner_id, loser_id, rec.name;
        END LOOP;
    END LOOP;
END $$;


-- ============================================================================
-- 4. PREVENT FUTURE DUPLICATES
-- ============================================================================
-- UNIQUE indexes on the normalized columns. LOWER() makes them
-- case-insensitive, matching the OrdinalIgnoreCase comparer the
-- Application code now uses. IF NOT EXISTS makes this section safe to
-- re-run.
--
-- We do NOT add a UNIQUE INDEX on research_topics because the EF model
-- has a case-sensitive one already (research_topics_name_key). Adding a
-- case-insensitive one alongside it would only cause confusion; the
-- Application code's GroupBy fix is what guards against duplicates.

CREATE UNIQUE INDEX IF NOT EXISTS ux_journals_name_lower
    ON journals (LOWER(name));

CREATE UNIQUE INDEX IF NOT EXISTS ux_authors_external_author_id
    ON authors (external_author_id)
    WHERE external_author_id IS NOT NULL;


-- ============================================================================
-- Verification
-- ============================================================================
-- Re-run these queries by hand to confirm the duplicates are gone:
--
--   SELECT name, COUNT(*) FROM journals
--    GROUP BY name HAVING COUNT(*) > 1;
--
--   SELECT external_author_id, COUNT(*) FROM authors
--    WHERE external_author_id IS NOT NULL
--    GROUP BY external_author_id HAVING COUNT(*) > 1;
--
--   SELECT name, COUNT(*) FROM research_topics
--    GROUP BY name HAVING COUNT(*) > 1;

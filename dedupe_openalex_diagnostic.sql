-- ============================================================================
-- Diagnostic queries — run BEFORE the dedupe migration to see what state
-- the database is in. Read-only, does NOT modify anything.
-- ============================================================================

-- 1. Duplicate journal names ----------------------------------------------------
SELECT name, COUNT(*) AS dup_count,
       array_agg(journal_id ORDER BY journal_id) AS ids
  FROM journals
 GROUP BY name
HAVING COUNT(*) > 1
 ORDER BY dup_count DESC, name
 LIMIT 50;

-- 2. Duplicate external author IDs ---------------------------------------------
SELECT external_author_id, COUNT(*) AS dup_count,
       array_agg(author_id ORDER BY author_id) AS ids
  FROM authors
 WHERE external_author_id IS NOT NULL
 GROUP BY external_author_id
HAVING COUNT(*) > 1
 ORDER BY dup_count DESC
 LIMIT 50;

-- 3. Duplicate research-topic names --------------------------------------------
SELECT name, COUNT(*) AS dup_count,
       array_agg(topic_id ORDER BY topic_id) AS ids
  FROM research_topics
 GROUP BY name
HAVING COUNT(*) > 1
 ORDER BY dup_count DESC, name
 LIMIT 50;

-- 4. UNIQUE indexes that already exist -----------------------------------------
SELECT schemaname, tablename, indexname, indexdef
  FROM pg_indexes
 WHERE tablename IN ('journals', 'authors', 'research_topics', 'keywords')
   AND indexname LIKE '%unique%' OR indexdef LIKE '%UNIQUE%'
 ORDER BY tablename, indexname;

-- ============================================================
-- ROUND 2 CLEANUP — 2026-04-10
-- After the first cleanup brought agents from 2181 -> 24, a stale
-- deploy of the seed-on-empty branch re-duplicated the table to 1457
-- rows while kwashington was signing in. The fix in index.html now
-- removes the seed path entirely and requires an auth session. This
-- script re-collapses the duplicates preserving avatar_photos and
-- the Danny / Sam additions.
-- ============================================================

-- 1) Snapshot before any destructive work.
DROP TABLE IF EXISTS public.agents_backup_20260410_r2;
CREATE TABLE public.agents_backup_20260410_r2 AS
SELECT * FROM public.agents;

-- Sanity: how many rows are we backing up?
SELECT 'backup_count' AS metric, COUNT(*) AS value FROM public.agents_backup_20260410_r2;

-- 2) Pick ONE canonical row per name.
--    Preference order:
--      (a) a row that already has an uploaded avatar_photo wins,
--      (b) then the row with the oldest id (first insert),
--      (c) ties broken by id text for determinism.
WITH ranked AS (
    SELECT
        id,
        name,
        ROW_NUMBER() OVER (
            PARTITION BY name
            ORDER BY
                CASE WHEN avatar_photo IS NOT NULL AND avatar_photo <> '' THEN 0 ELSE 1 END,
                id
        ) AS rn
    FROM public.agents
)
DELETE FROM public.agents
WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

-- 3) Verify counts post-cleanup.
SELECT 'final_total'         AS metric, COUNT(*)                 AS value FROM public.agents
UNION ALL
SELECT 'final_distinct_names',           COUNT(DISTINCT name)             FROM public.agents
UNION ALL
SELECT 'final_rows_with_photo',          COUNT(*) FILTER (WHERE avatar_photo IS NOT NULL AND avatar_photo <> '')
                                                                           FROM public.agents;

-- 4) Show the surviving roster so we can visually confirm Danny + Sam are kept.
SELECT name, level, area,
       CASE WHEN avatar_photo IS NOT NULL AND avatar_photo <> '' THEN 'yes' ELSE 'no' END AS has_photo
FROM public.agents
ORDER BY name;

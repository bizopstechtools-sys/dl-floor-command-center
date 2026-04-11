-- Migration: add per-agent timestamped notes column
-- Run once in the Supabase SQL editor before deploying the notes feature.
-- Safe to re-run: IF NOT EXISTS + default empty array.

ALTER TABLE agents
    ADD COLUMN IF NOT EXISTS notes jsonb NOT NULL DEFAULT '[]'::jsonb;

-- Each entry has the shape: { "ts": "2026-04-10T15:30:00.000Z", "text": "..." }
-- The app stores the most recent append at the end of the array; the UI sorts
-- by ts descending at render time. The column is append-only from the UI and
-- never displays the service_role key or any auth data.

-- =============================================================
-- DL Floor Command Center - Supabase Schema
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor)
-- =============================================================

-- 1. AGENTS TABLE
CREATE TABLE IF NOT EXISTS agents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  level TEXT NOT NULL DEFAULT 'T1',
  wfh TEXT DEFAULT '-',
  gender TEXT DEFAULT 'male',
  avatar_index INT DEFAULT 0,
  avatar_photo TEXT,  -- base64 photo data
  sick_until BIGINT,
  pto_until BIGINT,
  sick_reason TEXT,
  pto_reason TEXT,
  area TEXT,
  full_week BOOLEAN DEFAULT FALSE,
  schedule JSONB NOT NULL DEFAULT '{}',
  scheduled_pto JSONB DEFAULT '[]',
  move_history JSONB DEFAULT '[]',
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. FLOOR AREAS TABLE
CREATE TABLE IF NOT EXISTS floor_areas (
  id TEXT PRIMARY KEY,  -- matches 'area-main', 'area-phones', etc.
  name TEXT NOT NULL,
  color TEXT DEFAULT '#01CC74',
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. AUDIT LOGS TABLE
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  type TEXT NOT NULL,
  message TEXT NOT NULL,
  agent_name TEXT DEFAULT '',
  user_email TEXT,  -- which manager made this change
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. OPEN SPOTS TABLE
CREATE TABLE IF NOT EXISTS open_spots (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  level TEXT NOT NULL,
  type TEXT DEFAULT 'open',
  label TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. APP SETTINGS TABLE
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================
-- DEFAULT DATA (initial seed)
-- ============================

-- Default floor areas
INSERT INTO floor_areas (id, name, color, sort_order) VALUES
  ('area-main', 'Main Floor', '#01CC74', 0),
  ('area-phones', 'Phone Bay', '#1665D8', 1),
  ('area-zoom', 'Zoom Room', '#FF4998', 2),
  ('area-training', 'Training Area', '#FFA500', 3)
ON CONFLICT (id) DO NOTHING;

-- Default settings
INSERT INTO app_settings (key, value) VALUES
  ('chart_flipped', 'false'),
  ('last_maintenance', '')
ON CONFLICT (key) DO NOTHING;

-- ============================
-- ROW LEVEL SECURITY (RLS)
-- ============================

-- Enable RLS on all tables
ALTER TABLE agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE floor_areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE open_spots ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

-- Policies: authenticated users can read/write everything
-- (All managers on the floor share the same data)
CREATE POLICY "Authenticated users can read agents" ON agents
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert agents" ON agents
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update agents" ON agents
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can delete agents" ON agents
  FOR DELETE TO authenticated USING (true);

CREATE POLICY "Authenticated users can read floor_areas" ON floor_areas
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert floor_areas" ON floor_areas
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update floor_areas" ON floor_areas
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users can delete floor_areas" ON floor_areas
  FOR DELETE TO authenticated USING (true);

CREATE POLICY "Authenticated users can read audit_logs" ON audit_logs
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert audit_logs" ON audit_logs
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Authenticated users can read open_spots" ON open_spots
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert open_spots" ON open_spots
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can delete open_spots" ON open_spots
  FOR DELETE TO authenticated USING (true);

CREATE POLICY "Authenticated users can read app_settings" ON app_settings
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can update app_settings" ON app_settings
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- ============================
-- ENABLE REALTIME
-- ============================
ALTER PUBLICATION supabase_realtime ADD TABLE agents;
ALTER PUBLICATION supabase_realtime ADD TABLE floor_areas;
ALTER PUBLICATION supabase_realtime ADD TABLE audit_logs;
ALTER PUBLICATION supabase_realtime ADD TABLE open_spots;

-- ============================
-- UPDATED_AT TRIGGER
-- ============================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER agents_updated_at
  BEFORE UPDATE ON agents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================
-- SEED: 22 INITIAL AGENTS
-- ============================
INSERT INTO agents (name, level, wfh, gender, avatar_index, area, schedule) VALUES
  ('Aileen','Phone','F','female',0,'area-phones','{"Sunday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":true},"Monday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":false},"Tuesday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":false},"Wednesday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":false},"Thursday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":false},"Friday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":false},"Saturday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":true}}'),
  ('Alejandro','T1','-','male',1,'area-main','{"Sunday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":true},"Monday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":false},"Tuesday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":false},"Wednesday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":false},"Thursday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":false},"Friday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":false},"Saturday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":true}}'),
  ('Alex','Phone','-','male',2,'area-phones','{"Sunday":{"start":"09:00","end":"18:00","lunch":"13:30","isOff":true},"Monday":{"start":"09:00","end":"18:00","lunch":"13:30","isOff":false},"Tuesday":{"start":"09:00","end":"18:00","lunch":"13:30","isOff":false},"Wednesday":{"start":"09:00","end":"18:00","lunch":"13:30","isOff":false},"Thursday":{"start":"09:00","end":"18:00","lunch":"13:30","isOff":false},"Friday":{"start":"09:00","end":"18:00","lunch":"13:30","isOff":false},"Saturday":{"start":"09:00","end":"18:00","lunch":"13:30","isOff":true}}'),
  ('Andres','T1','-','male',3,'area-main','{"Sunday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":true},"Monday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Tuesday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Wednesday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Thursday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Friday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Saturday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":true}}'),
  ('Andrew','T1','-','male',4,'area-main','{"Sunday":{"start":"11:00","end":"20:00","lunch":"14:30","isOff":true},"Monday":{"start":"11:00","end":"20:00","lunch":"14:30","isOff":false},"Tuesday":{"start":"11:00","end":"20:00","lunch":"14:30","isOff":false},"Wednesday":{"start":"11:00","end":"20:00","lunch":"14:30","isOff":false},"Thursday":{"start":"11:00","end":"20:00","lunch":"14:30","isOff":false},"Friday":{"start":"11:00","end":"20:00","lunch":"14:30","isOff":false},"Saturday":{"start":"11:00","end":"20:00","lunch":"14:30","isOff":true}}'),
  ('Carlos','BKaaS / Zoom','W,F','male',5,'area-zoom','{"Sunday":{"start":"10:00","end":"19:00","lunch":"15:30","isOff":true},"Monday":{"start":"10:00","end":"19:00","lunch":"15:30","isOff":false},"Tuesday":{"start":"10:00","end":"19:00","lunch":"15:30","isOff":false},"Wednesday":{"start":"10:00","end":"19:00","lunch":"15:30","isOff":false},"Thursday":{"start":"10:00","end":"19:00","lunch":"15:30","isOff":false},"Friday":{"start":"10:00","end":"19:00","lunch":"15:30","isOff":false},"Saturday":{"start":"10:00","end":"19:00","lunch":"15:30","isOff":true}}'),
  ('Char','BKaaS / Zoom','W,F','female',1,'area-zoom','{"Sunday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":true},"Monday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Tuesday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Wednesday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Thursday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Friday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Saturday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":true}}'),
  ('Diana','Phone','-','female',2,'area-phones','{"Sunday":{"start":"10:00","end":"19:00","lunch":"14:00","isOff":true},"Monday":{"start":"10:00","end":"19:00","lunch":"14:00","isOff":false},"Tuesday":{"start":"10:00","end":"19:00","lunch":"14:00","isOff":false},"Wednesday":{"start":"10:00","end":"19:00","lunch":"14:00","isOff":false},"Thursday":{"start":"10:00","end":"19:00","lunch":"14:00","isOff":false},"Friday":{"start":"10:00","end":"19:00","lunch":"14:00","isOff":false},"Saturday":{"start":"10:00","end":"19:00","lunch":"14:00","isOff":true}}'),
  ('Erick','T1','-','male',6,'area-main','{"Sunday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":true},"Monday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Tuesday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Wednesday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Thursday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Friday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Saturday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":true}}'),
  ('Franco','T1','W','male',7,'area-main','{"Sunday":{"start":"09:00","end":"18:00","lunch":"14:00","isOff":true},"Monday":{"start":"09:00","end":"18:00","lunch":"14:00","isOff":false},"Tuesday":{"start":"09:00","end":"18:00","lunch":"14:00","isOff":false},"Wednesday":{"start":"09:00","end":"18:00","lunch":"14:00","isOff":false},"Thursday":{"start":"09:00","end":"18:00","lunch":"14:00","isOff":false},"Friday":{"start":"09:00","end":"18:00","lunch":"14:00","isOff":false},"Saturday":{"start":"09:00","end":"18:00","lunch":"14:00","isOff":true}}'),
  ('Frank','T1','-','male',0,'area-main','{"Sunday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":true},"Monday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":false},"Tuesday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":false},"Wednesday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":false},"Thursday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":false},"Friday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":false},"Saturday":{"start":"09:00","end":"18:00","lunch":"12:30","isOff":true}}'),
  ('Gabriel','T1','-','male',1,'area-main','{"Sunday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":true},"Monday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Tuesday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Wednesday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Thursday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Friday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Saturday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":true}}'),
  ('Johnny','T1','-','male',2,'area-main','{"Sunday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":true},"Monday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Tuesday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Wednesday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Thursday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Friday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Saturday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":true}}'),
  ('Kahlil','ATS','W,F','male',3,'area-main','{"Sunday":{"start":"09:00","end":"18:00","lunch":"14:00","isOff":true},"Monday":{"start":"09:00","end":"18:00","lunch":"14:00","isOff":false},"Tuesday":{"start":"09:00","end":"18:00","lunch":"14:00","isOff":false},"Wednesday":{"start":"09:00","end":"18:00","lunch":"14:00","isOff":false},"Thursday":{"start":"09:00","end":"18:00","lunch":"14:00","isOff":false},"Friday":{"start":"09:00","end":"18:00","lunch":"14:00","isOff":false},"Saturday":{"start":"09:00","end":"18:00","lunch":"14:00","isOff":true}}'),
  ('Matthew','Phone','-','male',4,'area-phones','{"Sunday":{"start":"09:00","end":"18:00","lunch":"15:30","isOff":true},"Monday":{"start":"09:00","end":"18:00","lunch":"15:30","isOff":false},"Tuesday":{"start":"09:00","end":"18:00","lunch":"15:30","isOff":false},"Wednesday":{"start":"09:00","end":"18:00","lunch":"15:30","isOff":false},"Thursday":{"start":"09:00","end":"18:00","lunch":"15:30","isOff":false},"Friday":{"start":"09:00","end":"18:00","lunch":"15:30","isOff":false},"Saturday":{"start":"09:00","end":"18:00","lunch":"15:30","isOff":true}}'),
  ('Mei','Lead','-','female',3,'area-main','{"Sunday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":true},"Monday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Tuesday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Wednesday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Thursday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Friday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Saturday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":true}}'),
  ('Milly','T1','-','female',4,'area-main','{"Sunday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":true},"Monday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Tuesday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Wednesday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Thursday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Friday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Saturday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":true}}'),
  ('Nicole','T1','F','female',5,'area-main','{"Sunday":{"start":"08:00","end":"17:00","lunch":"15:00","isOff":true},"Monday":{"start":"08:00","end":"17:00","lunch":"15:00","isOff":false},"Tuesday":{"start":"08:00","end":"17:00","lunch":"15:00","isOff":false},"Wednesday":{"start":"08:00","end":"17:00","lunch":"15:00","isOff":false},"Thursday":{"start":"08:00","end":"17:00","lunch":"15:00","isOff":false},"Friday":{"start":"08:00","end":"17:00","lunch":"15:00","isOff":false},"Saturday":{"start":"08:00","end":"17:00","lunch":"15:00","isOff":true}}'),
  ('Paolo','T1','W','male',5,'area-main','{"Sunday":{"start":"08:00","end":"17:00","lunch":"13:00","isOff":true},"Monday":{"start":"08:00","end":"17:00","lunch":"13:00","isOff":false},"Tuesday":{"start":"08:00","end":"17:00","lunch":"13:00","isOff":false},"Wednesday":{"start":"08:00","end":"17:00","lunch":"13:00","isOff":false},"Thursday":{"start":"08:00","end":"17:00","lunch":"13:00","isOff":false},"Friday":{"start":"08:00","end":"17:00","lunch":"13:00","isOff":false},"Saturday":{"start":"08:00","end":"17:00","lunch":"13:00","isOff":true}}'),
  ('Randall','ATS','W,F','male',6,'area-main','{"Sunday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":true},"Monday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Tuesday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Wednesday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Thursday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Friday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":false},"Saturday":{"start":"09:00","end":"18:00","lunch":"12:00","isOff":true}}'),
  ('Tanner','ATS','T/TH','male',7,'area-main','{"Sunday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":true},"Monday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Tuesday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Wednesday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Thursday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Friday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Saturday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":true}}'),
  ('Torez','ZOOM','F','male',0,'area-zoom','{"Sunday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":true},"Monday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Tuesday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Wednesday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Thursday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Friday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":false},"Saturday":{"start":"09:00","end":"18:00","lunch":"13:00","isOff":true}}')
ON CONFLICT DO NOTHING;

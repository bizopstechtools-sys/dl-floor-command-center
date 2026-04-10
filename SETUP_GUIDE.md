# DL Floor Command Center - Deployment Guide

## What You're Deploying

Your Floor Command Center is now a full-stack app with shared real-time data. All managers will see the same floor state and changes sync instantly across browsers.

**Stack:** Express server + Supabase (database + auth + realtime) + Render (hosting)

---

## Step 1: Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and log in
2. Click **New Project**
3. Name it `dl-floor-command-center`
4. Choose a strong database password (save it somewhere safe)
5. Select the region closest to your team
6. Click **Create new project** and wait ~2 minutes

### Run the Schema

1. In your Supabase dashboard, go to **SQL Editor** (left sidebar)
2. Click **New Query**
3. Open the file `deploy/supabase/schema.sql` from your project
4. Copy the entire contents and paste it into the SQL Editor
5. Click **Run** — this creates all tables, security policies, realtime subscriptions, and seeds your 22 agents

### Get Your Credentials

1. Go to **Settings** > **API** (left sidebar)
2. Copy the **Project URL** (looks like `https://abcdefg.supabase.co`)
3. Copy the **anon public** key (the long string under "Project API keys")

### Paste Credentials into the App

Open `deploy/public/index.html` and find these lines near the top of the `<script>` block:

```javascript
var SUPABASE_URL = '';
var SUPABASE_ANON_KEY = '';
```

Paste your values:

```javascript
var SUPABASE_URL = 'https://your-project-id.supabase.co';
var SUPABASE_ANON_KEY = 'eyJhbGci...your-anon-key...';
```

### Enable Email Auth

1. Go to **Authentication** > **Providers** in Supabase
2. Email provider should be enabled by default
3. Optional: Under **Authentication** > **URL Configuration**, set the Site URL to your Render URL once you have it

---

## Step 2: Create a GitHub Repo

1. Go to [github.com/new](https://github.com/new)
2. Name it `dl-floor-command-center`
3. Make it **Private**
4. Do NOT initialize with README (we have our own files)
5. Click **Create repository**

### Push Your Code

Open Terminal and run these commands:

```bash
cd ~/Documents/Claude/Projects/DL\ Floor\ Command\ Center/deploy

git init
git add .
git commit -m "Initial deploy - Floor Command Center v3 with Supabase"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/dl-floor-command-center.git
git push -u origin main
```

Replace `YOUR_USERNAME` with your GitHub username.

---

## Step 3: Deploy on Render

1. Go to [render.com](https://render.com) and log in
2. Click **New** > **Web Service**
3. Connect your GitHub account if not already connected
4. Select the `dl-floor-command-center` repo
5. Render will auto-detect the settings from `render.yaml`, but verify:
   - **Name:** `dl-floor-command-center`
   - **Build Command:** `npm install`
   - **Start Command:** `node server.js`
6. Under **Environment Variables**, add:
   - `SUPABASE_URL` = your Supabase project URL
   - `SUPABASE_ANON_KEY` = your Supabase anon key
7. Choose the **Free** tier (or paid if you want always-on)
8. Click **Create Web Service**

Your app will be live at `https://dl-floor-command-center.onrender.com` (or similar) within a few minutes.

---

## Step 4: Create Manager Accounts

1. Open your Render URL in a browser
2. Each manager enters their email and a password (6+ characters)
3. Click **SIGN UP**
4. If email confirmation is enabled in Supabase, they'll need to check their email first
5. After confirming, they can **SIGN IN**

All managers share the same floor data. Any change one manager makes appears on everyone else's screen in real time.

---

## Project Structure

```
deploy/
  server.js           - Express server (serves the app)
  package.json         - Node.js dependencies
  render.yaml          - Render deployment config
  .env.example         - Environment variable template
  .gitignore           - Files to exclude from git
  public/
    index.html         - The full app (HTML + CSS + JS)
  supabase/
    schema.sql         - Database schema (run once in Supabase SQL Editor)
```

---

## Troubleshooting

**"Supabase not configured" error on login screen:**
You forgot to paste the SUPABASE_URL and SUPABASE_ANON_KEY into index.html.

**All agents show as UNASSIGNED:**
The schema.sql seeds agents with area assignments. If you see this, the seed data didn't run — go back to Supabase SQL Editor and re-run schema.sql.

**Changes not syncing between managers:**
Make sure Realtime is enabled. In Supabase Dashboard > Database > Replication, verify the `agents`, `floor_areas`, `open_spots`, and `audit_logs` tables are in the `supabase_realtime` publication.

**Render deploy fails:**
Check that your `package.json` and `server.js` are in the root of the repo (the `deploy/` folder contents should be the repo root).

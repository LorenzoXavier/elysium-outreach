# Elysium Outreach

A Rails 8 + PostgreSQL app for managing an outreach pipeline: bulk CSV import with
automatic deduplication, a "Needs Action" dashboard, a low-priority archive, a
duplicate-review screen, and a LinkedIn -> email follow-up workflow.

## Stack

- Ruby 3.2, Rails 8.1, PostgreSQL 16
- Hotwire (Turbo + Stimulus) and Tailwind CSS
- ActionMailer over SMTP, configured entirely via environment variables

This runs inside **WSL (Ubuntu)** since Ruby/Rails/PostgreSQL aren't installed
natively on Windows in this environment. Ruby itself is managed by **rbenv**
(version pinned in `.ruby-version`) -- a normal interactive WSL shell picks
this up automatically, no manual `PATH`/`GEM_HOME` exports needed. Run all
commands below from a WSL shell in this project directory:

```bash
wsl
cd /mnt/c/Users/lorenzo/outreach
```

## Setup

```bash
bundle install
bin/rails db:create db:migrate
bin/rails db:seed   # imports db/seed_data/*.csv, including the sample "Elysium CRM - Outreach.csv"
```

## Running

```bash
bin/dev
```

Runs the Rails server and the Tailwind CSS watcher together (via `Procfile.dev`).
Visit http://localhost:3000. `Ctrl-C` stops both.

For just the server without the CSS watcher: `bin/rails server` (rebuild CSS
manually first with `bin/rails tailwindcss:build` if you've changed any views).

## Importing CRM CSVs

- **In the app:** "Upload CSV" in the nav bar accepts one or more `.csv` files at once.
- **From the command line:** `bin/rails "import:crm_data[path/to/file.csv]"`, or with
  no argument it imports every CSV in `db/seed_data/`.

Each row is deduplicated against existing contacts by email, LinkedIn URL, or
name + company. Matches are flagged `potential_duplicate` and linked to the
existing record for review on the "Potential Duplicates" screen.

## Email delivery

Configured via environment variables (see `.env.example`): `SMTP_ADDRESS`,
`SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_DOMAIN`. Copy `.env.example`
to `.env` and fill it in for real SMTP delivery in development. Without those
set, development falls back to the `:test` delivery method (emails are
processed but not actually sent). Production requires them.

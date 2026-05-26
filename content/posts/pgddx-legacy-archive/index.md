+++
title = "/m/legacy: 30 years of UC Berkeley Postgres mail, browsable"
date = "2027-01-04"
draft = true
description = "What it took to ingest pre-PostgreSQL POSTGRES95-era archives into a modern indexer."
[taxonomies]
tags = ["postgres","history","pg.ddx.io","public-inbox"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

UC Berkeley Postgres mailing-list archives — pre-PostgreSQL, the original
POSTGRES95-and-earlier era — are now browsable at /m/legacy. Why this
matters historically, what you have to do to ingest a 30-year-old archive
into a modern indexer, and the surprising things the early threads contain.

## outline

- [ ] The archive's provenance and historical importance.
- [ ] Ingestion: format quirks of pre-2000 mbox / ezmlm / inn outputs.
      Encoding (8-bit MIME wasn't a thing yet), Date headers, Message-Id
      stability across migrations.
- [ ] Identity reconciliation across berkeley.edu → academic and industry
      trails.
- [ ] Three or four highlights from threads that explain present-day
      Postgres design choices.
- [ ] Invitation: send me archives I'm missing.

## source material

- `~/ws/pgesq/agora/cmd/agora/commands/sync_git.go` and the ingestion
  pipeline more generally.
- The /m/legacy page once it's live.

## open questions for me to answer

- Get permissions/copyrights right for re-publishing 1990s-era list traffic.
  Is there documented consent? Whom to ask if not?

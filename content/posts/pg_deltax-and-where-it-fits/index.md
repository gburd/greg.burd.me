+++
title = "pg_deltax: a Postgres-native ClickHouse alternative, sort of"
date = "2026-08-31"
draft = true
description = "Where Xata's columnar/compression extension fits relative to TimescaleDB and ClickHouse."
[taxonomies]
tags = ["postgres","pg_deltax","columnar","time-series","extensions"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

δx is Xata's Apache-2.0 columnar / compression extension. It stores data in
regular Postgres tables — not its own format — so physical/logical
replication, crash recovery, backups, and pg_dump just work. Where it fits
relative to TimescaleDB and ClickHouse, and what makes it interesting to me
as a contributor.

## outline

- [ ] The "compressed columnar in plain Postgres tables" constraint and what
      it costs.
- [ ] What you give up vs. ClickHouse, what you keep that you'd lose with
      ClickHouse.
- [ ] What you gain vs. TimescaleDB.
- [ ] Where I'm contributing and what's open in the project.

## source material

- `~/ws/pg_deltax/README.md` and `CONTRIBUTING.md`.
- The upstream Xata project.

## open questions for me to answer

- This is someone else's project. Stay in contributor voice, not employer
  voice. Vet every "we" before publishing.
- What's the contribution actually consist of? Don't oversell.

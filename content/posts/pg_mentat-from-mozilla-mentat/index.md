+++
title = "pg_mentat: bringing Mozilla's Mentat back inside PostgreSQL"
date = "2026-08-10"
draft = true
description = "Datomic's data model survives Mozilla's abandonment, ports cleanly to pgrx, and earns a place in Postgres."
[taxonomies]
tags = ["postgres","pg_mentat","datalog","datomic","extensions"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

Mozilla shipped Mentat as an embedded Datomic-compatible Datalog store, then
abandoned it. I forked it, ported it to Rust + pgrx, and made it a first-
class PostgreSQL extension. Datomic's data model — immutable facts,
schema-first attributes, the pull API, time travel — is worth keeping
alive. Here's what it gives you that ordinary SQL doesn't.

## outline

- [ ] The Datomic data model in two minutes for the SQL crowd.
- [ ] Why Mozilla's original Mentat was a good idea poorly timed.
- [ ] Porting strategy: what survived, what got rewritten.
- [ ] The pgrx bet: 13–18 PostgreSQL versions in one extension.
- [ ] Where it goes from here: where-fns into pg_trgm, rum, pgvector, pg_infer.
- [ ] The optional `mentatd` companion that speaks Datomic's wire protocol.

## source material

- `~/ws/pg_mentat/README.md` and the announcement at `~/Desktop/_/announce-pg_mentat.txt`.
- `~/ws/mentat/` — the original Rust port lineage.
- The Mozilla mentat repo's archived state.

## open questions for me to answer

- How honest should I be about the Mozilla-Mentat-was-abandoned framing?
  (Stick to public facts; no ex-Mozilla insider gossip.)
- Which where-fn integration do I want as the showcase example?

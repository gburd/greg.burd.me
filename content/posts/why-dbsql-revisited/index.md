+++
title = "why DBSQL, twenty-three years later"
date = "2026-09-07"
draft = true
description = "BDB-backed SQL was niche in 2003 and is again niche in 2026, for very different reasons."
[taxonomies]
tags = ["dbsql","sqlite","berkeley-db","databases","sleepycat"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

The first DBSQL post (`/posts/dbsql/`) covered the history through 2011.
Twenty-three years later, I'm maintaining DBSQL again — v0.4.0 shipped
January 2026. What changed about the world to make BDB-backed SQL
interesting again, and what didn't.

## outline

- [ ] One-paragraph recap of the 2002–2011 era (link to existing post).
- [ ] What the SQLite project taught everyone since then.
- [ ] BDB-backed durability and replication that SQLite still doesn't ship
      out of the box.
- [ ] Why "small SQL92 on top of BDB" is again a niche worth filling — for
      whom?
- [ ] What I'm doing now to revive the codebase.

## source material

- `~/ws/dbsql/README` — current status.
- `content/posts/dbsql/index.md` — the existing post for the back-link.

## open questions for me to answer

- Genuinely: who is the audience for revived DBSQL? Embedded? Education?
  Personal nostalgia? Be honest.

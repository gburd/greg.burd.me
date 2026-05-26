+++
title = "multiple buffer pools: partitioning shared_buffers by workload"
date = "2026-11-16"
draft = true
description = "A per-relation buffer_pool reloption, pluggable replacement algorithms, and a route for TOAST overflow."
[taxonomies]
tags = ["postgres","postgres-wiki","buffer-manager","series:postgres-wiki"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

[TODO: rewrite the wiki page summary in conversational voice. The wiki page
is the canonical design; this post is the public-facing version that
explains why a non-Postgres-developer should care.]

## outline

- [ ] One-paragraph problem statement (cribbed from the Wiki page summary;
      then rewritten so it's actually inviting).
- [ ] Why this is interesting *now* — what current PostgreSQL pain point it
      addresses.
- [ ] Sketch of the design (don't repeat the wiki page; hit the three or
      four most important diagrams).
- [ ] Status: where in commitfest, who's involved, what's open. Update this
      every revision.
- [ ] Link back to the canonical wiki page.

## source material

- `~/Desktop/_/Multiple-Buffer-Pools.mediawiki` — the Wiki page itself, my draft.
- <https://wiki.postgresql.org/wiki/Multiple_Buffer_Pools> — once it's published.

## open questions for me to answer

- Status of the patch series at time of post — verify before publishing.
- People who've been involved in the discussion — name them with permission.
- Risk: do I have any AWS-DocumentDB-internal context informing this design?
  If so, sanitize. The Wiki page itself is already public — fine to lean on.

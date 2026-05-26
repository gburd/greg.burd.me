+++
title = "HOT-indexed updates: extending HOT to the case where indexed columns change"
date = "2026-11-02"
draft = true
description = "Per-update tombstones with a modified-attribute bitmap let unchanged indexes keep their old entries."
[taxonomies]
tags = ["postgres","postgres-wiki","hot","indexing","series:postgres-wiki"]
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

- `~/Desktop/_/HOT-Indexed-Updates-Design.mediawiki` — the Wiki page itself, my draft.
- <https://wiki.postgresql.org/wiki/HOT-Indexed_Updates_Design> — once it's published.

## open questions for me to answer

- Status of the patch series at time of post — verify before publishing.
- People who've been involved in the discussion — name them with permission.
- Risk: do I have any AWS-DocumentDB-internal context informing this design?
  If so, sanitize. The Wiki page itself is already public — fine to lean on.

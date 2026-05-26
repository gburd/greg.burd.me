+++
title = "pg.ddx.io/community: the algorithm, and why it's only fair-enough"
date = "2026-12-21"
draft = true
description = "Ranking 30 years of contributors when one human has had four email addresses since 1997."
[taxonomies]
tags = ["postgres","pg.ddx.io","community","agora"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

The pg.ddx.io/community page ranks contributors by a metric that is
"fair-enough" given current data. The honest disclosure: email-to-person
identity mapping is genuinely ambiguous over a 30-year archive, and any
ranking with that input is biased toward people who never changed
addresses. Here's the algorithm, here's why it's the best I can do today,
and here's what would make it better.

## outline

- [ ] Data sources: git history, mailing-list archives, commitfest, build farm.
- [ ] Current scoring (cite the actual implementation in `~/ws/pgesq/agora/`).
- [ ] The identity-mapping problem: one human ↔ N email addresses across
      decades. Heuristics I use; their false-positive and false-negative rates.
- [ ] What "fair-enough" means as a public commitment: the page links here.
- [ ] Roadmap: how additional signals (Wiki edits, commitfest reviews,
      conference talks, PR reviews) reduce email-monoculture bias.
- [ ] Invitation to flag identity errors with a process that doesn't burn
      contributors.

## source material

- `~/ws/pgesq/agora/` — the implementation.
- pg.ddx.io/community — the live page.

## open questions for me to answer

- Should I publish the actual scoring formula or just the inputs? (Probably
  the formula; transparency beats security-through-obscurity for a
  community ranking.)

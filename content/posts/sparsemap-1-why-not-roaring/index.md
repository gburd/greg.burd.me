+++
title = "sparsemap, part 1: why not just use Roaring?"
date = "2026-06-01"
draft = true
description = "When Roaring's three-container dispatch overhead matters and a simpler two-encoding bitmap wins."
[taxonomies]
tags = ["sparsemap","bitmaps","postgres","series:sparsemap"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

Roaring is great when you have RAM to spare and your bitmaps are large enough
to amortize three-container dispatch. For long runs and small/sparse universes
embedded in a hot inner loop — index access methods, visibility maps,
transaction-id sets — a simpler two-encoding design wins on cache footprint and
branch behavior. This post argues that case without trash-talking Roaring.

## outline

- [ ] The textbook bitmap problem in two diagrams: 32-bit universe = 512 MB.
- [ ] What Roaring solves: array / bitmap / RLE container dispatch, dense default.
- [ ] What Roaring costs: 3-way branch in the hot path, container-type metadata,
      memory pool design.
- [ ] sparsemap's two-encoding choice: 64-bit descriptor + sparse vectors / RLE.
- [ ] When to pick which; when not to use sparsemap at all.
- [ ] Forward pointer to part 2 (the encoding) and part 3 (pg_tre integration).

## source material

- `~/ws/sparsemap/README.md` — opening narrative is mine to crib from.
- `~/ws/sparsemap/docs/ARCHITECTURE.md` — the design rationale is documented.
- `~/ws/sparsemap/bench/` — comparison numbers if I want to ground the rhetoric.

## open questions for me to answer

- Did I actually benchmark against Roaring head-to-head? If yes, link the
  numbers; if not, soften the claim.
- Concrete real-world workload to anchor "long runs are common" — pg_tre
  trigram postings? Postgres visibility map?

+++
title = "what a fair ledger benchmark would actually measure"
date = "2027-02-01"
draft = true
description = "TPC has nothing for ledger workloads. Here's what such a benchmark needs and what's stopping me from writing it."
[taxonomies]
tags = ["benchmarking","ledger","tpc","fintech"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

Most database benchmarks are TPC-something. None of them faithfully
represent ledger workloads — immutable append, multi-account atomicity,
time-bucketed reads, audit-trail dominance. What a real ledger benchmark
should measure and why I keep wanting one.

## outline

- [ ] TPC-A through TPC-E: what they cover and what they actively misrepresent
      for ledger work.
- [ ] Real ledger characteristics observed in production (cite public
      sources; do not lean on any current/former employer's internals).
- [ ] The properties a fair ledger benchmark must have: write-shape,
      read-shape, contention model, durability assumptions, audit query mix.
- [ ] A roadmap toward a draft spec.
- [ ] Ask: who else wants this and would help.

## source material

- Public TigerBeetle docs (good vocabulary).
- Public TPC specifications.

## open questions for me to answer

- Which prior employer experiences do I draw on, and which can I cite
  publicly? Keep all examples to public sources.

+++
title = "Ra, part 5: .rra files and emergent rule composition"
date = "2026-08-03"
draft = true
description = "How four worked examples compose into optimizations the author of any single rule didn't anticipate."
[taxonomies]
tags = ["ra","query-optimization","series:ra"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

A guided tour of the `.rra` file format and how rule composition produces
emergent optimizations the author of any single rule didn't anticipate. Four
worked examples, picked to show the surprising interactions.

## outline

- [ ] Anatomy of an `.rra` file: header, formal algebra, preconditions,
      implementation, cost model, tests.
- [ ] How preconditions are checked and composed under saturation.
- [ ] Worked example 1: predicate pushdown × projection pushdown ⇒ index-only.
- [ ] Worked example 2: a hardware rule (SIMD aggregation) gated by a
      logical rule (group-by reorder).
- [ ] Worked example 3: a multi-model rule that bridges relational and
      datalog operators.
- [ ] Worked example 4: a rule I expected to compose well that didn't, and
      what I learned from the failure.

## source material

- `~/ws/ra/rules/` — the actual rule files.

## open questions for me to answer

- Pick the four examples carefully. They should each illustrate a distinct
  rule-interaction pattern.

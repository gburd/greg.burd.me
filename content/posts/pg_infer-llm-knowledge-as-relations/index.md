+++
title = "pg_infer: making transformer model knowledge SQL-queryable"
date = "2026-08-17"
draft = true
description = "Inference becomes a planner-visible operator, not an external service the database calls."
[taxonomies]
tags = ["postgres","pg_infer","llm","extensions"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

Most "AI in the database" stories are about calling a model from SQL. pg_infer
flips it: the model's *internals* — gate activations, feature labels, learned
associations — become indexed relations the planner can scan, filter, and
join. Inference becomes a query operator, not an external call. This unlocks
question shapes that black-box inference cannot answer.

## outline

- [ ] The "vindex" (vectorized index of model knowledge) format.
- [ ] What questions become tractable when model knowledge is queryable.
- [ ] Why this is fundamentally different from "call OpenAI from a UDF":
      cost, latency, planner integration, parallelism.
- [ ] Hardware paths: Apple Metal, NVIDIA CUDA, CPU. What's experimental.
- [ ] Honest experimental status: 769+ tests passing, no production users.

## source material

- `~/ws/pg_infer/README` and `~/Desktop/_/announce-pg_infer.txt`.
- `~/ws/pg_infer/DESIGN/` — design docs.
- `~/ws/larql/` — the predecessor / sibling project.

## open questions for me to answer

- Pick three concrete demo queries that pg_infer makes possible and a
  black-box LLM API cannot.
- Be specific about which model architectures are supported (which
  transformer families, what extraction tooling).

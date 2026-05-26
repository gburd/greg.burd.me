+++
title = "using pg.ddx.io/mcp from your AI agent"
date = "2027-01-11"
draft = true
description = "Step-by-step: clone skills.git, configure your agent, ask 30 years of pgsql-hackers anything."
[taxonomies]
tags = ["postgres","pg.ddx.io","mcp","agents","tutorial"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

A how-to: clone the `skills.git` from pg.ddx.io, configure your agent
(Claude Code / Codex / Pi / Kiro) to use the pg.ddx.io/mcp server, and start
asking questions about Postgres internals or mailing-list history without
context-window starvation.

## outline

- [ ] Step-by-step setup: skills.git clone, agent config snippet for each tool.
- [ ] The 50+ tools the MCP server exposes — categories: git, mailing list,
      code-intel, commitfest, build farm.
- [ ] Worked example 1: "find the thread that discussed visibility map
      atomicity in 2018".
- [ ] Worked example 2: "who has reviewed visibility-map patches in the last
      year" — name discovery via thread participation.
- [ ] Worked example 3: "git churn for src/backend/storage/buffer over the
      last 5 years, by author cluster".
- [ ] Failure modes: when the agent burns context anyway, when the MCP
      server is rate-limited, how to recover.

## source material

- `~/ws/pgesq-skills/` — the skills repo content.
- `~/ws/pgesq/agora/` — the MCP server.

## open questions for me to answer

- Pin the exact agent versions / config syntaxes at publish time; these
  change.
- Decide rate-limit policy and document it before publishing this guide.

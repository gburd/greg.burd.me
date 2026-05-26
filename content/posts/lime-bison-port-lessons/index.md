+++
title = "porting flex+bison to Lime: 12 grammars, 36k lines, lessons learned"
date = "2026-10-26"
draft = true
description = "What flex and bison actually do that the textbooks don't mention, learned the hard way."
[taxonomies]
tags = ["lime","parsers","compilers","postgres"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

Porting 12 PostgreSQL grammar/scanner pairs (~36k lines of flex+bison) to
Lime taught me what flex and bison actually do that nobody mentions in the
textbooks. Notes on the conversion mechanics, the gotchas, and the cases
where a hand-rolled scanner cousin of flex is simpler than flex itself.

## outline

- [ ] The mechanical bison → Lime conversion that mostly works.
- [ ] Where it breaks: scanner state machines, push parsers, %code directives,
      glr-mode, error recovery.
- [ ] Why hand-rolled scanners replacing flex are easier than they sound when
      the grammar is small.
- [ ] The reverse converter (Lime → bison source) for tools that still
      consume bison output, and why I built it.
- [ ] Empirical: which Postgres grammars were easy, which were nightmares.

## source material

- `~/.kiro/skills/flex-bison-to-lime/SKILL.md` — I have a skill for this!
- `~/ws/lime/` — the generator.
- `~/ws/postgres/` — the grammars I ported.

## open questions for me to answer

- Pick the single most surprising lesson and lead with it.

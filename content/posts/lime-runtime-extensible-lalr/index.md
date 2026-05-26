+++
title = "Lime: an LALR(1) parser generator with runtime grammar extensions"
date = "2026-09-21"
draft = true
description = "Yacc and Bison generate parsers at compile time. Database engines, language servers, and extensible query processors need parsers that can evolve at runtime. Lime fills that gap."
[taxonomies]
tags = ["lime","parsers","compilers","postgres"]
+++

[Lime](https://codeberg.org/gregburd/lime) is the parser generator I
wanted and could not find.  It reads a context-free grammar and emits
a C parser, like Yacc or Bison.  Unlike them, the generated parser
can load and unload grammar extensions at runtime without
recompilation.

That last sentence is the whole point.  No other parser generator I
know of supports runtime grammar modification.  This post is about
why I needed it, what it cost to build, and where it earns its
keep.

## the use case that demanded it

I write database extensions.  PostgreSQL extensions in particular
have a familiar dance: you write some SQL functions, hide some
parsing behind regexes or hand-rolled state machines, and accept
that your "language" inside the database is whatever subset of SQL
plus operators the planner already understands.

`pg_tre` is the example I have written about elsewhere.  It accepts
*approximate-regex patterns* from SQL — `tre_pattern('(error){~1}.*(42[0-9]){~0}', 1)` —
which is a real grammar with a real LALR(1) structure.  I could have
hand-rolled a recursive-descent parser, but real users want to write
patterns interactively in `psql`, and the grammar has enough
ambiguity-shaped corner cases that hand-rolling them invites bugs.

Doing that with Bison would have meant either compiling the grammar
into the extension (fine for one extension, becomes a maintenance
nightmare across the family) or shipping a separate parser
executable (defeats the integration story).  What I wanted was a
parser generator whose output I could call as a library function
inside an extension's `_PG_init`, and which I could *extend* from
another extension that landed later in the load order.

This is the same problem language-server authors run into when
they want to support project-specific dialects.  And database-
engine authors when they want to add an operator without
recompiling the parser.  And anybody whose grammar evolves under
their feet.  Lime is what falls out when you try to satisfy all
three at once.

## the design in one diagram's worth of words

A Lime grammar compiles to two artifacts: a *base parser* (the
LALR(1) tables and a small VM that walks them) and an *extension
ABI* that lets a shared library plug in additional productions at
runtime.  Loading an extension is a one-shot operation that:

  1. Reads the extension's productions from a structured
     description.
  2. Computes the augmented LALR(1) tables incrementally — the
     framework knows the existing tables and only re-derives the
     diff.
  3. Detects shift/reduce and reduce/reduce conflicts between
     the existing grammar and the new productions, and invokes
     a registered callback to disambiguate.  The default
     callback fails closed (refuses to load); the application
     can override.
  4. Atomically swaps in the augmented tables under a reader-
     writer lock so that an in-flight parse never observes a
     torn grammar.

Unloading an extension reverses the process.  The base parser
runs at full speed when no extensions are loaded — the extension
machinery has zero overhead until somebody activates it.

## what makes the implementation interesting

Three things, two of them performance, one of them development
ergonomics.

**SIMD-accelerated tokenization.**  The character-classify
primitive — the inner loop that decides whether each byte starts
or extends a token — runs 4–8× faster on AVX2 and NEON than the
scalar version.  The full tokenizer pipeline absorbs some of that
in the loop overhead and emit path; measured end-to-end speedup is
1.5–2× over the scalar tokenizer.  This is not a microbenchmark;
it is what `pg_tre`'s pattern parser actually does on a real
workload.

**LLVM JIT for action tables.**  Optionally, the LALR action
tables can be JIT-compiled at parser-load time using
[Cranelift](https://cranelift.dev/) or LLVM Orc.  This trades a
tens-of-milliseconds startup cost for a parser that hits the
pattern of an L1-resident dispatch table on every shift/reduce
decision.  For long-lived parsers that see millions of inputs,
the JIT path is measurably faster.  For short-lived parsers, the
table-walking interpreter is the right choice and is the default.

**The grammar source format is human-readable enough to write by
hand.**  Bison's `%` directives have aged.  Lime's input format
is a small subset of EBNF plus a structured action language; the
intent is that you can read a Lime grammar without reaching for
the manual.  This sounds like a small thing.  When you are
porting twelve PostgreSQL grammar/scanner pairs from Bison to
Lime — about thirty-six thousand lines of grammar in total — a
small thing per file becomes a large thing in aggregate.  That
porting work is its own post.

## where Lime is and is not the right tool

The right tool when:

  - You are writing a database extension or language server that
    needs a parser whose grammar changes at runtime.
  - You have a grammar that is genuinely LALR(1) and want
    predictable performance.
  - You want a small, dependency-light parser generator that
    fits in a build pipeline that also has to ship to platforms
    where Bison's runtime is awkward (Windows, embedded).

The wrong tool when:

  - Your grammar is naturally GLR or Earley.  Lime is LALR(1)
    on purpose because LALR(1) is predictable, but GLR/Earley
    parsers have their own merits and people who need them
    really need them.
  - You want a battle-tested generator with twenty years of
    bug-fix history.  Bison is that.  Lime is not.
  - Your build tooling already has Bison or Yacc and your
    grammar does not change at runtime.  Use what you have.

## status

Lime compiles from a single C file with no dependencies.  CI
covers Linux x86_64, Linux aarch64, and macOS aarch64; the
SIMD tokenizer is gated on platform feature detection.  The
LLVM-JIT action-table path is opt-in.  License is MIT.

The first real users are
[`pg_tre`](https://codeberg.org/gregburd/pg_tre) (regex pattern
syntax) and a slow-burning side project to make PostgreSQL's
SQL grammar pluggable in a way it currently is not.  The latter
is years of work and a much larger conversation; the former is
done.

The repo is at <https://codeberg.org/gregburd/lime>.  Issues,
patches, and grammars to throw at it welcome.

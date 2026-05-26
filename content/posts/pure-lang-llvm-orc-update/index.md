+++
title = "porting Pure to LLVM 21: ORC v2, refp lifetimes, and a RISC-V relocation surprise"
date = "2026-05-09"
draft = true
description = "Albert Gräf's term-rewriting language was stuck on LLVM 3.5.2. Sixteen LLVM major releases later, here is what the migration cost and what survived."
[taxonomies]
tags = ["pure-lang","llvm","jit","languages"]
+++

[Pure](https://agraef.github.io/pure-lang/) is Albert Gräf's term-
rewriting language.  Equational definitions with pattern matching,
full symbolic rewriting, dynamic typing, eager and lazy evaluation,
lexical closures, built-in list and matrix support, an easy C
interface, and an LLVM JIT backend that produces fast native code
for any of the above.  It is one of those languages that is small
enough to read end-to-end in a weekend and big enough to do
something with afterward.  I have a soft spot for it.

When I picked Pure up last year it was pinned to LLVM 3.5.2,
released in 2015.  The current LLVM at the time of writing is
21.1.8.  That is sixteen major releases of drift, including the
single most disruptive API change LLVM has shipped in its history:
the move from MCJIT to ORC v1 to ORC v2.  Pure was *stuck*, and the
distance from where it was to where LLVM is now was the kind of
distance that makes most people give up and start a new project.

I did not start a new project.  Pure 0.69 now builds against
LLVM 20 and 21 on Ubuntu and macOS, runs on RISC-V as well as
x86_64 and aarch64, and has a CI matrix proving it.  This post is
about what that took.

## the migration in numbers

The single migration commit changed 24 files, with **4 756
insertions and 4 176 deletions**.  Most of the churn was in
`pure/interpreter.cc` and `pure/interpreter.hh` (the JIT entry
point) and `pure/runtime.cc` (the symbol resolution glue).  The
build system pieces — `configure.ac`, `config.guess`, `config.sub`
— picked up a decade of vendor updates more or less by accident.
A `pure.nix` and a `flake.nix` landed at the same time so the
toolchain pinning is reproducible.

I want to be specific about what *kind* of churn that is.  It is
not refactor-for-its-own-sake churn.  It is "the LLVM API names,
shapes, and lifetimes are different now and every call site has
to change" churn.  When I say "every call site," I mean every
`engineBuilder.create()`, every `getPointerToFunction`, every
`addModule`, every `getSymbolAddress`, every place where Pure
asked the JIT for an executable function pointer to a freshly
compiled rewrite rule.  All of them.

## ORC v2, briefly, for non-JIT people

LLVM's just-in-time compilation story has had three named
generations:

  - **MCJIT** (the LLVM 3.x default).  You hand it a
    `llvm::Module`; it gives you a function pointer.  Simple,
    inflexible, increasingly out of step with how LLVM wanted
    to ship optimisations.
  - **ORCv1**.  Introduced as a layered alternative to MCJIT,
    with explicit symbol-resolution layers.  Documented as the
    future, kept around as a transitional API, then deprecated.
  - **ORCv2** (current).  A small set of orthogonal pieces:
    `LLJIT` for the high-level case, `ExecutionSession`,
    `JITDylib` for symbol scoping, `ResourceTracker` for
    lifetime management, `ThreadSafeContext` for concurrent
    compilation.  Composes well, expresses cross-module symbol
    visibility cleanly, and forces you to think about lifetimes
    in a way MCJIT never did.

ORCv2 is correctly designed.  It is also a different mental model
from MCJIT, which means a port is not a search-and-replace.  It is
a re-architecture of the JIT call-out path.

## the lifetime problem nobody warns you about

Here is the bug I spent most of a weekend chasing.

Pure has a `refp` (reference-counted pointer) abstraction wired
into the runtime.  When the JIT compiles a rewrite rule, it
produces a function whose body manipulates `refp` values; when
that rule's compilation finishes, the runtime expects to be able
to install the function pointer in a dispatch table and call it.

Under MCJIT, the `Module` you handed to the JIT was effectively
owned by the JIT for the rest of the program's life.  The
function pointer you got back was valid until you tore the JIT
down.

Under ORCv2, modules are scoped to `ResourceTracker`s, and the
default tracker's lifetime is bounded by the `ExecutionSession`'s
lifetime, *but the symbol-resolution path through `JITDylib` does
not increment any reference count on the underlying module*.  If
you let the `ResourceTracker` go out of scope — and it is easy
to let that happen, because the natural place to put the tracker
is inside the per-rewrite-rule compilation context — the symbols
get unloaded.  The function pointer is now dangling.  Pure's
runtime sails on, calls the dangling pointer through the
dispatch table, and you get a SIGSEGV that is very hard to
attribute to "the JIT freed the function out from under you."

The fix is to make the `Env` (the per-environment compilation
state in Pure) own the `ResourceTracker` explicitly, plumb the
tracker through the rule-installation path, and tear it down
*after* the dispatch table has been mutated to forget the
function.  In code that is roughly an Rc<RefCell<…>> dance with
the obvious shape, except this is C++ so it is a `std::shared_ptr<ResourceTracker>`
held by the right object.  Pure also had a static-destruction
issue at shutdown that the same fix turned out to address — the
JIT had to be torn down *before* the global `refp` allocator
went away, and the migration-era code was tearing them down in
the wrong order.

The commit message ("Fix memory management: Env lifecycle, refp
tracking, and static destruction") is the smallest possible
description of the work; the actual diff is hundreds of lines
of "every place where the JIT and the runtime touch each other,
make the lifetime relationship explicit."  That is the kind of
work that does not show up in headline numbers but that is the
difference between "the test suite passes" and "the test suite
passes *and the program does not crash on shutdown*."

## the RISC-V relocation surprise

Once Pure was building under LLVM 21, I tried it on a RISC-V box
for fun.  It segfaulted on the first compiled function.

The cause turned out to be a generic-LLVM-on-RISC-V issue rather
than anything Pure-specific.  RISC-V's default code model is
`medlow`, which limits direct relocations to a 2 GiB window
around the program counter.  When the JIT emits a function that
calls into the runtime's `_pure_call`, the runtime symbol can
end up *outside* that 2 GiB window, especially under address-
space randomisation on a system where the heap and the JIT pool
end up far apart.  The relocation overflows.  The function does
not load.

The fix is to compile the runtime call-outs through the GOT
(the `medany` code model with PIC).  In LLVM-API terms: set
`TargetOptions::MCOptions.CodeModel = CodeModel::Medium`, ensure
`Reloc::PIC_` is on, and rebuild.  In Pure-specific terms: a
narrowly-scoped change to the JIT's target-machine setup that
fires only on RISC-V targets.  The rest of the architectures are
unaffected.

This is the kind of bug I would not have hit without trying
Pure on a third architecture.  It is also the kind of bug that
exists in plenty of LLVM-based JITs that have only been tested
on x86_64 and aarch64; when those JITs eventually get tried on
RISC-V, the same fix will land.

## the CI

A pure language port is not done until the build is reproducible
on a system the maintainer does not personally own.  The CI
matrix runs:

  - Ubuntu (latest), LLVM 20 and LLVM 21.
  - macOS (latest, Apple Silicon), LLVM 21.

`configure && make && make check` on each combination.  The full
Pure test suite is small enough that the matrix completes in
under fifteen minutes per leg, which means the CI signal is
reliable enough that I can rebase against upstream LLVM main and
notice within an hour when something breaks.

This is the part of the work that is the least glamorous and
the most useful.  The migration itself was a one-shot effort.
The CI is the thing that prevents a future LLVM 22 from quietly
re-breaking everything.

## what survived

The things that did *not* need to change might be more interesting
than the things that did:

  - The Pure language semantics.  Term rewriting is term
    rewriting.  Pattern matching is pattern matching.
  - The runtime's reference-counting story (after the lifetime
    fix).
  - The C interface.  Pure programs that call into C libraries
    via the FFI did not notice the migration.
  - The standard library.  No changes required.
  - The documentation.

A 16-major-release LLVM bump touched exactly the LLVM-adjacent
parts of Pure and almost nothing else.  That is the strongest
argument I can make for the language's design discipline: the
JIT layer is *cleanly separated* from the rest of the system, so
when LLVM moves under it, the blast radius is bounded.

## what's next

Three things on the list, in priority order:

  - **Track LLVM main**, not LLVM 21.  The CI gives me the signal;
    the gap to close is small.  I would like Pure to be one of
    the languages that LLVM contributors notice when they break
    a JIT API, on the same level as Rust's `cranelift` consumers.
  - **A modern Pure-on-Wasm target** through LLVM's WebAssembly
    backend.  Pure compiles to LLVM IR; LLVM compiles IR to
    Wasm; the missing piece is Pure's runtime in a JS-friendly
    shape.
  - **Better diagnostics from the JIT.**  ORCv2 has a much
    richer error model than MCJIT did, and Pure currently
    drops most of that information on the floor.  Rule-rewrite
    failures should produce error messages that point to the
    rule, not to the JIT.

The repo is at
<https://codeberg.org/gregburd/pure-lang>.  The four commits that
make up the migration are
[`a3465ece`](https://codeberg.org/gregburd/pure-lang/commit/a3465ece)
(LLVM 21),
[`ecc7cb8d`](https://codeberg.org/gregburd/pure-lang/commit/ecc7cb8d)
(memory management),
[`9daa983d`](https://codeberg.org/gregburd/pure-lang/commit/9daa983d)
(RISC-V), and
[`d29a8829`](https://codeberg.org/gregburd/pure-lang/commit/d29a8829)
(CI).  Patches and bug reports welcome; Albert is still the
upstream maintainer and the long-term plan is to land these
changes back at
[github.com/agraef/pure-lang](https://github.com/agraef/pure-lang)
once they have soaked.

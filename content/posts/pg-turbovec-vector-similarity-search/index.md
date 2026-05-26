+++
title = "pg_turbovec: 4-bit vector search that beats pgvector on storage and latency"
date = "2026-05-26"
draft = false
description = "Open-source vector similarity for Postgres backed by Google Research's TurboQuant, with measured numbers against pgvector HNSW."
[taxonomies]
tags = ["postgres","pg_turbovec","vector-search","quantization","extensions"]
+++

I keep being told that "vector search in Postgres" means one of two things.
You either pay full FP32 and live with eight kilobytes a row, or you reach
for `binary_quantize()` and accept that you lost most of your recall on the
way down.  Neither is the right answer for the workload most people are
actually running, which is RAG and semantic search over a million-or-so
1536-dimensional OpenAI embeddings on hardware that is small enough to
care about disk.

`pg_turbovec` is what I think the right answer looks like.  It is an
open-source PostgreSQL extension that quantizes vectors to 2 or 4 bits
per coordinate using Google Research's
[TurboQuant](https://arxiv.org/abs/2504.19874) algorithm via the
[`turbovec`](https://crates.io/crates/turbovec) crate.  At 4 bits it is
roughly an order of magnitude smaller than pgvector's `vector` column on
disk and a touch faster at the median, with R@10 of 1.000 on a real
million-row OpenAI corpus.  At 2 bits it is half that size again, with
the same recall on the same corpus.

## the headline numbers

Head-to-head, warm cache, release build, on
[`dbpedia-entities-openai-1M`](https://huggingface.co/datasets/KShivendu/dbpedia-entities-openai-1M)
(1 M rows × 1536 dimensions of real `text-embedding-ada-002`):

| Index                            | Storage  | Build   | p50 (warm) | R@10  |
|----------------------------------|---------:|--------:|-----------:|------:|
| pgvector HNSW (ef_search=40)     | 8 192 MB | 4.9 min |    61 ms   | 0.962 |
| pgvector HNSW (ef_search=200)    | 8 192 MB | 4.9 min |   115 ms   | 0.970 |
| **pg_turbovec 4-bit (k=100)**    |   780 MB | 2.7 min |  **71 ms** | **1.000** |
| pg_turbovec 4-bit (k=500)        |   780 MB | 2.7 min |   124 ms   | 1.000 |
| **pg_turbovec 2-bit (k=100)**    |   396 MB | 2.1 min |  **48 ms** | **1.000** |
| pg_turbovec 2-bit (k=500)        |   396 MB | 2.1 min |    78 ms   | 1.000 |

The full sweep including methodology lives in
[`docs/RECALL.md`](https://codeberg.org/gregburd/pg_turbovec/src/branch/main/docs/RECALL.md);
the raw JSON is checked in next to it.  R@10 is dominated by ranks 2..10
because the dbpedia query set comes from inside the corpus.  This is the
same caveat that applies to every "self-query" vector benchmark; I am
calling it out here so I do not have to call it out twice.

## why scalar quantization wins over 1-bit Hamming at the same byte budget

If you have already reached for `binary_quantize()` plus
`bit_hamming_ops`, it was almost certainly because you had 100 M
embeddings and FP32 did not fit.  At the same byte budget, `pg_turbovec`
in 2-bit mode wins on recall, and it is not close.

| Approach                                 | Bytes / 1536-dim | R@10 on real ada-002 |
|------------------------------------------|-----------------:|---------------------:|
| FP32 (raw `vector`)                      |            6 144 | 1.00 (ground truth)  |
| FP16 (`halfvec`)                         |            3 072 | ≈ 1.00               |
| TurboQuant 4-bit (`turbovec` index)      |              780 | **1.000** (k=100)    |
| TurboQuant 2-bit (`turbovec` index)      |              396 | **1.000** (k=100)    |
| 1-bit + Hamming HNSW (`bit_hamming_ops`) |              192 | ≈ 0.65–0.75 (literature) |

The reason is mechanical, not handwaving.  TurboQuant rotates the input
by a fixed orthogonal matrix so that, after rotation, each coordinate
independently follows a known Beta distribution converging to *N(0,
1/d)*.  It then assigns buckets via Lloyd-Max scalar quantization,
which is the *distortion-rate-optimal* scalar code for that
distribution, and packs them at 2, 3, or 4 bits.  `binary_quantize()`
is the same machinery pinned to 1 bit: you keep the sign and throw the
magnitude away.  At 2 bits, four reconstruction levels lands
materially closer to the Shannon distortion-rate lower bound than a
sign threshold can.  The
[paper](https://arxiv.org/abs/2504.19874) has the full distortion
analysis and is worth reading even if you never install the extension.

`bit_hamming_ops` remains the right tool when the bit vector *is* the
data, not a compression of an `f32` vector.  Cohere's native binary
embeddings, perceptual / image fingerprints (pHash, dHash), and
SimHash signatures over text are not vectors that got quantized;
they are bit strings by construction.  For those, pgvector's HNSW on
`bit_hamming_ops` is correct and pg_turbovec is not.

## what's an indexable distance

Quantization changes which distance functions can be evaluated cheaply.
`pg_turbovec` indexes inner product (`<#>`) and cosine distance
(`<=>`) through the `turbovec` index AM, which is what RAG and
semantic search workloads almost always need.  L2 (`<->`) and L1
(`<+>`) are exposed as exact functions and operate on the FP32
representation; you can use them in `WHERE` clauses but the index
will not accelerate them.  pgvector indexes L2, inner product,
cosine, and L1 through HNSW and IVF; if you genuinely need indexed
L2 ANN, that is the path.

## filtered ANN that gets *cheaper* with selectivity

The other place pg_turbovec earns its keep is filtered nearest
neighbour.  `WHERE` predicates on a vector query traditionally fall
into two camps: pre-filter (run the predicate first, then ANN over a
tiny set, but you lose recall when the predicate is selective and
the ANN graph fragments) and post-filter (run ANN, then drop
non-matching rows, but the work scales with `k`, not with the
result set size).  pg_turbovec pushes the predicate's row bitmap
into the SIMD scoring loop so highly selective filters get
*cheaper*, not more expensive.  Details in
[`docs/INDEXAM.md`](https://codeberg.org/gregburd/pg_turbovec/src/branch/main/docs/INDEXAM.md).

## what is intentionally missing

I do not ship `halfvec`, `sparsevec`, or `bitvec` types.  pgvector
has those and there is no reason to re-implement them.  I do not
ship indexed L2 ANN; if you need it, use HNSW.  The full honest
scoreboard is in
[`docs/PARITY_GAPS.md`](https://codeberg.org/gregburd/pg_turbovec/src/branch/main/docs/PARITY_GAPS.md).
There is no value in pretending the gap does not exist.

## status

v1.3.0 ships with 109 of 109 `#[pg_test]` cases passing on
PostgreSQL 13 through 18, default-on `turbovec` index AM, default-on
relfile-resident page format, and the experimental Cargo features
retired.  Apache 2.0.  Built on
[`pgrx`](https://github.com/pgcentralfoundation/pgrx) 0.17, like the
rest of my extension family.

The repo is at
<https://codeberg.org/gregburd/pg_turbovec> with a GitHub mirror.
Issues, patches, and pgsql-hackers-style review are welcome.

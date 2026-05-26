+++
title = "pg_mentat: bringing Mozilla's Mentat back inside PostgreSQL"
date = "2026-05-26"
draft = false
description = "Datomic's data model is too good to leave in a deprecated repo. The pgrx port lives in the database that already has the rest of your data."
[taxonomies]
tags = ["postgres","pg_mentat","datalog","datomic","extensions"]
+++

I have a soft spot for [Datomic](https://www.datomic.com/).  The data
model — immutable facts indexed by entity, attribute, value, and
transaction; schema as a first-class set of attribute definitions;
Datalog as the query language; time travel free with the model — is
the one piece of database design from the last twenty years that
has aged better than I expected.  When Cognitect built it on top of
DynamoDB and Cassandra and Postgres back-ends, the engineering said
"this is a model worth keeping around" loud enough that
[Mozilla's mentat project](https://github.com/mozilla/mentat) tried
to ship a desktop / mobile version of the same idea.  Then Firefox's
roadmap moved on, mentat got archived, and the model went looking for
a new home.

[`pg_mentat`](https://github.com/gburd/pg_mentat) is that home.  It is
a PostgreSQL extension, written in Rust on
[`pgrx`](https://github.com/pgcentralfoundation/pgrx) 0.17, that
implements Datomic's data model entirely inside Postgres: immutable
datoms, schema-first attributes, the Datalog query compiler, the pull
API, time travel as `as-of`/`since`/`history`/`tx-range`, and ACID
transactions because Postgres gives them to me for free.  Supports
PostgreSQL 13 through 18.  An optional companion daemon, `mentatd`,
speaks the Datomic client wire protocol over HTTP for applications
that already expect it.

## the data model in two minutes for the SQL crowd

A datom is a 5-tuple `[entity, attribute, value, tx, op]`.  *Entity*
is a stable id.  *Attribute* is a name with a type and a cardinality
(one or many).  *Value* is the obvious thing.  *Tx* is the transaction
that asserted (or retracted) the fact.  *Op* is whether the fact was
asserted or retracted.

That's it.  All of your data is datoms.  A row in a SQL table becomes
a small set of datoms — one per non-null column — that share an
entity id.  An update becomes a retraction of the old datom and an
assertion of the new one, both at the same `tx`.  A "row that did
not exist before time T" is `(entity, attr, value, tx, op)`-tuples
where `tx ≤ T` does not contain an assertion for that pair.

This is a strange shape if you have spent your career on tables.  It
turns out to also be a powerful shape, because:

  - **Time travel is free.**  `as-of T` is just a filter on `tx`.
  - **Schema migrations are additive.**  Adding an attribute is
    asserting a datom about it; no `ALTER TABLE` lock dance.
  - **Audit logs are the data.**  You did not have to build them.
  - **Reverse references are first-class.**  "Who points at this
    entity" is a single index lookup.
  - **The query language is the same shape as the data.**  Datalog
    patterns are 5-tuples with logic variables; nothing has to be
    translated.

## why a Postgres extension and not yet another standalone Datomic clone

Three reasons.

First, Postgres already has the storage, the WAL, the replication,
the backup, the role system, and the connection pool that any
production-grade database has to have, and that Mozilla's mentat
explicitly did not.  Re-implementing those is years of work that
buys you nothing if your users already have a Postgres operator
on call.

Second, Postgres already has my *other* data.  An application that
wants the Datomic data model also wants to JOIN against the rest of
the data it owns, which is in Postgres tables.  Running both inside
the same instance — same transaction, same backup, same monitoring —
removes the two-store consistency problem that kills most polyglot
deployments.

Third, `pgrx` makes this approachable.  pg_mentat is on the order
of tens of thousands of lines of Rust, not hundreds, because pgrx
absorbs the boilerplate that hand-rolled C extensions used to spend
half their bulk on.

## what survived from the original mentat

The query AST, the EDN reader, and the schema model survived almost
intact.  The shape of attributes and the way Datalog patterns
compile to executor steps follow Mozilla's design.  Where I had to
diverge was the storage layer (entirely Postgres-native; no SQLite
underneath like the original) and the transaction layer (Postgres
transactions all the way down, no separate transaction id space).

## where it goes from here

The 1.3.0 release introduced Datalog `where-fns` that bridge into
other PostgreSQL extensions: `pg_trgm`, `rum`, `fuzzystrmatch`,
[`pgvector`](https://github.com/pgvector/pgvector),
[`pg_infer`](https://codeberg.org/gregburd/pg_infer),
[PostGIS](https://postgis.net/).  These are *soft* dependencies:
nothing pg_mentat ships requires any of them, but the where-fns
light up automatically when they are present.  This is the bet I am
making about the Postgres extension family.  My extensions are
designed to compose with each other and with the broader ecosystem;
none of them tries to swallow another's responsibilities.

A worked example.  If you have `pg_trgm` installed, the where-fn
`(trgm-similar? ?text "input string" 0.3)` does what you would
expect, returning true when the trigram similarity exceeds the
threshold.  If you have `pgvector`, `(cosine-similar? ?embedding
v 0.85)` filters by cosine distance.  If you have `pg_infer`,
`(model-implies? "qwen05b" ?subject ?object 0.7)` filters by a
threshold on a learned association from the model's vindex.  None
of these are SQL — they are Datalog patterns, expressed against
datoms, that happen to call into other extensions through the
where-fn extension point.

## status

pg_mentat is at 1.3.0 and tested against PostgreSQL 13 through 18.
Apache 2.0.  The repo is at
<https://github.com/gburd/pg_mentat> with a Codeberg mirror.

A Datomic-cloud-shaped person looks at this and says "but Datomic
ships transactor / peers / storage as one box, and pg_mentat is
running in a Postgres backend."  That is correct.  The architecture
is different.  What it shares with Datomic is the *data model* and
the *query language*, not the deployment shape.  If your application
wanted Datomic-the-deployment, the right tool is still
[Datomic Pro](https://docs.datomic.com/pro/) or
[XTDB](https://xtdb.com/).  If your application wanted Datomic-the-
data-model in the database it already runs, that is what pg_mentat
is for.

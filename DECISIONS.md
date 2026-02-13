# Decisions — ai-ops-starter-kit

## 2026-02-13 — Profile-first compose layout
Created compose profile tiers (minimal/full/prod) at scaffold stage to keep later service wiring predictable.

## 2026-02-13 — Makefile UX façade
Added stable operator command surface early, even with placeholder internals, to preserve CLI compatibility as implementation deepens.

## 2026-02-13 — Bootstrap orchestrates idempotent seed loaders
Bootstrap now handles env generation + baseline resource seeding in one flow. Each loader checks existence first, so reruns are safe.

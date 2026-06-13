# 🍲 OpenTelemetry Collector Cookbook — Refactoring Design

**Date:** 2026-06-12
**Status:** Approved (design), pending implementation plan

## Problem

The cookbook grew organically. It now holds ~20 documented top-level recipes, a large
`ratatouille/` bucket of ~50 undocumented config fragments, and a `_drawer/` of shared
resources. Quality and structure are inconsistent:

- README headers vary (`# 🍜 Recipe:` vs `# Simple recipes`).
- The version footer heading varies (`😋 Executed last time…` / `😋 Versions` / `😋 Tested with`).
- Optional sections sprawl (🎯 🔍 📖 🎓 🚀 📚) with no rule for when to use them.
- File naming is mixed (`otelcol.yaml` / `otelcol-cr.yaml` / `.yml` / `.yaml`).
- Local-binary recipes and Kubernetes-CR recipes have structurally different shapes.
- Many recipes have not been validated against a recent collector/operator.

## Goals

1. A single, consistent organizing structure with a culinary "menu" theme that fits the
   existing cookbook metaphor.
2. A fixed per-recipe contract (folder layout + README skeleton) so every recipe looks and
   reads the same.
3. Every recovered recipe validated to actually work on the latest collector (and operator,
   when relevant) via a runtime smoke test.
4. The `ratatouille/` junk drawer dissolved — every fragment triaged into a real recipe,
   merged, or dropped.

## Non-Goals

- Rewriting the collector configs to change behavior (we modernize for compatibility only).
- Building tooling/CI to auto-generate the index in this first pass (the root index table is
  maintained by hand for now; automation can come later).
- Adding new recipes beyond what already exists in the repo.

## New Structure

Top-level folders are culinary courses, sorted by **depth/effort**:

```text
starters/      quick, local, single-concept recipes (run in ~2 min)
mains/         substantial / Kubernetes / multi-file, real-world recipes
desserts/      advanced showcases & niceties
sides/         shared building blocks (today's _drawer: lgtm, prometheus app)
MIGRATION.md   tracking doc — every legacy recipe/fragment and its status
README.md      root: setup instructions + topical index table
docs/          design + planning docs (this file lives here)
```

- `ratatouille/` is **dissolved**. Each fragment is triaged into one of the courses (with full
  README treatment), merged into a related recipe, or dropped if it is a dead end or duplicate.
- `_drawer/` becomes `sides/`.
- Topical discoverability ("where is tail sampling?") comes from the metadata table in each
  README plus a hand-maintained index table in the root README — a recipe can live under any
  course and still be found by signal/component/topic.

### Course assignment heuristic

- **starters** — single concept, runs locally with one config, smoke-testable in seconds.
- **mains** — needs Kubernetes, multiple files, or models a realistic end-to-end scenario.
- **desserts** — advanced or "nice to know" showcases that are not everyday building blocks.
- **sides** — not a runnable recipe on its own; a dependency other recipes reuse.

## Per-Recipe Contract

### Folder layout

```text
<course>/<kebab-name>/
  README.md
  otelcol.yaml         # local-binary recipes
  otelcol-cr.yaml      # Kubernetes (OpenTelemetryCollector CR) recipes
  <supporting files>   # *.json, policy files, manifests, etc.
```

Conventions:

- Folder names are kebab-case and descriptive.
- Config files are always `.yaml` (never `.yml`).
- Local config file is `otelcol.yaml`; Kubernetes CR file is `otelcol-cr.yaml`.

### README skeleton

```markdown
# 🍜 Recipe: <Name>

<One- or two-sentence description of what this demonstrates.>

| | |
|---|---|
| **Signals** | traces / metrics / logs |
| **Runs on** | local binary · Kubernetes |
| **Key components** | tailsamplingprocessor, loadbalancingexporter |

## 🧄 Ingredients
- ...

## 🥣 Preparation
1. ...

## 🎯 Key details        ← optional; only when the config needs explaining
...

## 😋 Tested with
- OpenTelemetry Collector Contrib vX.Y.Z
- OpenTelemetry Operator vX.Y.Z   ← only for Kubernetes recipes
```

Rules:

- The metadata table is required and always carries the three rows above.
- `🎯 Key details` is the **only** sanctioned optional section. The previously sprawling
  sections (📖 / 🎓 / 🚀 / 📚 / 🔍) are folded into the description, Key details, or dropped.
- `😋 Tested with` is the standardized heading (replaces all prior variants) and pins concrete
  versions.

## Validation

Each recovered recipe must pass a **runtime smoke test** before it is marked recovered:

- **Local recipes** — run the collector via its Docker image
  (`otel/opentelemetry-collector-contrib:<latest>`), send data with `telemetrygen` (Docker
  image), and observe the expected output (console or output file) described in the README.
- **Kubernetes recipes** — deploy to a real k3d cluster with the OpenTelemetry Operator (and
  cert-manager), apply the manifests, and observe the expected behavior.

"Latest" means the newest released version at recovery time, pinned in the recipe's
`😋 Tested with` section. Available tooling locally: `k3d`, `kubectl`, `docker`. The collector
and `telemetrygen` run via Docker images; `cfssl` is installed on demand for TLS recipes.

## Migration Workflow (the loop being validated)

Per recipe:

1. **Pick** the next recipe/fragment from `MIGRATION.md`.
2. **Recover & modernize** the config to the latest collector/operator (fix deprecations,
   renamed keys, removed components).
3. **Smoke test** per the validation rules above.
4. **Write the README** to the contract above.
5. **Finalize** — set status to `recovered` in `MIGRATION.md`, delete the original file(s),
   add/update the row in the root README index table.
6. **Commit** — each recipe migration is its own commit (the recovered recipe, the deleted
   original, the `MIGRATION.md` status change, and the index update together), so history
   reads one-recipe-per-commit and any single migration can be reviewed or reverted in isolation.

`MIGRATION.md` tracks every legacy recipe and ratatouille fragment with a status:
`pending` / `recovered` / `merged` / `dropped` (with a one-line note for merged/dropped).

## Pilot Scope (this first batch)

Validate the end-to-end workflow with three recipes spanning the spectrum:

1. `log-cleanup` → **`starters/log-deduplication/`** — local Docker smoke test.
2. `target-allocator` → **`mains/target-allocator/`** — full k3d + operator deploy; depends on
   the prometheus app promoted into `sides/`.
3. `ratatouille/simple/blocking.yaml` → **`starters/blocking-exporter/`** — proves the
   ratatouille dissolve/triage path (single concept: disabling the sending queue).

After the pilot, we review the workflow, then proceed to migrate the rest course by course.

## Open Questions / Future Work

- Automating the root index table from per-recipe metadata (deferred).
- Whether `sides/` should also host the LGTM stack docs currently inline in the root README.
- Final disposition of near-duplicate ratatouille fragments (decided per-fragment during triage).

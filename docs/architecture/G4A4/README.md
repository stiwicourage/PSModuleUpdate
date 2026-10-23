# G-4A4 — Cross-platform qualification and GitHub Actions integration

## TL;DR

**Status: planning complete (2026-10-23); Phase 1 is implemented locally but has not run on GitHub.** PSModuleUpdate
(PMU) had no `.github/workflows/`, no Git remote and no CI when this was written. Phase 1 now adds `ci.yml` and
`scripts/build/ci/` (see [PHASE1_IMPLEMENTATION.md](PHASE1_IMPLEMENTATION.md)); Phases 2-4 are not started and no
Windows, Linux or hosted result exists. This folder
records the investigation of PMU, NovaModuleTools (Nova), SemanticRelease and
Gerber and proposes a GitHub Actions architecture that:

- keeps Nova as the only build/version/package/release engine;
- runs a six-lane native matrix (Windows x64, Linux x64, macOS ARM64 × PowerShell
  7.4 and latest stable) on **free standard hosted runners** for public repositories;
- makes publication depend explicitly on one aggregate gate that fails on any
  failed, skipped or cancelled mandatory lane;
- needs no permanent infrastructure.

The headline finding is that Nova's own `Publish.yml` (the pattern PMU would
inherit) **does not gate publication on the cross-job test suite**. It runs only
`Test-NovaBuild` on `main` and then calls `Invoke-NovaRelease … -SkipTests`; the
unit suite runs in a separate workflow that does not run on pushes to `main` and
is not a declared dependency. See [NOVA_RELEASE_ANALYSIS.md](NOVA_RELEASE_ANALYSIS.md).

## Status vocabulary

| Label | Meaning |
| --- | --- |
| IMPLEMENTED | Present in the inspected source and verified by reading it |
| EXISTING | Existing documented behavior or proposal in a repository (not necessarily executed) |
| PROPOSED | G-4A4 recommendation requiring approval |
| NOT VERIFIED | Could not be confirmed from repositories or fetched documentation |
| NOT SUPPORTED | Confirmed not possible/not provided |

## Documents

| # | Deliverable | File |
| --- | --- | --- |
| 1 | Architecture and integration analysis | [ARCHITECTURE_AND_INTEGRATION.md](ARCHITECTURE_AND_INTEGRATION.md) |
| 2 | Existing GitHub Actions workflow map | [WORKFLOW_MAP.md](WORKFLOW_MAP.md) |
| 3 | NovaModuleTools release integration analysis | [NOVA_RELEASE_ANALYSIS.md](NOVA_RELEASE_ANALYSIS.md) |
| 4 | Runner feasibility report | [RUNNER_FEASIBILITY.md](RUNNER_FEASIBILITY.md) |
| 5 | Test classification and execution policy | [TEST_EXECUTION_POLICY.md](TEST_EXECUTION_POLICY.md) |
| 6 | Release-gating design | [RELEASE_GATING.md](RELEASE_GATING.md) |
| 7 | Security and credential model | [SECURITY_MODEL.md](SECURITY_MODEL.md) |
| 8 | Shared infrastructure ownership | [OWNERSHIP_RECOMMENDATION.md](OWNERSHIP_RECOMMENDATION.md) |
| 9 | Implementation roadmap | [ROADMAP.md](ROADMAP.md) |
| 10 | Decision and approval register | [DECISION_REGISTER.md](DECISION_REGISTER.md) |
| 11 | Phase 1 implementation record | [PHASE1_IMPLEMENTATION.md](PHASE1_IMPLEMENTATION.md) |

Related earlier proposals: [strategy](../CROSS_PLATFORM_TESTING.md),
[matrix](../TEST_MATRIX.md), [roadmap](../TEST_IMPLEMENTATION_ROADMAP.md),
[G-4A3 closure](../G4A3_CLOSURE.md). G-4A3 evidence is unchanged and still
macOS/PowerShell 7.6.6/PSResourceGet 1.2.0 only.

## Investigation boundary

Read-only inspection of Nova, SemanticRelease and Gerber; the only writes are
these planning documents plus pointer edits in `PLAN.md`, `DECISIONS.md` and
`CONTRIBUTING.md`. No production code, tests, workflows, Git state, tags or
releases were touched. Runner and PowerShell facts were fetched on 2026-10-23
from `actions/runner-images`, GitHub documentation and the PowerShell release
feed; those are point-in-time observations.

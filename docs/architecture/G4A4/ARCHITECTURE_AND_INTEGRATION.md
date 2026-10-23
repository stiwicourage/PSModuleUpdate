# Architecture and integration

## TL;DR

PROPOSED: three PMU workflows (`ci.yml`, `qualification.yml`, `release.yml`) plus a
manual `external-integration.yml`. `ci.yml` is reusable and is the only place the
six-lane matrix is defined; `release.yml` calls it. A single `ci-gate` job is the
required status check. Nova remains the build, test, version and publish engine.

## Workflows (all PROPOSED)

| Workflow | Triggers | Jobs | Secrets |
| --- | --- | --- | --- |
| `ci.yml` | `push` (feature, `develop`), `pull_request`, `workflow_call`, `workflow_dispatch` | `quality`, `platform` (6 lanes), `ci-gate` | none |
| `qualification.yml` | nightly `schedule`, `workflow_dispatch` | privileged AllUsers, kill recovery, local-feed rows on the six lanes | none |
| `release.yml` | `push` to `main`, `workflow_dispatch` | `validate` (calls `ci.yml`), `release` | `PSGALLERY_API` in the `release` environment |
| `external-integration.yml` | `workflow_dispatch` | protected-environment provider checks | environment secrets |

## Lane matrix

| Lane | Runner label | PowerShell |
| --- | --- | --- |
| win-74 / win-latest | `windows-2025` | 7.4.x / latest stable |
| linux-74 / linux-latest | `ubuntu-24.04` | 7.4.x / latest stable |
| mac-74 / mac-latest | `macos-15` (arm64) | 7.4.x / latest stable |

Each lane runs a project-owned lane script that provisions the pinned `pwsh`,
asserts OS, architecture and versions, then runs Nova's build, `Invoke-NovaTest`
and `Test-NovaBuild` in fresh processes, and writes a lane manifest. See
[RUNNER_FEASIBILITY.md](RUNNER_FEASIBILITY.md) and
[TEST_EXECUTION_POLICY.md](TEST_EXECUTION_POLICY.md).

## Gate

`ci-gate` runs with `if: always()` and fails unless every mandatory result is
`success` and all six lane manifests exist. Details in
[RELEASE_GATING.md](RELEASE_GATING.md).

## Integration boundaries

| Component | Role |
| --- | --- |
| NovaModuleTools | Unchanged release engine; PMU calls its commands |
| SemanticRelease | Reference only |
| Gerber | Later consumer of the same pattern ([OWNERSHIP_RECOMMENDATION.md](OWNERSHIP_RECOMMENDATION.md)) |
| Composite actions | Copied from Nova and adapted |

Security rules are in [SECURITY_MODEL.md](SECURITY_MODEL.md); phases in
[ROADMAP.md](ROADMAP.md).

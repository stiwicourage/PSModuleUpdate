# Existing GitHub Actions workflow map

## TL;DR

Only Nova and SemanticRelease have workflows (identical `Publish.yml`; `Tests.yml`
differs only in script names). PMU has none; Gerber has no `.github/workflows`.
No workflow declares a dependency on another, and nothing in a repository file
shows branch protection or required checks.

## Repositories inspected

| Repository | Branch seen | Remote | Workflows | Notes |
| --- | --- | --- | --- | --- |
| PSModuleUpdate | `develop` | none configured | none | `scripts/build`, `scripts/qualification`, `run.ps1` only |
| NovaModuleTools | `develop` | `github.com/stiwicourage/NovaModuleTools` (public) | `Tests.yml`, `Publish.yml`, `powershell.yml`, `dependency-review.yml` | Five composite actions under `.github/actions/` |
| SemanticRelease | `develop` | `github.com/stiwicourage/SemanticRelease` (public) | Same four, same actions | Reference only |
| Gerber | `feature/mainstream` | `github.com/stiwicourage/Gerber`; unauthenticated API returns 404 (private or not yet published; NOT VERIFIED) | none | `.github` has only agents/instructions/prompts/skills |

## Nova workflow behavior (IMPLEMENTED; identical in SemanticRelease)

| Question (brief §4) | Answer |
| --- | --- |
| 1 Feature branches | `Tests.yml` on `push` to every branch except `main`; `powershell.yml` (PSScriptAnalyzer SARIF) on every `push` |
| 2 Pull requests | `Tests.yml` on PRs to `main` and `develop`; `powershell.yml` and `dependency-review.yml` on PRs to `develop`; CodeScene coverage gate job on PRs |
| 3 develop | `Tests.yml` (push) plus CodeScene analysis job on push to `develop`; `Publish.yml` does **not** trigger on `develop` pushes |
| 4 main | Only `Publish.yml` (`push` to `main`, or `workflow_dispatch`); `Tests.yml` is `branches-ignore: main`; `powershell.yml` runs on any push |
| 5 Tests | `Tests.yml` → `scripts/build/ci/Invoke-NovaModuleToolsCI.ps1`: `Invoke-NovaBuild`, then `Invoke-NovaTest` and `Test-NovaBuild` each in a fresh `pwsh`; also hourly `schedule` (`0 * * * *`) |
| 6 Builds | `Invoke-NovaBuild` in `Tests.yml` and `Invoke-NovaBuild -ContinuousIntegration` in `Publish.yml` |
| 7 Version calculation | Inside `Invoke-NovaRelease` (`Update-NovaModuleVersion`, inferred from Git commit messages); `Update-NovaModuleVersion -Preview -ContinuousIntegration` for the next preview |
| 8 Packages | Inside `Invoke-NovaRelease`/`Publish-NovaModule`; no workflow step produces a separate package artifact |
| 9 PSGallery publication | `Publish.yml`: `Invoke-NovaRelease -Repository PSGallery -ApiKey … -SkipTests` (main); `Publish-NovaModule … -SkipTests` appears under `github.ref_name == 'develop'` steps |
| 10 Commits/tags | `Publish.yml` composite actions `create-verified-commit` (REST API commit), `update-git-ref`, `create-annotated-tag`; also resets `develop` to `main` and force-updates it |
| 11 Can skip tests | `Publish.yml` always passes `-SkipTests` to the publishing command |
| 12 Workflow dependencies | None across workflows. Within `Tests.yml`, CodeScene jobs `needs: test-and-coverage` |
| 13 Required before merge | NOT VERIFIED: branch protection is configured in GitHub settings and requires admin API access (401 unauthenticated) |
| 14 Required before publish | Within `Publish.yml` only: successful `Install-CiPowerShellModules`, `Invoke-NovaBuild`, `Test-NovaBuild` steps (sequential steps in one job) |

## Observations that affect G-4A4

1. **`develop` publication branch is effectively unreachable.** `Publish.yml`
   triggers on `main` only; the `github.ref_name == 'develop'` steps can run only
   through a manual `workflow_dispatch` on `develop`.
2. **No `concurrency` group** in `Publish.yml`; two pushes to `main` can release in
   parallel.
3. **No GitHub environment** and no required reviewer on the publishing job.
   `contents: write` and `actions: write` are granted to the whole workflow.
   `PSGALLERY_API` is passed only to the two publishing steps (good).
4. **Hourly cron** in `Tests.yml` multiplies hosted-runner use; fine for a public
   repository, expensive for a private one.
5. Actions are referenced by mutable tag (`actions/checkout@v4`,
   `actions/github-script@v7`) except the third-party PSScriptAnalyzer action,
   which is pinned to a commit SHA.
6. Composite actions are copied verbatim between Nova and SemanticRelease: a
   concrete example of duplication cost (see
   [OWNERSHIP_RECOMMENDATION.md](OWNERSHIP_RECOMMENDATION.md)).
7. `ensure-psresource-repository` shows the established PSResourceGet store
   location on Linux (`~/.local/share/PSResourceGet`).

## SemanticRelease classification

Reference implementation of existing PowerShell-module GitHub conventions only.
It is a separate module for Azure DevOps/Java application delivery, is not the
release engine for PMU and must not become a PMU dependency. Its workflows add no
behavior beyond Nova's.

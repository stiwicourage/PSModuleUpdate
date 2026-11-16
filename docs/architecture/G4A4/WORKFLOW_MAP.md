# GitHub Actions workflow ownership

## Current shared-workflow migration

PSModuleUpdate keeps `.github/workflows/Run-Platform-Matrix.yml` and `scripts/build/ci/` lane
qualification locally. Six Windows/Linux x64 and macOS ARM64 lanes cover
PowerShell 7.4 and stable, with unchanged provisioning, exact skip policy,
full-SHA action pins, artifact validation, and aggregate `ci-gate`.

| Caller | Shared owner | Project-specific contract |
| --- | --- | --- |
| `Tests.yml` | `powershell-ci/.github/workflows/tests.yml` | Common analyzer 1.25.0 and both release files; PMU isolation/Pester 5.7.1 exceptions; JaCoCo 95%; shared analysis/artifact defaults |
| `Publish.yml` | `powershell-ci/.github/workflows/publish.yml` | Main push/manual dispatch, Test-NovaBuild, CI-release mode, isolated dependencies |
| `Security.yml` | Shared CodeQL, SARIF analyzer, dependency-review workflows | Common develop push/PR and weekly Monday schedule; PR-only dependency review with shared default severity |
| `.github/dependabot.yml` | GitHub Dependabot | Common weekly GitHub Actions updates and powershell-ci group |

The shared test workflow owns generic Nova orchestration and coverage uploads.
Each isolated job owns its dependency root and cleanup; imports do not survive
fresh PowerShell steps. `run.ps1` and the local analyzer wrapper remain valid
developer entrypoints. Consumer tests cover caller contracts, not upstream
dependency implementation.

Only PSModuleUpdate uses `@develop` for qualification. GerberCore and
SemanticRelease retain `@0.1.1`, including GerberCore's direct install-action
ref; Gerber.AzureDevOps retains its existing `@0.1.0`. PSModuleUpdate moves to a
real release tag only after upstream qualification and a separately authorized
release. Record the
resolved upstream commit for every run; a local sibling change is not
automatically available to GitHub.

Publish follows GerberCore: stable release publishes and updates main, then
prepares/force-updates develop; dispatch on develop publishes a prerelease and
bumps the next version. Both release documents are moved during stable release.
There is no newly introduced cross-workflow dependency or environment-approval
gate. Successful publisher build/tests are not evidence that all six matrix
jobs passed; hosted branch-protection settings are configured separately.

## Historical discovery snapshot

The sections below preserve the original G-4A4 investigation. Statements about
missing PMU workflows, remotes, or copied actions describe that historical
checkout and are superseded by the current ownership map above. They are not
claims about current hosted qualification.

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

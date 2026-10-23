# NovaModuleTools release integration analysis

## TL;DR

Nova release is `build → (tests) → version bump → rebuild → publish`, and tests
are optional via `-SkipTests`. Nova's own `Publish.yml` always skips them inside
the release command, because it ran `Test-NovaBuild` earlier. That earlier run is
build-validation only; the unit flow does not run on `main` pushes. Nova offers
all primitives PMU needs, so no competing engine is required, but PMU must add the
explicit test-to-publish dependency itself.

## Traced call chain (IMPLEMENTED)

| Step | Source | Behavior |
| --- | --- | --- |
| `Invoke-NovaRelease` | `src/public/InvokeNovaRelease.ps1` | Builds a workflow context; `ShouldProcess` supports `-WhatIf`; calls `Invoke-NovaReleaseWorkflow` |
| `Invoke-NovaReleaseWorkflow` | `src/private/release/InvokeNovaReleaseWorkflow.ps1` | 1) `Invoke-NovaBuild` 2) unless `SkipTestsRequested`: `Invoke-NovaTest` then `Test-NovaBuild` 3) `Update-NovaModuleVersion` 4) `Invoke-NovaBuild` again 5) publish action (local deploy or repository publish) |
| `Update-NovaModuleVersion` | `src/private/release/GetNovaVersionUpdateWorkflowContext.ps1` | Infers Major/Minor/Patch from Git commit messages; requires Git history (`fetch-depth: 0`) unless `-OverrideWarning`; updates `project.json` version |
| `Publish-NovaModule` | `src/public/PublishNovaModule.ps1` | `Invoke-NovaBuildValidation` (build, then unless skipped `Invoke-NovaTest` + `Test-NovaBuild`) then publish |
| `Invoke-NovaTest` / `Test-NovaBuild` | `src/public/InvokeNovaTest.ps1`, `TestNovaBuild.ps1` | Unit mode versus BuildValidation mode of the same Pester runner; both accept `-TagFilter` and `-ExcludeTagFilter`; `Invoke-NovaTest` accepts a guarded `PesterConfigurationOverride` |
| `New-NovaModulePackage` | `src/public/NewNovaModulePackage.ps1` | Packages per `project.json` `Package.Types` (PMU: NuGet into `artifacts/packages`) |

## Questions from the brief

**Does release run tests directly?** Yes, by default (step 2 above). The skip is
opt-in per call.

**Is `-SkipTests` safe in the existing context?** Only conditionally.

- In `Publish.yml` the skip follows `Test-NovaBuild` in the same job on the same
  checkout, so the checked-out commit is build-validated.
- It is not safe as a statement that the full suite passed: `Invoke-NovaTest` is
  absent from `Publish.yml`; `Tests.yml` excludes `main` pushes
  (`branches-ignore: main`), so unit coverage for a `main` SHA exists only if a
  pull request check ran earlier on equivalent content. No workflow dependency or
  SHA comparison enforces that.
- The tested tree (pre-bump) differs from the released tree (version bump,
  rebuilt module). Only the version-bump delta is expected; this is not asserted.

**Does the release reuse earlier results?** The implemented behavior is
implicit reuse of PR checks, not a mechanism. G-4A4 does not endorse it
(brief §2.6).

## Post-publish ordering risk

`Publish.yml` publishes to PSGallery first, then moves changelog entries, creates
the verified release commit, fast-forwards `main` (`update-git-ref` without
`force`), tags, and force-resets `develop`. A failure after publication leaves a
published version with no commit/tag; PSGallery versions cannot be re-published.
The non-forced `main` update provides some race protection (it fails if `main`
moved). PROPOSED mitigation: keep the order (publishing cannot be rolled back),
add a pre-publish gate and a stale-tip check; see [RELEASE_GATING.md](RELEASE_GATING.md).

## Reusable for PMU (IMPLEMENTED in Nova)

| Capability | Reuse |
| --- | --- |
| `Invoke-NovaBuild`, `Invoke-NovaTest`, `Test-NovaBuild`, `New-NovaModulePackage`, `Update-NovaModuleVersion`, `Invoke-NovaRelease`, `Publish-NovaModule` | Use as-is; PMU `project.json` already follows schema v3 |
| NUnit XML output | `Pester.TestResult.Enabled: true`, `NUnitXml` already configured by PMU |
| Composite actions `create-verified-commit`, `update-git-ref`, `create-annotated-tag`, `ensure-psresource-repository`, `check-coverage` | Copy-adapt, or consume once extracted (see ownership document) |
| `Install-CiPowerShellModules.ps1` | Installs Pester `5.7.1`–`5.10.0` plus Nova/KeepAChangelog from PSGallery; PMU `run.ps1` already enforces the same Pester range |

## Not provided by Nova (NOT SUPPORTED / not found)

- No built-in matrix, runner or PowerShell-version provisioning.
- No flag to select a PowerShell runtime for Nova; the strategy documents already
  note this ([strategy](../CROSS_PLATFORM_TESTING.md#runtime-os-and-architecture-policy)).
- No option to publish an already-built package without rebuilding it:
  `Publish-NovaModule` and `Invoke-NovaRelease` both call `Invoke-NovaBuild`.
  Consequence: validating the exact published bytes before publication needs the
  candidate approach in [RELEASE_GATING.md](RELEASE_GATING.md).
- No dependency on SemanticRelease; none is introduced.

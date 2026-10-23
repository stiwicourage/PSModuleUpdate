# G-4A3 closure

## TL;DR

**Closed on 2026-10-23: functionally complete and accepted within the qualified
scope.** The project owner explicitly accepts the remaining CodeScene and SIG
findings. This closes development, not universal production qualification.
Windows, Linux, PowerShell 7.4, real AllUsers mutation, live Nexus, and private
Azure prerelease progression have not been qualified.

No production code, tests, public API, provider behavior, or Nova Init
implementation is changed by this closure. The owner reports that the initial
HEAD failure was caused by Git hook execution before an initial commit existed
and is resolved; it is not an outstanding Nova Init defect.

## Evidence and provenance

This closure reviews existing reports; it does not rerun or reinterpret their
tests. The owner's final implementation report is confirmed by the preserved
local wrapper log, NUnit result summaries, package records, quality inventories,
and final-artifact live report listed below. Historical and final runs remain
separate.

The qualified environment was **macOS, PowerShell 7.6.6, PSResourceGet 1.2.0**.
The final live artifact's generated `PSModuleUpdate.psm1` SHA256 was:

```text
C9BEC7323C6E29CDF187BDEB29C8DFE0F496C0BCCFD3A7AB4A7136E39BBC6356
```

| Area | Recorded result | Boundary |
| --- | --- | --- |
| Local quality wrapper | Analyzer, Nova build, unit flow, integration flow, and text formatting passed | Existing `artifacts/final-quality.log`; no rerun for this prose change |
| Unit flow | 287 passed, 0 failed, 1 skipped; 288 discovered | The Windows ACL case was skipped, not passed; process fixtures run in this flow despite their `tests/integration/` location |
| Build-validation integration flow | 5 passed, 0 failed, 3 skipped; 8 discovered | Three opt-in live Pester cases were skipped |
| Process recovery and concurrency | Fresh-process recovery, backup-only recovery, two cooperating processes, competing-lock timeout, hard-kill lock release/recovery, and loaded-state reporting passed in disposable fixtures | Real processes with controlled provider/filesystem fixtures; not hard-killing a live remote provider, a VM, or storage |
| Local native provider | Preview progression, same-base replacement, stable promotion, and four-component version installation passed | Registered name and unregistered file URI on macOS; not private Azure prerelease progression |
| PSGallery live | ThreadJob 2.0.3 to 2.1.0 installed and verified; 62 Pester prereleases discovered | Discovery is not prerelease installation/progression |
| NuGet.org live | NuGet.Versioning 6.12.1 acquired; rejected as a nonmodule with `PMU.ModuleIdentityMismatch`; two Newtonsoft.Json prereleases discovered | Does not establish installation of arbitrary NuGet packages or a suitable PowerShell module from NuGet.org |
| Private Azure live | HashUtil 1.4.74 to 1.4.75 installed and verified with separate per-call credentials | Stable progression only; zero previews for this fixture does not describe the entire feed |
| Unregistered private HTTPS-v3 live | Zero endpoint registrations before planning; actual temporary Get/Install transport, unchanged WhatIf, verified install, credential-free objects, and cleanup passed | Authenticated private endpoint; unregistered public Gallery/NuGet HTTPS paths were not separately executed |
| Cleanup | Zero qualification/native registrations and transport receipts; unrelated registration snapshots preserved; secret-value scan passed | Recorded batch boundary, not an atomic-cleanup or external-writer guarantee |
| Packaging | Local NuGet payload and manifest matched final generated module/help; archive verification passed | No publication or package installation; archive SHA256 `c95b5d81f30570fa5ef907541911b1cd4797e6a24b787a3a3d317c5c3af7d2e7` |
| Coverage | Not measured | Test counts are not a coverage percentage |

The four live runs were standalone child-process runs. **They are not four
additional Pester integration passes.**

### Preserved report inventory

These are local execution artifacts, not guaranteed tracked or available in a
fresh clone. This tracked summary preserves their scope and outcomes; future
qualification must retain sanitized reports in durable CI/release artifacts.
Do not delete or overwrite the original evidence to update documentation.

- `artifacts/final-quality.log`
- `artifacts/UnitTestResults.xml`
- `artifacts/TestResults.xml`
- `artifacts/package-report.json`
- `artifacts/package-integrity.json`
- `artifacts/CodeHealth-current.json` (recorded 2026-10-23T04:44:24Z)
- `artifacts/SIG-current.json`
- `artifacts/qualification/final-20261023T044229Z/G-4A3-final-live-report.json`
  (reported 2026-10-23T04:48:32Z)
- `artifacts/qualification/final-20261023T044229Z/artifact-identity.json`
- `artifacts/qualification/final-20261023T044229Z/cleanup-and-secret-isolation.json`
- Per-scenario `gallery.json`, `nuget.json`, `azure.json`, and
  `azure-unregistered-http-v3.json` in that final report directory
- Earlier `artifacts/qualification/G-4A3-live-report.json` and
  `artifacts/qualification/historical-373E5C3DE5FC/`; these qualify the older
  `373E5C3DE5FC...` artifact, not the final artifact by implication

Intermediate diagnostics remain historical evidence, including the
`artifacts/help-validation.log` import-diagnostics exception. The final wrapper
records successful generated-help integration cases; this closure does not
relabel that earlier failed attempt as a passing standalone help-import check.

### Historical architecture reconciliation

The read-only sibling Gerber architecture reports remain unchanged:

| Historical source under `../Gerber/docs/architecture/` | Reconciliation at closure |
| --- | --- |
| `G-4A0-shared-self-update-analysis.md:8-20` | Build-time shared-source recommendation superseded by G-4A1 independent module ownership |
| `G-4A1-psmoduleupdate-design.md:11-47` | Independent runtime module retained; CurrentUser-first/collision-rejection/no-rollback constraints superseded by approved PMU decisions |
| `G-4A2-psresourceget-provider-qualification.md:1-40,340-385` | macOS/7.6.6/provider 1.2.0 evidence retained; original same-base rejection superseded, not rewritten as an earlier pass |
| `G-4A2-FIX1-azure-artifacts-authentication.md:300-359` | Resumed authentication/discovery/save succeeded after initial 401 blocker; its then-unqualified installation scope is extended only by the final PMU stable-install report |
| `G-4A2-FIX2-installation-scope-and-prerelease-replacement.md:180-232` | Strategy C/both scopes/recovery direction implemented; local replacement evidence did not qualify real AllUsers/private preview or other OSes |

No final G-4A3 implementation report exists in Gerber's architecture directory.
The final PMU artifacts and owner-provided implementation report are the closure
sources; an earlier Gerber document saying G-4A3 was not started is historical,
not current PMU status.

## Accepted quality findings

**Status: risk accepted by the project owner, not all thresholds passed.**
CodeScene scores are indicators, not absolute G-4A3 acceptance requirements.
No score-driven refactoring is authorized by this closure.

The retained CodeScene inventory covers 349 authored PowerShell files: 344
have numeric scores, including 343 at 10.0 and the public planning command at
9.68. Five entries have null scores; those are not invented 10.0 results.
The recorded non-10 finding is:

| File | Finding | Recorded evidence | Acceptance |
| --- | --- | --- | --- |
| `src/public/Get-PSModuleUpdate.ps1` | Excess function arguments | 9.68; five declared parameters versus tool threshold four | Preserve the approved public API and distinct repository parameter sets |

The retained manual SIG inventory reports 244 named units and eight findings:

| File / unit | Whole-unit lines | Branch points | Parameters |
| --- | --- | --- | --- |
| `src/private/planning/Get-PlanRuntimeField.ps1` / `Get-PlanRuntimeField` | 16 | 0 | 1 |
| `src/private/repository/Get-RepositorySnapshotByUri.ps1` / `Get-RepositorySnapshotByUri` | 12 | 6 | 2 |
| `src/private/repository/Register-OwnedRepository.ps1` / `Register-OwnedRepository` | 18 | 5 | 1 |
| `src/public/Get-PSModuleUpdate.ps1` / `Get-PSModuleUpdate` | 13 | 0 | 5 |
| `tests/TestHelpers/Get-PMUTestCommandReference.ps1` / `Get-PMUTestCommandReference` | 13 | 5 | 2 |
| `scripts/build/Test-TextFileFormatting.ps1` / `Test-TextFileFormattingCandidate` | 23 | 1 | 1 |
| `scripts/build/Test-TextFileFormatting.ps1` / `Get-TextFileFormattingRelativePath` | 18 | 1 | 2 |
| `scripts/qualification/QualificationScenario.ps1` / `Get-QualificationPlan` | 14 | 5 | 2 |

Counts use the report's whole-declaration convention, including attributes,
parameters and braces, excluding blank/comment-only lines; branch counting
includes alternatives, switch arms, loops, catches and explicit Boolean
decisions. These are manual indicators, not exact CodeScene metric equivalents.
The table preserves reported counts, rather than recomputing history.

The owner accepts these residual maintainability findings in this completed
scope. Do not change public parameters, split coherent functions, or rewrite
branches solely to meet a numerical limit. Test/support code and production
code can legitimately have different complexity characteristics. Acceptance
does not waive functional defects, credential safety, or future review of
substantive changes, and does not alter shared tooling policy globally.

## Outstanding qualification: separate phase

| Gap | Required new evidence |
| --- | --- |
| Windows and Linux | Native OS execution, including filesystem, locking, discovery and process semantics |
| PowerShell 7.4 | Explicit minimum-version runs on all three OS families; latest-version success is not a substitute |
| Real AllUsers | Authorized disposable elevated installation/replacement and negative non-elevated permission cases |
| Windows loaded files | Native loaded script and binary/file-lock cases with actual provider behavior |
| Private Azure prerelease | Authorized suitable package versions for exact preview-to-preview and preview-to-stable progression |
| Nexus | Authorized compatible NuGet-v3 endpoint and package fixture |
| Additional provider versions | Separate pinned compatibility rows beyond 1.2.0 |
| Deeper environment recovery | Real-provider interruption, transport crash windows, persistent VM restart/recovery, dependencies and additional filesystems as scoped in the strategy |

Existing process fixtures already passed on macOS. Repeating them on new OS
families or adding real-provider/VM fault testing extends qualification; it
does not reopen completed implementation by default.

The proposed next phase is documented in
[cross-platform testing strategy](CROSS_PLATFORM_TESTING.md),
[test matrix](TEST_MATRIX.md), and
[implementation roadmap](TEST_IMPLEMENTATION_ROADMAP.md). Those documents are
plans requiring approval, not implemented infrastructure or executed results.

## Documentation-only verification

The closure/strategy change is prose only. Repository text formatting, Markdown
fence/local-link structure, diff whitespace and source/test/artifact preservation
checks passed. No behavioral suite, live qualification, build or packaging was
rerun; the counts above are preserved historical results.

`README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, and `RELEASE_NOTE.md` were
reviewed. The first three link or record the new maintainer documentation.
Release notes and generated command help remain unchanged because public
commands, parameters, installation workflows and supported-platform claims did
not change. CodeScene measurements are not applicable to this prose-only diff;
the existing implementation findings retain their recorded owner acceptance.

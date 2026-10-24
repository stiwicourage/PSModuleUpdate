# G-4A4 Phase 1 - GitHub Actions platform matrix

## TL;DR

**Status: first GitHub run executed; both macOS lanes passed, both Windows and both Linux lanes failed.**
The first run is recorded below; the complete matrix is not yet qualified. Phase 1 adds
`.github/workflows/ci.yml` (reusable, six lanes, `ci-gate`) and helper scripts under
`scripts/build/ci/`. It reuses the existing Nova flow (`Invoke-NovaBuild`, `Invoke-NovaTest`,
`Test-NovaBuild`) and does not change Nova, release, publishing or credentials.

| Label | Meaning here |
| --- | --- |
| IMPLEMENTED | Present in the repository and covered by local tests |
| LOCALLY VERIFIED | Executed in the explicitly named local environment, not a hosted-runner result |
| HOSTED RESULT | Observed in the linked GitHub run, for its exact commit |
| NOT VERIFIED | Still needs successful execution on the relevant environment |

## Workflow structure (`.github/workflows/ci.yml`)

| Job | Runner | Purpose |
| --- | --- | --- |
| `plan` | `ubuntu-24.04` | Builds the matrix from `scripts/build/ci/CiLanes.json` (single source for matrix and gate) |
| `quality` | `ubuntu-24.04` | ScriptAnalyzer (`Invoke-ScriptAnalyzerCI.ps1`) and `Test-TextFileFormatting.ps1` |
| `platform` | per lane | Provision PowerShell, install modules, run the lane, upload artifacts |
| `ci-gate` | `ubuntu-24.04` | Aggregate gate; always evaluated |

## Triggers

`pull_request` to `develop` or `main`; `push` to `develop` or `main`; `workflow_call` (reuse by a future
release workflow); `workflow_dispatch`. There is no trigger for feature-branch pushes, so a pull request does
not run twice. Concurrency cancels superseded pull-request runs only; `workflow_call` and push runs are never
cancelled by another run. Phase 2 must remove the `main` push trigger if `release.yml` calls this workflow.

## Matrix

| Lane id | Runner label | Arch | PowerShell |
| --- | --- | --- | --- |
| `windows-x64-ps74` | `windows-2025` | x64 | 7.4 (pinned 7.4.21) |
| `windows-x64-psstable` | `windows-2025` | x64 | latest stable |
| `linux-x64-ps74` | `ubuntu-24.04` | x64 | 7.4 (pinned 7.4.21) |
| `linux-x64-psstable` | `ubuntu-24.04` | x64 | latest stable |
| `macos-arm64-ps74` | `macos-15` | ARM64 | 7.4 (pinned 7.4.21) |
| `macos-arm64-psstable` | `macos-15` | ARM64 | latest stable |

No `*-latest` labels are used (enforced by a test). On 2026-10-23, the
[official GitHub runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners#standard-github-hosted-runners-for-public-repositories)
explicitly lists `macos-15` in the **arm64** standard public-repository table;
the Intel label is `macos-15-intel`. These standard hosted runners are free for
public repositories and GitHub creates a fresh VM per job. Therefore the
approved `macos-15` label is retained, not inferred from its OS version.

The [official macOS 15 ARM64 image inventory](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-arm64-Readme.md)
lists preinstalled PowerShell 7.6.5 as the provisioning bootstrap.
[Microsoft's macOS installation documentation](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-macos?view=powershell-7.4)
lists macOS 15 ARM64 as supported and provides native `osx-arm64` archives
for 7.4 and stable PowerShell.
This establishes documented availability, **not execution qualification**:
runtime OS/architecture/edition/version/runner checks remain mandatory. Neither
the documented support alone nor a local Mac result establishes hosted qualification. Both hosted Mac lanes
subsequently passed in the first run recorded below.

## PowerShell provisioning

`Install-CiPowerShell.ps1` downloads the official release archive, verifies SHA-256 and extracts it into a
job-owned directory. It probes the extracted executable for exact version, Core edition, OS and CPU architecture,
then records its absolute executable path and runtime in `provisioning.json`. The workflow invokes that
absolute executable for dependency provisioning and lane execution; `GITHUB_PATH` is supplementary, not the
version-selection mechanism. Each build/test phase also uses the selected absolute executable.
Channel `7.4` is pinned in `PowerShellVersions.json` with a
checksum per runtime (values taken from the official `hashes.sha256`). Channel `stable` resolves the tag from
the official `tools/metadata.json` and takes the checksum from the same release's `hashes.sha256`; that is an
integrity check, not independent provenance. Updating the 7.4 pin is a reviewed change.

Stable metadata must identify a numeric stable release, not a preview. Metadata, download, checksum,
extraction or executable-probe errors fail provisioning without a fallback. Stable is resolved once per lane:
its exact version is passed through every phase and retained in the manifest. Different lanes resolve
independently; this is not a global version lock across a release boundary.

## Environment verification

Before running tests, `Invoke-PlatformLane.ps1` checks OS, OS and process architecture, PowerShell version
(exactly the provisioned one, and inside the requested channel), edition `Core`, `RUNNER_OS`, `RUNNER_ARCH` and,
on GitHub, `RUNNER_ENVIRONMENT=github-hosted`. Any mismatch skips the tests and fails the lane. The manifest and
step summary record all values. Every phase writes its actual process runtime and execution identity.
Unit and integration witness tests additionally write the runtime from inside Nova's real Pester runspace,
including the Pester version actually executing, not the newest installed version.

NovaModuleTools 3.4.3 runs Pester in an in-process runspace. Consequently those test witnesses must have the
same PID, selected executable and version as their corresponding phase process. These are actual
process/runspace checks, not an inference from `PATH` or a second, unrelated probe.

## Test entry points

Each phase runs in a fresh `pwsh -NoProfile` child: `Invoke-NovaBuild`, `Invoke-NovaTest` (unit) and
`Test-NovaBuild` (integration). No alternative runner exists and no assertion was changed. The
`PMU_QUALIFICATION_LIVE` opt-in is unset so live repository checks stay skipped, and the child processes use a
disposable temp directory that is removed afterwards. Provider installation fixtures target disposable
CurrentUser locations, not the developer's module installation. There are no destructive AllUsers tests.

Nova's NUnit XML is summary-only. `CiTestResultSummary.ps1` validates its actual structure and consistent
nonnegative integer counts; empty, missing, malformed, unrelated or zero-test reports fail qualification.
Exactly one unit report and one integration report are consumed; reports are cleared before execution,
not combined with older or additional files. Multiple XML documents/suites are rejected.

`CiTestDetail.ps1` captures exact file/name/outcome entries from Nova's Detailed/Ansi console output, strips
ANSI decoration and reconciles every count against the XML. Both representations are retained. Missing or
truncated detail fails closed; no test names are invented from counts. Failures and inconclusive results
cannot pass; both suites must execute passing tests. `CiSkipPolicy.json` permits only the exact existing
file/name/OS combinations inventoried below. Other skips fail qualification, including the POSIX permission
test being skipped by an unexpected root execution on Linux/macOS. Allowed skips are named in the step
summary and remain non-execution, not passes.

## Disposable dependencies

`Install-CiPowerShellModules.ps1` uses `Save-Module -Path`, never CurrentUser/AllUsers installation.
It saves Pester 5.7.1, PSResourceGet 1.2.0, NovaModuleTools, PSScriptAnalyzer, Microsoft.PowerShell.PlatyPS
and their package dependencies into a new `pmu-ci-modules-*` directory. The last three follow their stable
Gallery versions; the selected availability is recorded rather than claimed to be a dependency lock.
The verified PowerShell archives supply the bootstrap PowerShellGet/PackageManagement/NuGet provider.
No Nova changes are required.

The directory must not pre-exist and receives an ownership marker containing its absolute path and a random
token. Cleanup validates that marker, rejects symlink roots or changed ownership and removes only the
owned directory. A standalone lane provisions its own dependencies and cleans up on success or failure;
when `-ModuleRoot` supplies an already provisioned owned directory, the lane consumes and removes it.
The workflow has an additional always-run owned cleanup for failures before lane entry.

`PSModulePath` is explicitly restricted to the owned dependency root and the selected executable's
`$PSHOME/Modules`. Every child inherits it. A probe imports pinned Pester, PSResourceGet and Nova and rejects
loaded modules originating outside those two roots. Phase commands explicitly import Pester 5.7.1.
Neither changing `HOME` nor changing `PSModulePath` is claimed to isolate PSResourceGet repository storage.
Existing provider fixtures still create unique test-owned registrations, remove only those registrations,
and verify existing registration records and store bytes remain unchanged.

## CI gate

`ci-gate` needs `plan`, `quality` and `platform` and runs with `always()`. `Assert-CiGate.ps1` fails when any
required job result is not `success` (failed, cancelled, skipped, missing), and when any lane id from
`CiLanes.json` lacks exactly one downloaded `lane-manifest.json` with `status` `passed` for the current commit,
or when an unexpected lane manifest exists. Hardened validation also requires schema/field types, matching
lane configuration and runtime, hosted-runner metadata, provisioning details, all three successful phases,
actual phase/test runtime witnesses, and matching XML/log/detail test evidence. Empty suites, failed tests,
unexpected skips and missing evidence cannot be hidden behind an aggregate matrix `success`.
A release workflow can depend on this one job. Marking the check
name `ci-gate` as required in branch protection is NOT VERIFIED until GitHub shows it.

## Artifacts

One artifact per lane named `pmu-ci-lane-<run-id>-<run-attempt>-<lane-id>`, uploaded with `always()` and
14-day retention, containing `lane-manifest.json`, both NUnit XML files, `unit-details.json`,
`integration-details.json`, `PSVersionTable.txt`, phase logs, launch contexts and runtime witnesses.
Manifests include the environment, phases, counts, module availability, exact selected runtime and
provisioning details. No credentials or environment dumps are written. A step summary lists each lane result.

The gate removes its stale download directory and downloads only the current run/attempt's artifact pattern,
without a cross-run token or merged artifact directories. Download/digest errors fail the job; they are
not masked with `continue-on-error`. The artifact directory must match its expected lane name; manifest and
runtime identities must agree on SHA, run, attempt, lane, phase and a fresh execution ID. A copied JSON file
with the expected SHA alone is insufficient. This uses GitHub's current-run artifact association and digest
verification, not a new signature/attestation system or independent proof against malicious workflow code.

## Security

For `.github/workflows/ci.yml`: top-level `permissions: contents: read`; no secrets; no publishing; every action is
pinned to a full commit SHA with checkout credentials not persisted; PowerShell downloads are hash-verified.
`tests/repository/CiWorkflow.Tests.ps1` enforces these matrix-specific requirements without applying them to
the separate publish, analysis, dependency-review, or test/coverage workflows. Those workflows may use
version-tagged actions, moving runner labels, and purpose-specific permissions and secrets.
The common prohibition on `pull_request_target` still applies to every workflow, and publishing must not
trigger on pull requests. This policy scope does not establish release qualification or implement the
proposed Phase 2 release gate.

## Initial local validation (historical, before hardening)

| Check | Result |
| --- | --- |
| `Invoke-NovaTest -TagFilter BuildTooling` (new and existing tooling tests) | 83 passed, 0 failed |
| `Invoke-ScriptAnalyzerCI.ps1`, `Test-TextFileFormatting.ps1` | clean |
| `ci.yml` YAML parse | valid |
| `Invoke-PlatformLane.ps1 -LaneId macos-arm64-ps74 -ExpectedPowerShellVersion 7.4.21` | passed: unit 361 passed, 1 skipped; integration 5 passed, 3 skipped |
| Same script with `-LaneId linux-x64-ps74` on this Mac | failed on environment mismatch, as designed |
| `Assert-CiGate.ps1` with only the macOS 7.4 manifest | failed: five lanes produced no manifest, as designed |

actionlint was not run. The Windows lanes, Linux lanes, the macOS stable lane and the hosted-runner behavior of
the provisioning script were not executed.

## Hardening local qualification (2026-10-23)

The interrupted background agent was cancelled; no task-owned test process remained running when work
resumed. Its retained macOS manifest reported success (397 unit passes plus one skip; six integration
passes plus three skips), but the reclaimed shell's exit status was unavailable. That is retained evidence,
not a timeout interpreted as a test failure. The final explicit runs below supersede that evidence for the
current working tree.

| Scope and command | Status | Observed result |
| --- | --- | --- |
| `Invoke-NovaTest -TagFilter BuildTooling -OutputRenderMode Ansi` | Passed | 135 passed, zero failed/skipped; includes CI, repository workflow and existing BuildTooling tests |
| `run.ps1` using the owned dependency path under selected 7.4.21 | Passed | Analyzer, Nova build, 413 unit passes/one expected skip, six integration passes/three expected skips, formatting; exit 0 |
| macOS ARM64 `macos-arm64-ps74`, explicit provisioned 7.4.21 | Passed | All three phases exit 0; 413 unit passes/one expected skip; six integration passes/three expected skips |
| macOS ARM64 `macos-arm64-psstable`, explicit provisioned stable 7.6.8 | Passed | Same counts; all phases exit 0; official archive SHA256 and actual executable verified |
| Phase and Nova runspace witnesses in both lanes | Passed | Exact selected executable/version, Arm64, Core, matching execution identity/PID and actual Pester 5.7.1 |
| `actionlint .github/workflows/ci.yml` | Passed | Real actionlint 1.7.12, checksum-verified temporary darwin_arm64 installation; no diagnostics |
| `Invoke-ScriptAnalyzerCI.ps1`, formatting and `git diff --check` | Passed | No remaining diagnostics |
| Before/after dependency and registration storage comparison | Passed | Seven module/repository-store locations compared; no file/availability changes; both owned dependency roots removed |
| GitHub-hosted six-lane workflow, artifact transfer and required-check behavior | Unverified | No repository publication or GitHub execution authorized or performed |

The CurrentUser module directory retained the same 798 files and aggregate content/path fingerprint as
before the preserved earlier lane. The final before/after comparison additionally covered available
CurrentUser/AllUsers module directories and PSResourceGet/PowerShellGet registration-store locations.
Existing CurrentUser PSResourceGet 1.2.0 was neither uninstalled, upgraded nor overwritten.
The provider integration fixtures also verified their actual existing-registration/store preservation.

Negative tooling scenarios cover failed/cancelled/skipped/missing jobs, missing/duplicate/unexpected lane
manifests, invalid JSON/schema/types, empty or incorrect SHA, wrong run/attempt/platform/edition/architecture,
absent runner metadata, missing phases/modules/test reports/logs/runtime witnesses, zero passing execution,
failures, unexpected skips, truncated detail and inconsistent XML counts. Valid synthetic complete bundles
still pass.

Test-first evidence was preserved during hardening. In the resumed work, the artifact-download regression
failed before removal of `continue-on-error` (134 passed, one expected failure), then all 135 tooling tests
passed. The same assertions remained green before and after the small gate-validation refactor. Earlier
typed-evidence and actual-Pester-version regressions were observed failing and then corrected; no assertion
was weakened. The final quality wrapper and both real lanes passed after those corrections.

An analyzer run initially identified two Pester setup-variable scoping warnings and a plural-noun warning;
all three were corrected before the passing wrapper. A mistyped local stable lane ID was rejected before any
tests and its owned dependencies were cleaned; the declared `macos-arm64-psstable` lane subsequently passed.
There are no outstanding local executable-validation failures.

The final pre-commit safeguard passed across all 26 supported changed files, each measured at Code Health
10.0. This is separate from the supplementary manual SIG declaration targets: counting whole declarations,
parameters and braces, excluding blank/comment-only lines, found 18 functions above 15 lines (maximum 31)
and two interfaces above four parameters (maximum seven). These include existing CI provisioning/manifest
builders and the modified phase orchestrator. No whole-scope SIG-compliance claim is made. Meeting those
stricter targets needs an additional bounded CI-structure cleanup; normal quality readiness remains blocked
by that unmet target despite passing functional checks and measured Code Health. Production/G-4A3 code was
not changed to address it.

Logs and actual lane evidence are retained under `artifacts/ci/macos-arm64-ps74/` and
`artifacts/ci/macos-arm64-psstable/`. Local records intentionally lack GitHub-hosted identity and are not
eligible to satisfy a hosted-runner gate.

## Skipped-test inventory

The four skips in the initial macOS run were identified from actual Pester
definitions, including their enclosing `Describe` conditions, not inferred
from the counts. Names below are the exact `It` names.

| File under `tests/` | Test name | Category | Actual skip condition and purpose | Windows | Linux | macOS | Release requirement |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `private/locking/Get-WindowsDirectoryDescriptor.Tests.ps1` | `reads current-user ACL metadata from a disposable directory` | Unit, `PMU`; native Windows descriptor | `-Skip:(-not $IsWindows)`; Windows ACL metadata is not applicable on Unix | Run | Expected skip | Expected skip | Mandatory on Windows; not applicable on Unix |
| `repository/RepositoryProtocol.Integration.Tests.ps1` | `updates an unloaded independent ThreadJob module from PSGallery with exact source binding` | Integration, `RepositoryLive` | Enclosing suite skips unless `PMU_QUALIFICATION_LIVE=1`; real public-feed mutation requires explicit opt-in | Opt-in only | Opt-in only | Opt-in only | Deferred live qualification, not mandatory for the ordinary Phase 1 gate |
| `repository/RepositoryProtocol.Integration.Tests.ps1` | `rejects a real NuGet.org nonmodule package before any installation mutation` | Integration, `RepositoryLive` | Same suite opt-in; a provider rejection can separately yield **inconclusive**, which is not a passing PMU rejection result | Opt-in only | Opt-in only | Opt-in only | Deferred live qualification, not mandatory for the ordinary Phase 1 gate |
| `repository/RepositoryProtocol.Integration.Tests.ps1` | `updates a caller-selected private module with separate credentials and credential-free results` | Integration, `RepositoryLive` | Same suite opt-in; additionally skips without all caller-supplied private fixture inputs and `ADO_PAT` | Opt-in plus private inputs | Opt-in plus private inputs | Opt-in plus private inputs | Deferred private-feed qualification; credentials must not enter Phase 1 |

All four skips are conditional. Phase 1 deliberately clears the live opt-in.
An allowed skip is a declared non-execution, never a passed test or evidence
that the deferred release scenario is qualified. The release-gating design
and historical G-4A3 live evidence remain unchanged; Phase 2 must separately
decide and enforce its required qualification scenarios. No new exemption
from release qualification is approved by allowing these Phase 1 skips:
the live tests' mandatory release status is not established by their skip
definitions.

Other platforms have additional existing conditional skips that must remain
explicit rather than being treated as unexplained failures:

| File under `tests/` | Exact test name | Category and condition | Expected execution |
| --- | --- | --- | --- |
| `repository/QualificationProcess.Tests.ps1` | `canonicalizes the macOS temporary base before applying no-symlink installation guards` | Unit; skips unless macOS | macOS only |
| `private/locking/Get-InstallationLockIdentity.Tests.ps1` | `conservatively shares a lock for differently cased Windows and macOS root aliases` | Unit, `PMU`, `PMULockIdentity`; skips on Linux | Windows and macOS |
| `private/installation/Invoke-UpdateInstallation.Tests.ps1` | `translates actual controlled-directory permission denial before acquiring a lock` | Unit; skips on Windows or when the process user is `root` | Non-root Linux and macOS; Windows permission qualification remains a gap |
| `private/repository/Read-RepositoryReceipt.Tests.ps1` | `rejects a symlink receipt before reading its external contents` | Unit, `PMUUriBridge`; skips on Windows | Linux and macOS |
| `integration/LocalProvider.Integration.Tests.ps1` | `performs licensed offline prerelease progression, stable promotion and four-component installation` | Integration, `PMULocalProvider`; skips unless macOS | macOS only; Windows/Linux real-provider progression remains unqualified |

The initial Nova summary XML contains no individual test names or skip reasons.
It alone cannot reliably establish this inventory or detect which test was
skipped. Detailed execution evidence must accompany the summary; changing
Nova's XML to include per-test identity, outcomes and reasons would be a
useful future Nova improvement, not part of this task.

## First hosted run and platform fixes (2026-10-23)

[Run 39949417203, attempt 1](https://github.com/stiwicourage/PSModuleUpdate/actions/runs/39949417203)
executed `develop` commit `649298434aac533bd308270cf10d7aa4607c400b`. This is execution evidence for
that commit, not proof that subsequent unpushed fixes have passed on GitHub.

| Job/lanes | Hosted result | Observed tests |
| --- | --- | --- |
| `plan`, `quality` | Passed | Matrix generation, isolated analyzer dependencies, ScriptAnalyzer and formatting completed |
| macOS ARM64 / 7.4.21 and stable 7.6.8 | Both passed | Each: 413 unit passes/one expected skip; six integration passes/three expected skips |
| Windows x64 / 7.4.21 and stable 7.6.8 | Both failed | Each: 407 unit passes/four failures/three expected skips; integration did not execute |
| Linux x64 / 7.4.21 and stable 7.6.8 | Both failed | Each: 410 unit passes/one failure/three expected skips; integration did not execute |
| `ci-gate` | Failed as required | Rejected failed matrix status and incomplete/failed lane evidence; did not turn the two passing lanes into a passing matrix |

Provisioning and module saving succeeded on all six hosted lanes. Lane artifact uploads and the gate's
current-run download succeeded; no actual artifact-digest failure was induced.

The four Windows failures have two causes: two tests compare canonical native paths against manually
slash-concatenated expectations (`ActiveState.Tests.ps1`, `Assert-SafePath.Tests.ps1`), and the disposable-home
containment guard in `QualificationSafety.ps1` appends a Unix-only separator, incorrectly rejecting a valid
Windows child before the symlink guard can execute. Both qualification-safety tests retain their intended
containment and symlink rejection contracts.

The Linux failure is in `Resolve-RepositoryTransportRoot.Tests.ps1`: it assumes that changing child `HOME`
never changes the provider's native application-data store. That assumption is not portable to Linux.
Cooperating processes using the same actual provider store must still resolve the same lease root; the
test must control and independently verify that shared store rather than assume macOS HOME semantics.

The gate's missing-summary and incomplete-phase messages are consequences of stopping on failed unit
tests. The gate, skip policy and mandatory phase requirements must not be weakened to hide these failures.
The fixes require a new hosted run before Windows/Linux or the complete matrix can be called qualified.

The follow-up fixes are limited to `scripts/qualification/QualificationSafety.ps1`,
`tests/integration/ActiveState.Tests.ps1`, `tests/private/shared/Assert-SafePath.Tests.ps1`,
`tests/repository/QualificationSafety.Tests.ps1`,
`tests/private/locking/Resolve-RepositoryTransportRoot.Tests.ps1` and
`tests/TestHelpers/Get-PMUNativeRegistryRootProbe.ps1`, plus these status/qualification docs.
Production commands, transport-lock implementation, CI workflow/gate and skip policy are unchanged.

### Post-fix local validation

| Scope and command | Result |
| --- | --- |
| `Invoke-NovaTest -TagFilter PMUActualActive,PMUSafePath,RepositoryQualification,PMUUriBridge` under macOS ARM64 / 7.4.21 | 92 passed, zero failures/skips; the same assertions remained green after extracting the native-store probe helpers |
| `PATH=/tmp/pwsh74:$PATH pwsh -NoLogo -NoProfile -File ./run.ps1` | Exit 0: analyzer, build, 416 unit passes/one expected skip, six integration passes/three expected skips, formatting |
| `Invoke-PlatformLane.ps1 -LaneId linux-x64-ps74 -ExpectedPowerShellVersion 7.4.21 -ProvisioningFile /linux-tools/provisioning.json -ModuleRoot /linux-tools/pmu-ci-modules-regression` under emulated Linux x64 | Exit 0: build, 414 unit passes/three expected skips, five integration passes/four expected skips; complete lane evidence and owned-dependency cleanup passed |

The Linux check used the official Microsoft `7.4-ubuntu-22.04` container image, digest
`sha256:62300a213a9293916333df2b014cd3a8f22fb0b0b65f2bb446aaf436bcf8c868`, with
Linux/amd64 emulation on the local ARM64 Docker host. Its bundled 7.4.6 was only a bootstrap:
the repository provisioner downloaded/checksum-verified the actual 7.4.21 executable used for qualification.
This is Ubuntu 22.04 local evidence, not the hosted Ubuntu 24.04 result.

An initial container attempt had 65 ownership-related failures because the supplied numeric UID had no
matching named account. The corrected disposable container created a real non-root account, its normal
home/cache/config/data directories, and explicit home-local cache/config paths before dropping privileges.
Dependency bootstrap initially also failed without those writable cache directories. No ownership guard,
test assertion or skip policy was changed to accommodate the container. The corrected complete lane passed;
its data-home behavior remained covered by the actual native-store probes.

The original hosted failures supply pre-fix regression evidence. The local checks establish passing fixes
on macOS and Linux, not an observed Windows red-to-green run. Windows and both channel variants still need
the new GitHub matrix execution. The ordinary documented platform skips are unchanged, and no additional
skip is accepted. The previously recorded manual SIG cleanup remains a separate unresolved readiness item.

## Hardening file inventory

Paths below are relative to the repository; no production command, Nova, version pin or later-phase workflow
was changed.

| Change | Directory | Files |
| --- | --- | --- |
| Modified | `.github/workflows/` | `ci.yml` |
| Modified | Repository/docs | `CONTRIBUTING.md`, `docs/architecture/TESTING.md`, `docs/architecture/G4A4/PHASE1_IMPLEMENTATION.md`, `docs/architecture/G4A4/ROADMAP.md` |
| Modified | `scripts/build/ci/` | `Assert-CiGate.ps1`, `CiLaneManifest.ps1`, `CiTestResultSummary.ps1`, `Install-CiPowerShell.ps1`, `Install-CiPowerShellModules.ps1`, `Invoke-PlatformLane.ps1` |
| Added | `scripts/build/ci/` | `CiDependencyProbe.ps1`, `CiDependencyRoot.ps1`, `CiGateEvidence.ps1`, `CiGateSchema.ps1`, `CiRuntimeEvidence.ps1`, `CiSkipPolicy.json`, `CiTestDetail.ps1`, `Invoke-CiPhaseProcess.ps1`, `Write-CiTestRuntimeEvidence.ps1` |
| Modified | Tests | `tests/repository/CiWorkflow.Tests.ps1`; `tests/scripts/build/ci/Assert-CiGate.Tests.ps1`, `CiLaneManifest.Tests.ps1`, `CiTestResultSummary.Tests.ps1`, `Install-CiPowerShell.Tests.ps1`, `Install-CiPowerShellModules.Tests.ps1`, `Invoke-PlatformLane.Tests.ps1` |
| Added | `tests/scripts/build/ci/` | `CiDependencyRoot.Tests.ps1`, `CiGate.TestSupport.ps1`, `CiTestDetail.Tests.ps1`, `Write-CiTestRuntimeEvidence.Integration.Tests.ps1`, `Write-CiTestRuntimeEvidence.Tests.ps1` |

## Remaining qualification gaps

- New GitHub run of the fixes: Windows/Linux unit suites and their not-yet-executed integration phases must
  pass; both macOS lanes must stay green. The first failed run is preserved above.
- Exercise artifact-download/digest failure paths and the successful aggregate gate. Provisioning,
  disposable dependencies and normal artifact transfer have now executed on all hosted platforms.
- Confirm `ci-gate` as a required status check and `macos-15` arm64.
- Detailed-log parsing is intentionally tied to the pinned Pester Detailed/Ansi format. A format change must
  fail qualification, not silently fall back to summary-only counts; richer Nova NUnit output remains a
  recommended future Nova improvement.
- Release-mandatory live/private-feed policy and non-macOS local-provider progression are not qualified by
  accepting the documented Phase 1 skips.
- Resolve the remaining manual SIG declaration/interface targets before a normal quality-ready handoff;
  the passing measured safeguard does not replace that separate check.
- Phase 2 (release workflow, qualification gates), Phase 3 (Gerber) and Phase 4 (extended scenarios) are not started.

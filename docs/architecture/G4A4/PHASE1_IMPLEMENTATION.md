# G-4A4 Phase 1 - GitHub Actions platform matrix (implemented locally)

## TL;DR

**Status: implemented and validated locally on macOS ARM64 / PowerShell 7.4.21 only. Nothing has run on GitHub.**
No Windows, Linux or hosted-macOS result exists yet and none is claimed. Phase 1 adds
`.github/workflows/ci.yml` (reusable, six lanes, `ci-gate`) and helper scripts under
`scripts/build/ci/`. It reuses the existing Nova flow (`Invoke-NovaBuild`, `Invoke-NovaTest`,
`Test-NovaBuild`) and does not change Nova, release, publishing or credentials.

| Label | Meaning here |
| --- | --- |
| IMPLEMENTED | Present in the repository and covered by local tests |
| LOCALLY VERIFIED | Executed on the local macOS ARM64 host |
| NOT VERIFIED | Needs a real GitHub run |

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

No `*-latest` labels are used (enforced by a test). Runner label availability and `macos-15` being ARM64 are
NOT VERIFIED until the first GitHub run.

## PowerShell provisioning

`Install-CiPowerShell.ps1` downloads the official release archive, verifies SHA-256, extracts it into a
job-owned directory, runs the extracted `pwsh` to confirm its version and prepends it to `GITHUB_PATH`, so later
steps and Nova's child `pwsh` processes use it. Channel `7.4` is pinned in `PowerShellVersions.json` with a
checksum per runtime (values taken from the official `hashes.sha256`). Channel `stable` resolves the tag from
the official `tools/metadata.json` and takes the checksum from the same release's `hashes.sha256`; that is an
integrity check, not independent provenance. Updating the 7.4 pin is a reviewed change.

## Environment verification

Before running tests, `Invoke-PlatformLane.ps1` checks OS, OS and process architecture, PowerShell version
(exactly the provisioned one, and inside the requested channel), edition `Core`, `RUNNER_OS`, `RUNNER_ARCH` and,
on GitHub, `RUNNER_ENVIRONMENT=github-hosted`. Any mismatch skips the tests and fails the lane. The manifest and
step summary record all values.

## Test entry points

Each phase runs in a fresh `pwsh -NoProfile` child: `Invoke-NovaBuild`, `Invoke-NovaTest` (unit) and
`Test-NovaBuild` (integration). No alternative runner exists and no assertion was changed. The
`PMU_QUALIFICATION_LIVE` opt-in is unset so live repository checks stay skipped, and the child processes use a
disposable temp directory that is removed afterwards. Install scope is `CurrentUser`; there are no AllUsers tests.
Modules installed by `Install-CiPowerShellModules.ps1`: Pester 5.7.1, PSResourceGet 1.2.0 (required by the local
provider fixtures), NovaModuleTools and PSScriptAnalyzer (latest stable).

Skipped tests: Nova's NUnit result is a summary without per-test entries, so skipped tests are counted and the
step summary points to the `[!]` lines in the phase logs and the test source for the reason. They are not
hidden, and they do not count as passed.

## CI gate

`ci-gate` needs `plan`, `quality` and `platform` and runs with `always()`. `Assert-CiGate.ps1` fails when any
required job result is not `success` (failed, cancelled, skipped, missing), and when any lane id from
`CiLanes.json` lacks exactly one downloaded `lane-manifest.json` with `status` `passed` for the current commit,
or when an unexpected lane manifest exists. A release workflow can depend on this one job. Marking the check
name `ci-gate` as required in branch protection is NOT VERIFIED until GitHub shows it.

## Artifacts

One artifact per lane named `pmu-ci-lane-<lane-id>`, uploaded with `always()` and 14-day retention, containing
`lane-manifest.json`, `unit-nunit.xml`, `integration-nunit.xml`, `PSVersionTable.txt` and `logs/*.log`.
Manifests include the environment, phases, counts, module versions and provisioning details. No credentials or
environment dumps are written. A step summary lists each lane result.

## Security

Top-level `permissions: contents: read`; no secrets; no `pull_request_target`; no publishing; every action is
pinned to a full commit SHA with checkout credentials not persisted; PowerShell downloads are hash-verified.
`tests/repository/CiWorkflow.Tests.ps1` enforces these.

## Local validation (macOS ARM64, PowerShell 7.4.21)

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

## Remaining qualification gaps

- First GitHub run of all six lanes; expect and triage failures from tests written on macOS only.
- Provisioning on hosted runners (extract, `GITHUB_PATH`, Nova child `pwsh`) and `Install-Module` under the
  provisioned pwsh on Windows.
- Confirm `ci-gate` as a required status check and `macos-15` arm64.
- Phase 2 (release workflow, qualification gates), Phase 3 (Gerber) and Phase 4 (extended scenarios) are not started.

# Test classification and execution policy

## TL;DR

Four tiers. Tiers 1 and 2 are mandatory for pull requests, `develop` and `main`.
Tier 3 (extended) is scheduled, and the release-required subset also runs as part
of release validation. Tier 4 (external, credentialed) is protected, manual and
never a silent pass. A skipped mandatory lane counts as failed.

## Existing test portability (static review, nothing executed on Windows/Linux)

Existing results are macOS only (G-4A3). The table is from reading source, not
from running other platforms; actual ground truth comes from the Phase 1 run.

| Area | Evidence | Expectation |
| --- | --- | --- |
| Unit tests under `tests/private`, `tests/public` using mocks | No platform tools or paths | Likely portable; NOT VERIFIED |
| `Resolve-ModuleInstallationRoot` | Branches for Windows, Linux/macOS; AllUsers Unix path `/usr/local/share/powershell/Modules` | Implemented per OS; tests assert the Unix path when not Windows |
| `Resolve-PMUDataRoot` | Windows `ProgramData`/`LocalAppData`; macOS `/Library/Application Support/PSModuleUpdate`; Linux `/var/lib/PSModuleUpdate` (AllUsers needs root) | Implemented per OS |
| `tests/integration/LocalProvider.Integration.Tests.ps1` | `-Skip:(-not $IsMacOS)` | Skipped on Windows/Linux today; must become OS-aware (Phase 2) |
| `scripts/qualification/QualificationRepository.ps1` | Throws unless macOS | macOS-only harness (Phase 2 portability work) |
| `tests/repository/QualificationProcess.Tests.ps1` | macOS-only case plus `/bin/pwd -P` usage in `QualificationProcess.ps1` | Unix-only helper; Windows variant needed |
| `Get-WindowsDirectoryDescriptor.Tests.ps1` | Windows-only ACL test | Skipped on macOS (the one G-4A3 skip); will run on Windows lanes |
| `Read-RepositoryReceipt.Tests.ps1` (symlink), `Invoke-UpdateInstallation.Tests.ps1` (permission denial) | Skipped on Windows; permission test also skipped as root | Windows contrasts needed; root-skip matters for sudo-run lanes |
| `RepositoryLive` tests | Opt-in `PMU_QUALIFICATION_LIVE=1` | Never in mandatory lanes (tier 4) |
| Process fixtures in `tests/integration/` | Run in the unit flow (`Invoke-NovaTest`) per G-4A3 | Use real child processes; portability NOT VERIFIED |

Pester tags already present: `PMU`, `PMUActualActive`, `PMUBackupReference`,
`PMURepositoryContracts`, `PMUUriBridge`, `PMULocalProvider`, `Integration`,
`RepositoryQualification`, `RepositoryLive`. Nova supports `-TagFilter` and
`-ExcludeTagFilter`, which is the intended selection mechanism (no new framework).

## Tiers

| Field | Tier 1 Standard | Tier 2 Cross-platform integration | Tier 3 Extended qualification | Tier 4 External integration |
| --- | --- | --- | --- | --- |
| Examples | ScriptAnalyzer, text formatting, `Invoke-NovaBuild`, `Invoke-NovaTest`, manifest/import/help checks, `Test-NovaBuild` | Real PSResourceGet against a disposable local feed, CurrentUser install, discovery/PSModulePath precedence, version progression, repository registration and cleanup, process coordination | Privileged AllUsers install/replace and cross-scope, hard-kill recovery, multi-process concurrency, Windows loaded-file locks, ACL/permission denial, package install of the Nova artifact | PSGallery live, NuGet.org, private Azure Artifacts, Nexus, authenticated repositories |
| Trigger | PR, push to `develop` and feature branches, `main` release validation | Same | `schedule` (nightly), `workflow_dispatch`, release validation for the release-required subset | `workflow_dispatch` and optional weekly `schedule`, protected environment only |
| Permissions | `contents: read` | `contents: read` | `contents: read`; job-local `sudo`/admin on the disposable runner | `contents: read` plus environment secrets |
| Credentials | None | None (synthetic only) | None | Scoped environment secrets, never on fork PRs |
| Expected time (planning, per lane) | S–M | M | M–L | L |
| Required status | Required (PR, develop, main, release) | Required on PR where stable; initially required on `develop`/`main` | Release-required subset required; remainder advisory but visible | Optional; required only for an explicit support claim |
| Failure behavior | Fail lane and aggregate gate | Same | Release subset blocks publication; scheduled failures open attention but do not block unrelated PRs | Never silent pass: unavailable endpoint = `blocked/not tested` |
| Artifacts | NUnit XML, lane manifest | NUnit XML, lane manifest, sanitized logs | NUnit XML, manifests, sanitized recovery/journal evidence | Sanitized report only |
| Retention (proposed) | 14 days | 14 days | 30 days; release evidence attached to the GitHub Release | 30 days |

GitHub artifact retention is limited to 90 days; the earlier proposal of 180 days
for qualification evidence cannot be met by artifacts alone. Attach the release
qualification report to the GitHub Release instead (D-4A4-11).

## Scenario mapping to brief §6

| Scenario group | Tier | Runner-feasible | Notes |
| --- | --- | --- | --- |
| 6.1 CurrentUser, explicit scope, scope preservation | 2 | Yes | All OS |
| 6.1 AllUsers positive | 3 | Probably (admin/sudo); NOT VERIFIED | See the privileged section below |
| 6.1 Permission-denied, no silent elevation/fallback | 2 (Unix as normal user), 3 (Windows) | Unix yes; Windows needs a non-admin identity; NOT VERIFIED | Windows runner user is expected to be an administrator |
| 6.2 Module resolution, loaded vs installed, RestartRequired | 2 | Yes | `ActiveVersion`, `InstalledVersion`, `TargetVersion` via real `pwsh` children |
| 6.3 Version progression, GUID continuity | 2 | Yes | Local feed with synthetic modules; no PSGallery publication |
| 6.4 Registered/unregistered/temporary repositories, redaction | 2 (local feed); 4 (live) | Local yes; live protected | PSResourceGet store location is outside `HOME`; serialize per job and snapshot the registry store (existing contract) |
| 6.5 Staging, journals, rollback, hard-kill recovery, concurrency | 3 (2 for smoke) | Yes | Process kill only; see the table below |
| 6.6 Package/manifest/help/PSResourceGet install of the Nova artifact | 2 | Yes | Build artifact once per lane or consume the Linux-built package; install from a local repository only |

## Fault classes (brief §6.5)

| Class | Testable on hosted runner | Statement allowed |
| --- | --- | --- |
| A Process termination | Yes (`Stop-Process -Force` / `kill -9` of a child) | Recovery after process death |
| B PowerShell session restart | Yes (new `pwsh`) | Recovery in a fresh process |
| C GitHub job termination | Not deterministically; cancellation sends a signal and the runner is destroyed | Not tested; no claim |
| D OS reboot | NOT SUPPORTED on ephemeral hosted runners (the job cannot survive a reboot) | Not tested; no claim |
| E Power loss | NOT SUPPORTED | No claim. Process-kill tests do not prove power-loss safety |

Runner VMs are not made for D/E. If D becomes a support claim, the fallback is a
local disposable VM (cost category: none ongoing; operator time) per the earlier
strategy; nothing here requires it.

## Privileged tests (AllUsers) on hosted runners

PROPOSED, all NOT VERIFIED until a capability preflight job runs:

1. Preflight records `id`, `sudo -n true` result (Unix) or the
   Windows token elevation state, and the writability of the AllUsers roots.
2. Positive AllUsers tests use unique disposable module names and clean up in
   `finally`; they never touch module names a developer would install.
3. Unix negative tests run the unprivileged `runner` user against the AllUsers
   path; the macOS ARM64 `/usr/local` ownership and Linux writability are unknown.
4. Windows negative tests need a standard-user identity; creating a local
   standard user inside the job is feasible in principle but unproven. If it
   fails, mark Windows permission-denied as a named, non-passed gap and
   keep the Pester-level mock/ACL tests.

## Report contents

Each lane emits a JSON manifest (OS, image version, architecture, resolved
PowerShell, PSResourceGet, Pester and Nova versions, commit SHA, package hash,
privilege identity, counts of passed/failed/skipped/blocked, cleanup and
redaction verdicts). Skips in a mandatory category fail completeness unless the
skip is on a declared allow-list (for example the macOS-only or Windows-only
tests, listed by name).

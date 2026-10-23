# Cross-platform runner feasibility report

## TL;DR

All six lanes are available as **standard GitHub-hosted runners** with the
architectures the brief requires; none needs a VM or self-hosted runner. Free and
unlimited for public repositories. Neither 7.4 nor the latest stable PowerShell is
reliably preinstalled, so both must be provisioned by the job.

## Runner availability (fetched 2026-10-23, GitHub docs table for public repositories)

| Lane OS | Proposed pinned label | Architecture per docs | Image PowerShell (runner-images readme) | Status |
| --- | --- | --- | --- | --- |
| Windows x64 | `windows-2025` (`windows-latest` currently resolves to the same image) | x64 | 7.6.7 | PROPOSED; available |
| Linux x64 | `ubuntu-24.04` | x64 | 7.6.6 | PROPOSED; available |
| macOS ARM64 | `macos-15` (arm64 label; `macos-26` and `macos-latest` also arm64 today) | arm64 (3-core M1, 7 GB) | 7.6.5 (`macos-15`); 7.6.6 (`macos-26`) | PROPOSED; available |

Notes:

- `macos-15-intel` and `macos-26-intel` are x64 and must **not** be used for the
  ARM64 lane. Do not rely on `macos-latest` meaning ARM64 in future; pin the
  label and assert `uname -m` / `[RuntimeInformation]::OSArchitecture` and
  `ProcessArchitecture` in the job (PROPOSED preflight).
- Other available native rows for later extension: `ubuntu-24.04-arm`,
  `windows-11-arm`, `macos-15-intel`.
- The latest stable PowerShell on 2026-10-23 per the official release feed is
  **7.6.8** (published 2026-10-22); the newest 7.4 patch is **7.4.21**. Runner
  images lag (7.6.5–7.6.7), so "latest" must be resolved at job start, not taken
  from the image. Preview releases (7.7.0-preview.5) are advisory only.
- Pester on the images is 5.9.0 (inside Nova's supported 5.7.1–5.10.0 range);
  PMU still pins via `Install-CiPowerShellModules.ps1`-style installation.

## PowerShell provisioning

| Requirement | Finding |
| --- | --- |
| Install 7.4 | PROPOSED: download the official release asset (`.zip` Windows, `.tar.gz` Linux/macOS arm64/x64) for the resolved patch and verify it against the release's published hash before extracting into a job-owned directory. The official `install-powershell.ps1` supports `-Version` and `-Destination` on all three OS families and can serve as a fallback; its exact cross-OS behavior on hosted runners is NOT VERIFIED until the Phase 1 spike |
| Install latest stable | Same mechanism; resolve the newest non-preview release at job start and record it in the lane manifest |
| Side-by-side | Supported by extraction into a separate directory and invoking that executable by full path; the preinstalled `pwsh` remains. Confirmed by design, NOT VERIFIED on a runner |
| Reproducible pinning | Pin concrete patch + asset hash for the 7.4 lane (reviewed bump). The "latest" lane is deliberately floating, with the resolved version recorded; reruns can pass the recorded version |
| Select the runtime for Nova | Nova has no runtime flag. The lane script launches the selected `pwsh` executable explicitly, for example `& $pwsh -NoProfile -File scripts/ci/Invoke-PlatformLane.ps1`; step `shell:` stays `bash` (or a custom `shell:` template) so the runner's default `pwsh` is not used by accident |
| PSResourceGet | NOT VERIFIED on images; install/pin via the same bootstrap. G-4A3 baseline is 1.2.0 |

## Constraints and risks

| Topic | Finding |
| --- | --- |
| Cost, public repo | Standard runners free and unlimited; includes macOS ARM64 |
| Cost, private repo | Allotment-based then metered; macOS is the most expensive per minute (check [pricing](https://docs.github.com/en/billing/reference/actions-runner-pricing)). PMU has no remote; Gerber returned 404 unauthenticated. Visibility decides the cost |
| Concurrency limits | Not fetched; verify per plan before enabling hourly or large matrices |
| Image drift | Runner images roll weekly; pinned labels still receive image updates. Record image version (`ImageVersion` environment variable) in each lane manifest |
| 7.4 lifecycle | 7.4 is near the end of Microsoft support (see strategy document); a lifecycle decision is required (D-4A4-04) |
| macOS temp paths | The macOS runner temp path is canonicalized differently; PMU already has a test for the temporary-base canonicalization |
| Hardware | 4-core/16 GB for public Linux/Windows; 3-core M1/7 GB for macOS: enough for current tests (G-4A3 runs completed locally) |

## Verdict per lane

| Lane | Available | Native arch | Needs extra provisioning | Verdict |
| --- | --- | --- | --- | --- |
| Windows x64 / 7.4 | Yes | x64 | PowerShell 7.4 | Feasible |
| Windows x64 / latest | Yes | x64 | PowerShell 7.6.8 | Feasible |
| Linux x64 / 7.4 | Yes | x64 | PowerShell 7.4 | Feasible |
| Linux x64 / latest | Yes | x64 | PowerShell 7.6.8 | Feasible |
| macOS ARM64 / 7.4 | Yes | arm64 | PowerShell 7.4 (arm64 asset) | Feasible; arm64 asset existence NOT VERIFIED |
| macOS ARM64 / latest | Yes | arm64 | PowerShell 7.6.8 | Feasible |

No lane requires a fallback. If a future change moves the repositories to private
hosting, macOS minutes become the cost driver; the fallback is to run macOS lanes
on `develop`/`main`/scheduled only and keep Windows/Linux on every pull request.

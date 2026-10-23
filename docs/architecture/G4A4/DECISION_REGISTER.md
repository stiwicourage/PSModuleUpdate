# Decision register

## TL;DR

Fifteen decisions need owner approval before implementation. All are
PROPOSED. Recommendations are given; none is applied.

| ID | Decision | Recommendation | Status |
| --- | --- | --- | --- |
| D-4A4-01 | PMU and Gerber hosting and visibility (PMU has no remote; Gerber is not publicly visible) | Decide first; it sets cost and reusable-workflow options | Open |
| D-4A4-02 | Runner label pins and bump policy (`macos-15` vs `macos-26`) | Pin labels, assert architecture at runtime, review bumps | Open |
| D-4A4-03 | Latest-PowerShell policy | Floating latest with the resolved version recorded; 7.4 pinned by patch and hash | Open |
| D-4A4-04 | PowerShell 7.4 end-of-support policy | Verify the vendor date, then decide whether to keep the lane | Open |
| D-4A4-05 | Branch protection and the required `ci-gate` check (manual admin setting) | Require `ci-gate` on `develop` and `main` | Open |
| D-4A4-06 | Gate design: `workflow_call` inside `release.yml` vs a separate workflow | `workflow_call` | Open |
| D-4A4-07 | Validated artifact level A vs B | A first | Open |
| D-4A4-08 | Whether `develop` publishes previews | No | Open |
| D-4A4-09 | `release` environment with reviewers (plan dependent) | Yes if available | Open |
| D-4A4-10 | When to extract reusable workflows | After Gerber adopts the pattern | Open |
| D-4A4-11 | Evidence retention (artifacts are capped at 90 days) | Attach release reports to the GitHub Release | Open |
| D-4A4-12 | Windows negative-permission strategy | Spike a local standard user; otherwise name the gap | Open |
| D-4A4-13 | Native credential-store spikes for Gerber | Disposable keychain, `dbus-run-session`, Credential Manager | Open |
| D-4A4-14 | Cron cadence | Nightly rather than Nova's hourly | Open |
| D-4A4-15 | Third-party action pinning | Pin by SHA | Open |

## Open uncertainties (NOT VERIFIED)

- Branch protection and required checks on any repository (the API returned 401).
- Passwordless sudo and Windows administrator rights on hosted runners.
- Writability of `/usr/local/share/powershell/Modules` on the macOS ARM64 runner.
- Native credential stores in runner sessions.
- Concurrency limits per plan, and environment reviewers on private repositories.
- Whether `GITHUB_TOKEN` can update a protected `main`.
- Whether splitting Nova's release into public commands is equivalent to `Invoke-NovaRelease`.
- Behavior of the existing tests on Windows and Linux (never executed).

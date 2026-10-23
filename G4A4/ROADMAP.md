# Phased roadmap

## TL;DR

Four phases. Phase 1 proves the six-lane matrix with the existing tests. Phase 2
adds PMU qualification and release gating. Phase 3 adopts the pattern in Gerber.
Phase 4 covers extended and privileged scenarios. All phases are PROPOSED and
need owner approval before implementation. Hosted runners are free for public
repositories; private hosting changes the cost (see [RUNNER_FEASIBILITY.md](RUNNER_FEASIBILITY.md)).

## Phase 1: Platform matrix

| Item | Content |
| --- | --- |
| Deliverables | `ci.yml` with quality job, six-lane platform matrix and `ci-gate`; lane script; PowerShell provisioning with hash check; lane manifest; NUnit artifacts |
| Dependencies | PMU remote and visibility (D-4A4-01); runner pins (D-4A4-02) |
| Acceptance | Six lanes run the existing Nova flow; actual OS/arch/PowerShell asserted; skipped mandatory lane fails the gate; first real Windows/Linux results recorded, with failures triaged rather than hidden |
| Risks | Unknown Windows/Linux failures in macOS-written tests; `pwsh` 7.4 provisioning behavior |
| Approvals | A-01, D-4A4-01..04 |
| Cost | Free for public; macOS-heavy if private |

## Phase 2: PMU qualification and release gating

| Item | Content |
| --- | --- |
| Deliverables | OS-aware integration tests; CurrentUser, repository, locking and recovery scenarios; `release.yml` with `validate`, environment, concurrency, stale-tip check, artifact allow-list; local-feed install of the Nova package |
| Dependencies | Phase 1; branch protection (D-4A4-05); gate design (D-4A4-06) |
| Acceptance | A failing lane blocks publication in a dry run; a stale tip aborts; no secret is visible outside the `release` job |
| Risks | Nova split-release behavior NOT VERIFIED; generated release commit vs branch protection |
| Approvals | D-4A4-05..09 |
| Cost | Free for public |

## Phase 3: Gerber adoption

| Item | Content |
| --- | --- |
| Deliverables | Gerber `ci.yml` from the PMU pattern; native credential-store spikes per OS; Windows terminal strategy |
| Dependencies | Phase 1; Gerber hosting (D-4A4-01); extraction decision (D-4A4-10) |
| Acceptance | Gerber unit tests run on the six lanes; credential stores either verified or named as gaps |
| Risks | Keychain/Credential Manager/Secret Service behavior on runners; PTY harness is Unix-only |
| Approvals | D-4A4-10, D-4A4-13 |
| Cost | Free if public |

## Phase 4: Extended and privileged qualification

| Item | Content |
| --- | --- |
| Deliverables | `qualification.yml` nightly; AllUsers positive and negative; hard-kill recovery; concurrency; protected external-integration workflow |
| Dependencies | Phases 1–2; privilege preflight results |
| Acceptance | Each scenario is reported as passed, failed or blocked, never silently skipped; release evidence attached to the GitHub Release |
| Risks | Windows non-admin identity; OS reboot and power loss are NOT SUPPORTED |
| Approvals | D-4A4-09, D-4A4-11, D-4A4-12 |
| Cost | Nightly macOS minutes if private |

Implementation does not start until these are approved. No phase changes Nova.

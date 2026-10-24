# Phased roadmap

## TL;DR

Four phases. Phase 1 proves the six-lane matrix with the existing tests. Phase 2
adds PMU qualification and release gating. Phase 3 adopts the pattern in Gerber.
Phase 4 covers extended and privileged scenarios. Phase 1 implementation and
local hardening are authorized; Phases 2-4 remain PROPOSED and
need owner approval before implementation. Hosted runners are free for public
repositories; private hosting changes the cost (see [RUNNER_FEASIBILITY.md](RUNNER_FEASIBILITY.md)).

## Phase 1: Platform matrix

**Status: IMPLEMENTED; first GitHub run has two passing macOS lanes and four failing Windows/Linux lanes**
([record](PHASE1_IMPLEMENTATION.md#first-hosted-run-and-platform-fixes-2026-10-23)). Hosted provisioning
succeeded on all six lanes; complete platform-test acceptance remains open.

Local hardening includes documented runner verification: GitHub explicitly
maps `macos-15` to ARM64 standard hosted runners for public repositories, so
the approved label is retained. The implementation record inventories all
four historical macOS skips and the additional platform-conditional skips.
Documented runner support does not satisfy the six executed-lane acceptance
criterion; all six lanes must pass after the recorded platform fixes.

Hardening is locally verified with disposable dependencies and explicit executable/runtime witnesses on
macOS ARM64, PowerShell 7.4.21 and stable 7.6.8: each lane passed 413 unit tests and six integration tests
with the same four documented skips. The isolated repository quality wrapper, 135 BuildTooling tests,
analyzer, formatting and actionlint passed. Before/after module and repository-store fingerprints were
unchanged. The hardened gate requires current-run complete qualification evidence, not merely a successful
aggregate matrix job. These historical local results do not close the remaining Windows/Linux acceptance
items. Run 39949417203 confirmed both Mac lanes and rejected the incomplete matrix at `ci-gate`; a new run
is required to qualify the fixes.

The platform fixes subsequently passed the local macOS 7.4.21 quality wrapper (416 unit and six integration
passes) and a complete emulated Linux x64 / Ubuntu 22.04 / 7.4.21 lane (414 unit and five integration passes),
with only the existing platform/opt-in skips. These are not a Windows result or a hosted Ubuntu 24.04 rerun;
the [implementation record](PHASE1_IMPLEMENTATION.md#post-fix-local-validation) retains the exact scope.

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

Phases 2-4 do not start until separately approved. No phase changes Nova.

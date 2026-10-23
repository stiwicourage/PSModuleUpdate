# Cross-platform testing implementation roadmap

## TL;DR

G-4A3 development is closed. Approve the proposed architecture and minimum
matrix before implementing anything. Deliver a six-lane native baseline first,
then PMU qualification, Gerber native-credential/terminal qualification, and
extended privileged/recovery/release capabilities. No phase below has been
implemented by this documentation task.

Use the [strategy](CROSS_PLATFORM_TESTING.md),
[technology comparison](TEST_TECHNOLOGY_COMPARISON.md), and
[matrix](TEST_MATRIX.md) as the design package. Plan unit/behavior changes
test-first and preserve existing characterization assertions; infrastructure
approval does not authorize unrelated product refactoring or new support claims.

## Phase 1 - Minimum viable cross-platform execution

**Scope:** establish disposable native Windows x64, Linux x64, macOS ARM64
execution with independently pinned PowerShell 7.4 and latest stable; secret-free
PMU and Gerber Core baseline; optional local Linux container feedback.

**Likely affected files, subject to separate authorization:** per-project
`TESTING.md`/contribution guidance and `project.json` only where actual test
selection metadata is needed; new thin `.github/workflows/` callers or an
`azure-pipelines.yml` (choose one, neither exists as a task deliverable);
project-local `scripts/build/` environment adapter/report helpers and focused
tests. Shared-repository files are created only after ownership approval.
Do not change Nova Init or add infrastructure into NovaModuleTools by default.

**Deliverables:**

- Declared execution contract: OS/runtime/architecture/identity/capabilities,
  selected categories, fail-closed mutation checks, report/exit semantics.
- Version/checksum-verified runtime provisioning and pinned compatible
  Nova/Pester/analyzer selection without relying on runner preinstalls.
- Independent six-lane project reports and artifact retention; publish Nova
  NUnit results without losing failure status.
- Local safe macOS instructions and optional ARM64 Linux container recipe.
  Neither pretends to provide local Windows x64.
- Gerber Windows terminal-stage limitation explicitly reported, not hidden by
  a bypass or a false full-wrapper success.

**Dependencies:** approvals A-01 through A-05 and A-09 below; actual repository
hosting/CI entitlement, runtime assets for selected OS images, project tool
availability, and test categorization that can safely exclude protected effects
without weakening existing gates.

**Acceptance criteria:**

1. All six OS/runtime lanes per project execute the selected Nova baseline;
   exact versions/architecture are asserted, not inferred from labels.
2. A deliberately failing behavioral test produces a failing job and readable
   result; skipped required scenarios cannot make qualification pass.
3. Isolation preflight rejects a real user module path/registry; injected
   cleanup/redaction/timeout failures are visible.
4. Untrusted PR execution receives no protected secrets or durable privileged
   runner; safe local selection does not touch native developer vaults/stores.
5. Existing applicable assertions/coverage thresholds are preserved. Missing
   full Windows terminal validation remains an explicit separate Gerber gap.

**Risks:** 7.4 lifecycle/image compatibility, ARM64 tooling, CI budget, hidden
platform assumptions in fixtures, and expensive abstraction before reuse is
proven. Keep shared implementation minimal; validate it with both projects.

## Phase 2 - PSModuleUpdate native platform qualification

**Scope:** port/reuse provider and process fixtures on all three OSes, actually
execute 7.4, CurrentUser discovery/precedence, stable/prerelease/same-base
replacement, GUID/tree verification, source-bound auth/URI transport,
rollback/journal/concurrency/restart behavior.

**Likely affected files after authorization:**
`tests/integration/LocalProvider.Integration.Tests.ps1`,
`ProcessRecovery.Tests.ps1`, `ActiveState.Tests.ps1`,
`RepositoryBinding.Tests.ps1`, `UriBridge.Tests.ps1`,
`tests/repository/`, relevant `tests/TestHelpers/`,
`scripts/qualification/`, platform adapter tests under `tests/private/`,
and qualification documentation. Inspect each before changing it; preserve
existing assertion strength. Product fixes discovered by qualification are
separately scoped red/green changes, not assumed infrastructure work.

**Deliverables:** safe native-provider fixture lifecycle on each OS; isolated
actual registry/profile validation; native Windows file/assembly-lock fixture;
baseline-versus-candidate provider reports; durable artifact-bound report
replacing no historical evidence.

**Dependencies:** Phase 1; approval of actual PSResourceGet 1.2.0 provisioning,
disposable profiles and network fixture access. AllUsers/live private
prerelease/Nexus remain separate unless explicitly approved here.

**Acceptance criteria:**

1. Real native-provider CurrentUser stable and same-base preview-to-stable
   installation passes on each OS at both runtime selections.
2. Other scope/module trees and unrelated registrations remain unchanged;
   provider/native directories are measured, not simulated by PSModulePath.
3. Real-process contention/death and next-process journal recovery pass with
   preserved trees, bounded execution and explicit cleanup results.
4. Windows loaded-file behavior and ActiveVersion/InstalledVersion/
   RestartRequired outcomes are observed, not inferred from Unix.
5. Reports distinguish local-feed/provider fixtures, actual live services,
   missing packages, skips and new qualification; G-4A3 history is untouched.

**Risks:** currently macOS-only native provider harness; Windows Documents/
profile resolution; permission and path differences; provider metadata changes;
real network availability. Container passes cannot close native OS gaps.

## Phase 3 - Gerber Core credential and platform qualification

**Scope:** native store identification/round trips, Linux Secret Service and
headless failure, user config/permissions, module dependency conflicts,
external-process/encoding behavior, Unix PTY and Windows terminal capability.

**Likely affected Gerber files require separate permission:** existing
`tests/public/CredentialService.Integration.Tests.ps1`,
`tests/private/credentials/`, `tests/private/config/`,
`tests/private/ado/Approve-GerberAdoPipelineApproval.Tests.ps1`,
`scripts/build/Invoke-TerminalRegressionCI.ps1`, and `tests/terminal/`.
They are read-only during this investigation. Infrastructure ownership must
not move Core/plugin-specific assertions into PMU.

**Deliverables:** three distinct native-vault environment recipes and backend/
session assertions; unique test identifier cleanup; Windows terminal adapter;
safe synthetic-secret terminal suite; credential-free qualification reports.
Approved live Core PAT integration is separate from plugin-owned OAuth.

**Dependencies:** Phase 1; Phase 2's generic worker safety can be reused but
PMU behavior completion is not a technical prerequisite. Approvals A-06/A-08
and OS-specific identity/session capacity are required.

**Acceptance criteria:**

1. Core's credential object, transient plaintext, native persistence and
   external auth boundaries are asserted separately.
2. Linux unavailable/locked service yields actionable failure and no plaintext
   fallback; environment restoration is proven on success and failure.
3. macOS/Windows actual backend, account scope and session prerequisites are
   recorded; CRUD survives a fresh process where expected and owned entries
   are removed. No developer login vault is used.
4. Native config path, UTF-8, denied permissions and assembly/module loading
   cases pass on both runtime lanes with existing coverage targets intact.
5. Real Unix PTY and approved Windows interactive tests prove secure input,
   cancellation and noninteractive behavior; only then claim a complete
   Windows quality-loop result.

**Risks:** vault prompts, session/keychain access, Windows backend ambiguity,
Linux D-Bus/service lifecycle, Core/plugin boundary confusion, and Windows
pexpect incompatibility. If automation cannot exercise a desktop prompt,
record a manual qualification protocol, not a fabricated automated pass.

## Phase 4 - Privileged, persistent recovery and release qualification

**Scope:** real AllUsers installation/replacement and denied non-admin cases,
permission transitions, real-provider interruption, persistent VM restart,
authorized private Azure preview sequence/dependencies, Nexus, additional
architectures/providers and release-candidate qualification.

**Likely affected files after authorization:** project-owned qualification
scripts/tests/reports, protected CI callers and shared worker adapters; new
VM provisioning/snapshot definitions only for approved VM-dependent cases.
Product changes remain separately scoped. No release/publish/tag operation is
part of testing approval.

**Deliverables:** disposable privileged account/worker recipes; bounded
cross-process/reboot controller; protected secret/network lanes; immutable
release artifact identity/OS/runtime/provider report; expanded support matrix
and explicit unavailable rows.

**Dependencies:** relevant Phase 2/3 categories; A-03/A-06 through A-10;
authorized external fixtures, native OS licensing, VM/session capabilities and
budget. PMU AllUsers/recovery can proceed independently of Gerber vault
qualification; Gerber release claims still require their own Phase 3 evidence.

**Acceptance criteria:**

1. AllUsers success and same-base replacement occur in genuine system roots
   on approved disposable OSes; nonprivileged denial/no fallback is proven
   separately from elevated success.
2. Test-owned VM restart preserves the exact journal/backup/disk under test;
   recovery or explicit safe failure is observed in a new process/session.
3. Private preview and Nexus claims are backed by actual authorized fixtures,
   not synthetic local feed results or discovery-only calls.
4. Architecture/provider extensions get independent native evidence; emulated
   x64 on ARM is never reported as native x64.
5. Release reports identify the exact candidate and required rows, distinguish
   passed/failed/unverified/risk accepted, preserve sanitization/cleanup and
   obtain owner acceptance of named residual gaps before support claims.

**Risks:** privilege containment, licensing, secret leakage, VM/snapshot costs,
external feeds/network, unstable fault timing and overstated durability.
Require synchronization markers rather than arbitrary sleeps, and bounded
recovery attempts. Do not claim atomicity or guaranteed power-loss recovery.

## Decisions requiring owner approval

These are proposals, not decisions already made:

| ID | Proposed decision | Approval/input needed |
| --- | --- | --- |
| A-01 | GitHub Actions first; Azure Pipelines alternative | Confirm repository hosts, organization governance, runner permissions and existing subscriptions; do not operate both without need |
| A-02 | Shared contract, project-owned tests; extract small shared repository after two-project reuse | Name infrastructure maintainer, review ownership, release/version compatibility policy; Nova is not default owner |
| A-03 | Native Windows/Linux x64 + macOS ARM64; extra architectures scheduled before support claims | Confirm actual consumer CPU/OS requirements and available runners; Apple Silicon Windows is a distinct ARM claim |
| A-04 | PowerShell 7.4 plus newest stable release on every PR | Confirm post-7.4-support policy and optional intermediate/preview schedule; no silent minimum-version change |
| A-05 | Native hosted MVP; optional Podman/Docker Linux local lane | Choose container runtime after license/IT review, job concurrency, cost ceiling and phase time budget |
| A-06 | Privileged/vault mutation only in approved disposable identities/workers | Approve identity/session lifecycle, ACL/root capability, ownership and manual prompting boundaries |
| A-07 | Private Azure/Nexus qualification only with authorized pinned fixtures | Supply suitable prerelease/dependency sequence and approved endpoint/identity; no implicit permission to publish |
| A-08 | Windows terminal adapter; native vault jobs protected, plugin OAuth separate | Approve ConPTY/interactive infrastructure and required versus manual qualification status |
| A-09 | Sanitized XML/manifests, 14/30-day diagnostics and durable release evidence | Approve retention/storage/permissions and budget; provider maxima may require separate durable storage |
| A-10 | Add VM/snapshot adapter only for named reboot/desktop/privilege scenarios | Select provider/guest architecture/box licensing after capability proof; explicitly fund licenses and persistent workers |

G-4A3 quality acceptance is already decided in D-022, not another approval
request. This register does not propose refactoring for a score.

## Open questions / resume here

1. Which accounts actually host PSModuleUpdate and Gerber and can provide the
   required macOS ARM64 native jobs? Neither checkout defines a live CI matrix.
2. Must Windows ARM64, Linux ARM64 and Intel macOS be consumer support promises
   or advisory compatibility rows?
3. How long must 7.4 compatibility persist after its vendor support ends, and
   what network isolation/patch policy applies then?
4. Which Windows native credential backend is selected by Gerber's packaged
   provider, and can the chosen CI user session exercise it without prompts?
5. Which dedicated macOS keychain/user and Linux Secret Service implementation
   are approved, and who owns cleanup/recovery?
6. Is an authorized private prerelease package sequence and Nexus endpoint
   available? If not, retain explicit not-tested labels.
7. Which VM provider can demonstrate the required guest architecture, snapshot/
   restart behavior, automation/plugin compatibility and guest OS licensing on
   the actual Apple Silicon host?
8. What per-PR wall-clock/concurrency/minutes budget and release retention are
   acceptable? Estimates must be replaced by measured Phase 1 results.

After approval, authorize one phase at a time. Identify touched files and
behavioral evidence before implementation; do not begin by changing Gerber,
NovaModuleTools, Git metadata, pipelines or virtual machines from this plan alone.

# Cross-platform PowerShell testing strategy

## TL;DR

**Proposed architecture; no infrastructure implemented or new platform qualified.**
Keep behavioral tests in each project and use a small, versioned shared
execution/reporting contract. Prefer disposable native hosted Windows, Linux,
and macOS jobs for the minimum matrix, with **PowerShell 7.4 and latest stable
as distinct runtime lanes**. Use native macOS locally and optional Linux
containers for fast feedback on Apple Silicon. Add isolated full-OS VMs or
remote workers only for concrete privilege, native credential, persistent-state,
or recovery requirements.

Recommend GitHub Actions as the initial hosted option, subject to repository
hosting/access and budget approval. Azure Pipelines is a viable alternative,
not a second mandatory CI system. Neither project currently establishes an
active hosted pipeline merely by having Nova scaffold guidance.

This design initially serves PSModuleUpdate and Gerber Core and can be adopted
by future modules. The [comparison](TEST_TECHNOLOGY_COMPARISON.md) precedes the
recommendation; [matrix](TEST_MATRIX.md) and
[roadmap](TEST_IMPLEMENTATION_ROADMAP.md) define execution and approval gates.

## Scope and evidence boundary

Investigation date: 2026-10-23. Source evidence is a snapshot, not proof of
cross-platform execution. [G-4A3 closure](G4A3_CLOSURE.md) records accepted
implementation separately from qualification. Do not reinterpret prior passes,
skips, or quality findings through this strategy.

PMU's `project.json` declares PowerShell 7.4 and disables coverage; `run.ps1`
uses ScriptAnalyzer, Nova build, unit tests, build-validation integration, then
formatting. `TESTING.md` documents Pester 5.7.1-5.10.0 selection and
`artifacts/UnitTestResults.xml` / `artifacts/TestResults.xml`. Reuse those
entrypoints, do not bypass them with direct Pester invocation.

PMU has no `.github/workflows/` or Azure pipeline definition in the inspected
checkout and no configured Git remote. Scaffold references to publish/coverage
workflows are not evidence that such pipelines exist. Actual CI host and
permissions must be confirmed before implementation.

This is maintainer design documentation alongside Nova-style root
`ARCHITECTURE.md`, `PLAN.md`, `DECISIONS.md`, and `TESTING.md`, not PlatyPS command
reference. Public cmdlets, `% nova` CLI behavior, generated help, production code,
tests, pipelines, provisioning, Gerber and NovaModuleTools are unchanged.

## Runtime, OS, and architecture policy

| Dimension | Minimum design | Extended design |
| --- | --- | --- |
| OS families | Native Windows, Linux, macOS execution | Additional supported distributions/OS releases and filesystems when justified |
| PowerShell | Latest supported patch in the 7.4 line and separately resolved latest stable | Supported intermediate stable line when it adds distinct engine/.NET coverage; preview scheduled and advisory |
| Processor | Windows/Linux x64 plus macOS ARM64 initially | Linux ARM64, macOS x64 and Windows ARM64 when support intent, binaries, runners and tooling justify them |
| Provider/tooling | PSResourceGet 1.2.0 behavioral baseline; project-compatible pinned Nova/Pester/analyzer | Later provider 1.x versions in isolated lanes; never infer baseline parity |

Do not use an installed runner `pwsh` or `*-latest` label as a runtime pin.
Resolve official stable releases, record the concrete version and asset checksum,
install/extract into a job-owned location, invoke that exact executable, and
assert `$PSVersionTable`, OS, process architecture and provider version before
discovery. Record exact dependency versions. Resolve latest at job start and
freeze it for that batch; reruns intended to reproduce it use the recorded
version, not a fresh latest lookup. The strategy does not prescribe a nonexistent
Nova version-selection flag.

A minimum-version lane must actually run 7.4, even if the newest engine passes.
At the investigation date, official support schedules place 7.4 near its
support boundary; verify the current lifecycle before rollout. If 7.4 leaves
support while still a project requirement, retain an explicit isolated
compatibility lane, record the unsupported-runtime exposure and obtain a
separate minimum-version policy decision. Do not silently raise the minimum or
claim an out-of-support runtime is supported by Microsoft.

Windows PowerShell 5.1 is not in the initial contract. Extra versions add
distinct coverage only when their engine/.NET/provider behavior or consumer
requirements warrant the cost. Preview success does not qualify stable.
Architecture emulation is diagnostic evidence, not native architecture
qualification; Windows ARM64 on a Mac is not Windows x64.

## Execution layers and local workflow

| Layer | Appropriate use | Explicit limitation |
| --- | --- | --- |
| Local native macOS ARM64 | Secret-free unit/contracts and nonmutating built-module checks using existing Nova entrypoints | Do not assume current provider-mutating suites are safe merely because HOME is temporary |
| Optional Linux container | Fast Linux userland, paths, encoding, dependency packaging and controlled process tests | Linux VM kernel on macOS; no macOS/Windows proof, no host bind-mounted modules/secrets |
| Disposable hosted native OS job | PR and compatibility matrix; real OS-specific discovery/filesystem/process behavior | Selected hosted image only; not a VM snapshot or power-loss test |
| Disposable local Linux VM | Closer control of users, privilege transitions, init/session services and restart persistence | Adds provisioning/resources; not needed for ordinary logic tests |
| Disposable Windows VM or remote job | ACLs, actual AllUsers roots, file locking, user profile and native Credential Manager | Apple Silicon local guests/providers/PS assets must be verified; prefer hosted x64 for initial x64 claims |
| Controlled persistent VM/session | Crash/reboot recovery or desktop vault/terminal qualification | Explicit isolation, timeout, snapshot/rebuild and credential lifecycle required |

Developers should run the existing repository workflow only after its selected
tests meet the isolation preflight. Today, provider integration on PMU is
macOS-gated and uses the actual user registration store with approved owned
registrations; the proposed stronger isolation is not available yet. Until it
is implemented, use the documented opt-ins and safety boundaries in `TESTING.md`,
or a disposable account/worker; never describe the new strategy as an existing
safe-all-platform launcher.

The future local launcher should expose project-owned selections for fast,
native-provider, privileged and qualification categories, validate prerequisites
and refuse unsafe environments. These are design categories, not new commands.
Use the same project entrypoints inside local/container/CI environments; supply
environment/runtime facts outside the behavioral suite.

No single VM/container product reasonably supplies all three native OS kernels,
both architectures, desktop vaults and hosted secret controls. A thin shared
dispatcher/report format can orchestrate adapters, but must not grow a custom
cloud scheduler. Start with hosted matrices and one optional Linux container
recipe; add a VM adapter only when an approved scenario needs it.

## Ownership and shared architecture

| Option | Ownership/coupling/versioning assessment | Decision proposed |
| --- | --- | --- |
| A: everything copied into each project | Easy start, independent changes; duplicated provisioning drifts and fixes must be repeated | Keep project tests/config, not long-term duplicated orchestration |
| B: all infrastructure in NovaModuleTools | Convenient existing build integration; couples OS/vault/cloud releases to build tooling and creates unrelated ownership | Do not select by scaffold ancestry; no Nova modifications in this task |
| C: everything in a separate testing repository | Central operations/versioning; moving domain tests out obscures product contracts and makes changes cross-repository | Share infrastructure only, not all tests |
| D: shared versioned infrastructure plus project-owned contracts | Reusable safety/runtime/reporting, independent behavioral changes; requires compatibility/version discipline | Recommended target |

Start with a small contract documented here and project-local adoption after
approval. Extract reusable code into a dedicated shared testing repository only
once both projects demonstrate a common implementation; its creation and owner
are approval items. Do not create a new mandatory runtime dependency of PMU or
Gerber. Pin releases/immutable action revisions, support a declared contract
version, test shared changes with both consumers, and allow independent upgrades.

| Concern | Shared responsibility | Project responsibility |
| --- | --- | --- |
| Infrastructure | Runtime download verification, environment facts, disposable-worker adapters, lifecycle/cleanup | Required capabilities and denylist of unsafe host resources |
| Orchestration | Standard job inputs, bounded process control, status/report schema | Nova wrapper invocation and project category selection |
| Fixtures | Generic temporary-root/account lifecycle and sanitized fixture transport | PMU module/GUID/version/feed fixtures; Gerber provider/config/terminal fixtures |
| Tests | Shared infrastructure's own contracts only | Product scenarios, assertions, expected errors/results |
| CI configuration | Optional reusable workflow/template with least-privilege contract | Thin caller, triggers, permissions, approvals, required statuses |
| Qualification | Report schema, redaction/retention rules | Artifact identity, supported claims, gaps and owner acceptance |

Do not add product tests that retest Nova, PSResourceGet, vaults or authentication
providers wholesale. Exercise this project's integration and safety contract:
which source/identity it passes, which state it preserves, how results/errors
are represented, and which native effects matter.

## Isolation and safety contract

### Trust and mutation classes

Classify each test before scheduling:

1. Pure/controlled contract: no native repositories, real secrets or system
   mutations. Suitable for untrusted PR jobs after ordinary runner controls.
2. Disposable-user mutation: real provider/config/secret effects confined to a
   verified test identity/container/worker. No developer identity mounts.
3. Privileged mutation: real AllUsers roots, ACLs, other-user checks or process
   ownership. Only in an approved disposable full-OS worker.
4. External-secret/interactive qualification: protected feed/tenant/vault
   identity or desktop session. Explicit approval and isolated environment.

Disposable does not mean harmless: tests still need bounded roots, permissions,
timeouts and cleanup. Never elevate a developer shell to exercise AllUsers.

### Preflight before any mutation

- Assert canonical test root, expected OS user/account, parent worker identity
  and declared disposable-worker capability; a path string alone is not proof.
- Record actual provider destinations and PMU data roots, native application
  data directories, Documents/ProgramFiles locations on Windows, and provider
  registry path. Fail closed if any required writable location is outside the
  authorized disposable environment.
- Set test-owned HOME/USERPROFILE/XDG/config/temp locations where applicable,
  and an explicit PSModulePath containing only fixture roots and required
  pinned runtime/tool modules. Deny inherited developer module paths. Inspect
  child environment and actual discovery, not just intended variables.
- Use unique disposable module names/GUIDs, install roots, feed names and
  ports; validate they cannot resolve a real installed module.
- Do not mount host home, credential stores, SSH/cloud config, real module
  trees or a container-engine socket. Read-only source plus writable test
  workspace is enough; root in a container must not become host authority.
- Bound children by PID/process tree and timeout, not broad name-based kills.
  Kill only test-owned processes. Use a fresh process for each runtime/version.

On Windows, `.NET GetFolderPath(MyDocuments)` and LocalApplicationData can ignore
an edited HOME or USERPROFILE. Use a genuine disposable profile/agent, verify
resolved known folders and PSResourceGet's chosen destination; do not rely on
environment-variable spoofing to provide user-account isolation.

### Repository registration persistence

PMU evidence establishes that on macOS PSResourceGet 1.2.0 uses
`LocalApplicationData/PSResourceGet/PSResourceRepository.xml`, outside a changed
HOME in the qualification child. PMU's repository transport coordination also
uses native LocalApplicationData, intentionally independently of installation
HOME. Assert actual paths separately on every OS/provider lane.

Changing HOME or PSModulePath alone is **insufficient**. Prefer a fresh container
user, disposable OS account or fresh hosted worker with no developer registry.
Run registration-mutating jobs serially per user/store; never share writable
profiles across matrix jobs or parallel builds. Preserve pre-existing
registration/configuration state and use collision-resistant operation-owned
names and exact ownership/configuration checks. Always clean in `finally`,
including cancellation/failure paths, then verify:

- no test-owned registrations or transport receipts remain;
- unrelated registrations/trust/priority/configuration are unchanged;
- module, journal, backup and temporary root ownership is as expected.

If cleanup fails or an ownership/API-binding crash window cannot be proven,
fail the job and preserve sanitized evidence. Quarantine/destroy the disposable
worker rather than restoring an entire XML store over possible concurrent
changes. A fresh next job is containment, not proof cleanup passed.

Local real-user registration mutations remain exceptional documented opt-ins,
not the recommended routine developer workflow. Registry snapshot comparison
detects interference but does not prevent it, and PMU locks cannot coordinate
noncooperating writers.

### State, failure and credentials

Use a workspace/disk retained across test-owned child processes for journal
recovery. A new ephemeral CI job cannot recover a journal discarded with the
previous job. For reboot testing, use a disposable VM disk and two-stage
controller; snapshot only the clean pre-test state and preserve the failed
state before restoring. Hard process termination is not power loss.

Inject short-lived, least-privilege fixture credentials only into approved
private-feed/vault jobs. Use job-scoped secret facilities and per-project test
identities, never production vaults. Do not pass secret values as command-line
arguments, cache profiles/vaults, serialize credentials into fixtures, or upload
raw provider errors/transcripts. Remove inherited secrets from nonsecret child
environments. Environment injection has process/privileged-reader exposure:
restrict identity, lifetime and runner reuse rather than claiming it is secret
storage. Test redaction with synthetic canaries before permitting real secrets.

Untrusted PR code gets no protected secrets, persistent runners or privileged
test accounts. Masking is defense in depth, not an authorization boundary.
Protected/manual jobs run reviewed trusted revisions with approval; never
execute fork checkout code with a privileged token. Avoid elevated checkout
contexts such as a `pull_request_target` job running untrusted code.

## PSModuleUpdate scenario design

Current implementation evidence includes
`tests/integration/ProcessRecovery.Tests.ps1`,
`tests/integration/ActiveState.Tests.ps1`,
`tests/integration/LocalProvider.Integration.Tests.ps1`,
`tests/integration/RepositoryBinding.Tests.ps1`, and
`tests/integration/UriBridge.Tests.ps1`; reuse their behavioral assertions.
The native local-provider integration currently skips outside macOS; a green
Windows/Linux suite with that skip is not platform qualification.

PMU roots are resolved by
`src/private/identity/Resolve-ModuleInstallationRoot.ps1` and
`src/private/locking/Resolve-PMUDataRoot.ps1`:
Windows CurrentUser Documents and AllUsers ProgramFiles module roots;
Unix CurrentUser HOME and AllUsers `/usr/local/share/powershell/Modules`;
Windows state Local/CommonApplicationData, macOS AllUsers state under
`/Library/Application Support/PSModuleUpdate`, Linux under
`/var/lib/PSModuleUpdate`. Assert these contracts in disposable native OS
environments rather than redirecting production paths for convenience.

| Scenario group | Observable outcomes required | Environment / privilege |
| --- | --- | --- |
| CurrentUser, discovery, PSModulePath | Existing selected-scope copy updated; other roots unchanged; active shadowing distinct; module discoverable without auto-import | Disposable unprivileged account on each native OS; Linux container supplementary |
| AllUsers / mixed scopes | Real system root update and same-base replacement; denied non-admin attempt yields `PMU.PermissionDenied`; no elevation/fallback; CurrentUser remains unchanged | Disposable full OS; admin/root setup and mutation plus separate normal-user assertions |
| Stable / prerelease identity | Exact stable update; `preview.1 -> preview.2 -> preview.3 -> stable`; `preview.2 < preview.10`; numeric directory collision; four-component identity retained | Native provider with local disposable feed; no network credential needed |
| Registered source / authentication | Name/URI binding, separate credentials per call, configured auth where supported, denied/expired credential and repointed endpoint fail without fallback/leak | Local controllable feed plus protected HTTPS feed jobs for actual auth |
| Temporary registration / RepositoryUri | No mutation under Install WhatIf; owned ephemeral Get/Install names; inferred API bound; unrelated registrations unchanged; dead-owner cleanup and unproven binding fail closed | Disposable native user/store; controlled termination; live HTTPS separately |
| GUID / tree / metadata | Reject GUID mismatch before mutation; verify SHA256 of file trees; detect missing/extra/modified content; only documented provider metadata excluded | Controlled fixtures plus real-provider install comparison; unprivileged |
| Rollback / persistent journals | Verified backup outside Modules; injected install/verification failures restore exact old tree; new process repairs valid journal; corrupt/malicious journal fails safely | Disposable disk preserved across processes; normal-user lane first |
| Interrupted install / hard kill | Synchronize on named phase markers, terminate test-owned child, assert next process recovers or preserves evidence with explicit failure | Controlled provider for PR smoke; real provider and VM restart in qualification |
| Concurrency / synchronization | Two actual processes, bounded timeout, one mutation/second no-op, lock release on death, source/plan revalidation | Same native local filesystem/profile; root only for AllUsers variants |
| Permissions / file locking | Read-only/denied paths, Windows ACL/reparse cases, open exclusive handles, loaded binary locking versus Unix unlink behavior | Native OS, local disk; special account/privilege for ACL/ownership cases |
| Restart / active state | Old loaded code remains active; installed tree/target reported separately; same-base loaded-file change requires restart; unloaded target does not invent active state | Fresh native child processes; script and platform-native binary fixtures |
| Provider/environment variation | Baseline and candidate provider metadata, exact runtime 7.4, module loading, dependencies and actual install destinations | Separate pinned jobs; additional provider rows cannot overwrite baseline evidence |

Run scripted recovery locally in controlled roots only. Real-provider termination
and AllUsers tests belong on disposable workers. Do not promise atomic install,
guaranteed power-loss recovery, or protection from unrelated package managers.
Private Azure prerelease and Nexus require authorized endpoints/fixtures; absence
is **not tested**, not passed or a reason to publish packages without permission.

## Gerber Core scenario design

Read-only investigation snapshot:
`e2d177a241f0a9dee64e1c3913c0ed2547746f0d`. This design does not modify Gerber
or claim fresh Gerber test execution. Gerber also targets PowerShell 7.4;
unlike PMU, it enables source coverage with a 90% target. Preserve that contract,
not PMU's disabled coverage setting. Its `run.ps1:7-16` includes a separate
terminal regression wrapper after analyzer/build/Nova unit/integration checks.
There are no tracked hosted workflows at the inspected revision.

### Credential layers are not interchangeable

| Layer | Observed Gerber contract | Required qualification |
| --- | --- | --- |
| Object/input handling | Secure terminal input begins as SecureString; Core's credential abstraction accepts/returns transient secret strings; PMU separately consumes PSCredential | Synthetic credential/canary tests for retrieval, conversion, output masking, no configuration/result/log leakage; do not claim all Core secret handling is SecureString-only |
| Persistence | Gerber lazily loads packaged Devlooped.CredentialManager 2.7.0.0 and DotNetConfig 1.2.0.0; rejects conflicting loaded assemblies | Built-module, fresh-process load/version conflict; owned-ID CRUD and cleanup; not arbitrary dependency functionality |
| OS-native store | Linux explicitly selects Secret Service; macOS and Windows delegate backend selection to the provider | Assert the actual backend/identity/session; separate native round trips on each OS |
| External authentication | Core implements stored PAT retrieval/interactive onboarding for ADO, not a Core OAuth/MSAL/browser/device-code provider | Controlled transport and noninteractive failure tests; authorized live test tenant only for real PAT validation; plugin OAuth remains plugin-owned |

Gerber configuration rejects likely secret fields. Native vault storage is not
the JSON configuration file; a file-backed terminal test double is not evidence
for native vault encryption or isolation. PowerShell's own SecureString/CLIXML
behavior is platform-dependent and is not an alternative vault strategy.
Never persist test credentials with Export-Clixml as a cross-platform secret
store. Gerber's runtime native provider remains the authority.

### Native store jobs

- **Linux:** `GCM_CREDENTIAL_STORE=secretservice` is set during initialization,
  then the prior environment restored. Qualify restoration on success/failure,
  a D-Bus user session, libsecret and a real test-owned Secret Service
  implementation. A headless Linux container without the service is useful
  for explicit actionable failure and no-plaintext-fallback tests, not success.
  A private D-Bus/service fixture can automate integration; a full session VM
  is preferable for desktop lifecycle claims.
- **macOS:** historical Keychain success is supporting history, not a new pass.
  Use a dedicated disposable account/session and test-only keychain/backend
  configuration only after confirming the provider actually honors it.
  An arbitrary temporary keychain is not isolation if the provider still writes
  the login keychain. Unlocked/locked/cancelled access and headless behavior
  need a controlled user session; human confirmation may remain necessary.
- **Windows:** the repository does not verify which native backend was chosen.
  First identify it under the real provider, then qualify owned-ID CRUD,
  missing entries, permissions and user-bound persistence. A disposable hosted
  user may suffice, but service versus interactive profile behavior needs an
  explicit capability probe; do not infer Credential Manager availability from
  the Windows label or assume DPAPI/Keychain/Secret Service parity.

Existing `tests/public/CredentialService.Integration.Tests.ps1:25-159` uses
`GERBER_RUN_NATIVE_CREDENTIAL_TESTS=1` for opt-in CRUD/plugin callbacks. Keep
the opt-in; add backend/session assertions before upgrading those runs to
platform qualification. Normal PRs use synthetic secrets and controlled
providers, with no native developer-vault access.

### Platform contracts and terminal constraints

| Concern | Evidence to reuse | Proposed observable platform cases |
| --- | --- | --- |
| User configuration/environment | `src/private/config/Resolve-GerberUserConfigPath.ps1:8-105` | Absolute `GERBER_CONFIG_PATH`; Windows APPDATA; Unix XDG/HOME fallback; reject blank/relative/invalid values; real OS paths, spaces, Unicode, cwd independence |
| Persistence/permissions/encoding | `src/private/config/Save-GerberUserConfiguration.ps1:14-127` | UTF-8 without BOM, temp-file cleanup, old file preserved on failure, atomic-style replace; Unix file mode; Windows ACL/denied write and directory inheritance observed separately |
| Module/dependency loading | `src/private/credentials/Get-GerberCredentialStore.ps1:74-121` and built integration fixtures | Isolated PSModulePath, lazy loading, fresh process, intentional incompatible preloaded assembly, plugin discovery/namespace, case and path separator handling |
| Native command execution | `src/private/ado/Approve-GerberAdoPipelineApproval.ps1:35-172` | curl.exe/curl found/missing, controlled nonzero exit, stdin credential configuration, quoted/Unicode paths, UTF-8 body, captured streams and timeout/child cleanup; REST fallback |
| Noninteractive auth | `src/private/ado/Resolve-GerberAdoConnectionReadiness.ps1:541-567,791-808` | Redirected/headless missing PAT gives actionable failure, no prompt/hang, no token in output; no live endpoint required |
| Secure terminal input | `src/private/cli/Read-GerberSecureValue.ps1:1-69` | Masking, cancellation/EOF, redirected input, secret canaries, narrow terminal and UTF-8 output without secret echo |
| Full terminal/process behavior | `scripts/build/Invoke-TerminalRegressionCI.ps1:19-66`; `tests/terminal/framework/pty_session.py:51-61` | Unix PTY regression on Linux/macOS; dedicated Windows terminal adapter and process cleanup; do not substitute redirected text for real terminal behavior |

Gerber explicitly protects the Unix configuration **file** mode; this does not
prove private parent-directory permissions or Windows ACL hardening. Test actual
owned-directory inheritance before deciding whether product changes are needed;
this investigation makes none.

The current terminal harness uses Python `pexpect.spawn`, `python3`, and
`bin/python`; it is Unix-oriented, not Windows-ready. Its test harness isolates
configuration and modules and replaces credentials with a file-backed double
(`tests/terminal/fixtures/TestHarness.ps1:52-109` and
`TestHarness.Configuration.ps1:8-27`). That is appropriate terminal contract
coverage, not native credential qualification.

Windows needs an approved ConPTY-capable adapter or equivalent controlled
interactive infrastructure. Until implemented, report the terminal stage as
blocked/unverified on Windows rather than weakening `run.ps1`, silently skipping
it, or reporting the entire Gerber quality loop passed. Phase 1 can establish
the six-lane Nova component baseline while the complete Windows terminal gate
remains visibly outstanding in Phase 3. Existing assertions and coverage
thresholds remain intact.

### Gerber source references

All paths below are in the read-only sibling `../Gerber/` at the snapshot above,
not proposed PMU implementation files:

- `project.json:9-44`: minimum runtime and enabled coverage.
- `.github/instructions/testing-policy.instructions.md:69-84,108-116`:
  authoritative Nova entrypoints.
- `src/private/credentials/Get-GerberCredentialStore.ps1:32-121`:
  Linux backend selection, environment restoration and assembly validation.
- `src/private/credentials/Invoke-GerberCredentialStoreOperation.ps1:22-35`:
  Core error boundary; no raw provider-secret diagnostics.
- `src/private/ado/Test-GerberAdoUserConfiguration.ps1:363-382` and
  `tests/private/ado/Test-GerberAdoUserConfiguration.Tests.ps1:180-210`:
  configuration rejects credential-like fields.
- `tests/private/config/Resolve-GerberUserConfigPath.Tests.ps1:21-133` and
  `Save-GerberUserConfiguration.Tests.ps1:123-165`: characterization to retain.
- `tests/private/ado/Approve-GerberAdoPipelineApproval.Tests.ps1:1-44`:
  Windows `.cmd` versus Unix executable fixtures.

These references record inspected architecture and existing tests, not a claim
they executed on Windows/Linux/7.4. Native credential, PTY and external service
outcomes require their own reports.

## CI workflow design

Use one selected CI provider initially. Per-project thin pipelines call the same
project wrappers and optional shared environment adapter; pin dependencies and
serialize build/test flows that regenerate `dist` or share provider state.

| Trigger | Scope | Secret / privilege boundary | Reporting |
| --- | --- | --- | --- |
| Every PR | Six native OS/runtime lanes; secret-free unit/contracts, safe built-module checks, isolated process tests | No external credentials; no real developer profiles; provider mutation only after isolation is established | Required status for all six lanes, XML + sanitized environment manifest |
| Scheduled compatibility | Pinned baseline plus latest stable resolution; provider/architecture extensions and native local-feed scenarios | Disposable workers; no live private credentials in ordinary schedule | Trend concrete versions and skips; fail on unexpected qualification skips |
| Protected manual / release candidate | Full approved platform/privileged/recovery/credential matrix against a fixed candidate | Reviewed revision, environment approval, per-job least privilege | Artifact-bound qualification report; blocked rows remain explicit |

Use Linux containers as additional fast lanes, not replacements for the three
native OS lanes. A hosted Windows administrator or Unix passwordless sudo can
provide disposable AllUsers execution after capability preflight; still run
negative permissions as a genuinely unprivileged identity. Hosted runners do
not automatically provide snapshot/reboot orchestration or an unlocked user
keychain.

Preserve Nova NUnit XML as raw evidence. Azure's Publish Test Results supports
NUnit; GitHub needs a pinned, reviewed result-publishing action or a small
read-only summary adapter. Its built-in artifact upload is storage, not a
native NUnit interpretation step. Publishing failure must not conceal test
failure. Use job-unique filenames to avoid concurrent writes; always retain
sanitized failure output and mark uploads best effort if the runner is lost.

Proposed retention: 14 days for PR diagnostic artifacts, 30 days for scheduled
compatibility, and 180 days or the supported release lifetime (whichever is
longer) for qualification reports. These are approval/budget proposals subject
to provider limits; use durable approved storage if CI cannot retain that long.
Never retain secret stores, complete user profiles or authenticated transcripts.
Cache only checksum-keyed nonsecret tooling, not module/repository state whose
freshness the test is supposed to verify.

Each report should include source revision/dirty status, candidate module and
package hashes, concrete OS image/build/kernel/architecture, runtime/provider/
Nova/Pester versions, privileges/identity class, scenario IDs, commands invoked,
passed/failed/skipped/blocked counts, times, cleanup and redaction status, and
remaining gaps. Attach the exact tested artifact; separate building source on
different platforms from qualifying one release candidate.

## Recommendation and trade-offs

Choose **native hosted matrix + optional local Linux containers + selective
disposable VMs**, not an all-Vagrant or all-container platform. Native jobs give
the smallest credible three-OS baseline. Containers improve Linux developer
speed but cannot prove native Windows locks/ACLs or macOS Keychain. Full VMs
earn their cost for snapshot/reboot, desktop identity, system-root and
permission-transition tests; do not provision them merely to run pure unit tests.

Prefer GitHub Actions provisionally for existing GitHub/Nova contribution
conventions and reusable workflow distribution. Choose Azure Pipelines instead
if organizational runner capacity, governance or tenant/feed access gives a
concrete advantage; private Azure Artifacts usage alone does not require Azure
Pipelines. Actual repository hosting is still unconfirmed.

Share runtime/isolation/reporting mechanics, not product semantics. Begin with
the minimum matrix, measure actual runtime/cost and commonality, then approve
additional architectures, providers, credential sessions and VM adapters.
No implementation, purchasing, secret enrollment or remote execution follows
automatically from this recommendation.

## Open questions and approval

The numbered approval register and implementation-ready phase boundaries live
in [the roadmap](TEST_IMPLEMENTATION_ROADMAP.md#decisions-requiring-owner-approval).
Important unresolved inputs are actual repository hosting, runner/secret access,
supported processor architectures, 7.4 lifecycle policy, Gerber native-vault
infrastructure, private prerelease/Nexus fixtures, budgets and shared ownership.

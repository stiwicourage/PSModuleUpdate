# TL;DR

G-4A3 is **complete and accepted within its qualified scope as of 2026-10-23**.
See [closure and preserved evidence](G4A3_CLOSURE.md). Functional implementation,
executed tests, owner-accepted quality findings, and outstanding environment
qualification are separate statuses, not one universal readiness claim.

The completed development plan below implemented PSModuleUpdate test-first as a
Nova-managed PowerShell 7.4+ module with exactly two public commands.
Preserve the G-4A1 plan/consent/error model,
then apply the approved G-4A2-FIX2 revisions: CurrentUser and AllUsers, semantic
same-base prerelease progression, Strategy C staging and replacement, persistent
recovery, OS-level locks, tree verification, and best-effort rollback.

Phases 3A through 4F are retained as the completed implementation work breakdown,
not instructions to restart development. Their functional outcomes were accepted;
their cross-platform/live-environment criteria remain bounded by actual evidence.
The separate proposed qualification phase is
[cross-platform testing](CROSS_PLATFORM_TESTING.md), with an
[execution roadmap](TEST_IMPLEMENTATION_ROADMAP.md). No infrastructure
implementation is authorized by this documentation update.

## Completion status

| Area | Status |
| --- | --- |
| Phases 3A-3D: contracts, identity, repository, planning | Complete within G-4A3 scope |
| Phases 4A-4F: locking, staging, journal, replacement, recovery, restart | Complete within G-4A3 scope |
| Local validation | Recorded pass: 287 unit tests; five integration tests; one and three respective skips |
| Four final live runs and local packaging | Passed within the explicit artifact/environment limits in the closure |
| CodeScene/SIG residual findings | Explicitly owner-accepted; not all numerical thresholds passed |
| Windows/Linux, PowerShell 7.4, real AllUsers, Nexus, private Azure prerelease | Outstanding qualification, not passed |
| Reusable cross-platform infrastructure | Design proposed; not implemented |

## Delivery constraints

- Work only in the PSModuleUpdate repository.
- Treat the sibling Gerber repository as read-only evidence.
- Preserve the Nova scaffold and generated-output ownership.
- Do not implement Gerber `/update` or change NovaModuleTools.
- Do not hand-author `.psm1` or `.psd1` output.
- Do not update real user modules, real AllUsers paths, existing repository
  registrations, credentials, or external feeds in normal tests.
- Do not commit, push, tag, publish, or release without separate authorization.
- Keep PowerShell compatible with `project.json`
  `Manifest.PowerShellHostVersion` 7.4.
- Use PSResourceGet 1.2.0 as the initial provider contract baseline.
- The local `run.ps1` and analyzer wrapper now exist and use the required Nova
  pipeline. Their completed execution is recorded in the closure report.

## Target repository shape

The exact helper list may change as tests establish smaller responsibilities,
but implementation should use these ownership domains:

```text
src/
  public/
    Get-PSModuleUpdate.ps1
    Install-PSModuleUpdate.ps1
  private/
    identity/
    version/
    repository/
    planning/
    provider/
    installation/
    staging/
    locking/
    recovery/
    verification/
    shared/
tests/
  public/
  private/<matching-domain>/
  integration/
  TestHelpers/
docs/PSModuleUpdate/en-US/
```

Every `src/**/*.ps1` file receives a mirrored focused test. Public commands stay
thin and delegate to private workflow entry points. Cross-domain filesystem,
provider, process, and environment operations use narrow adapters rather than
being spread across callers.

## Public contract to implement

### `Get-PSModuleUpdate`

Mutually exclusive registered-name and explicit-URI parameter sets:

```text
-Module      [PSModuleInfo]  mandatory scalar
-Repository  [string]        mandatory literal in registered-name set
-RepositoryUri [Uri]         mandatory in explicit-URI set
-Policy      [hashtable]     optional
-Credential  [PSCredential]  optional
```

Policy fields and defaults:

```text
Channel               [Stable|IncludePrerelease] = Stable
Scope                 [CurrentUser|AllUsers]      = CurrentUser
ExpectedRepositoryUri [Uri|null]                  = null
VersionRange          [string|null]               = null
```

Output: one schema-1 `PSModuleUpdate.UpdatePlan` with the complete field set in
`ARCHITECTURE.md`.

The target is an installed `PSModuleInfo`, not necessarily the caller or a loaded
module. It need not contain PMU code or declare a PMU dependency. Keep target
identity separate from any matching active module observation.

### `Install-PSModuleUpdate`

One `ByUpdatePlan` parameter set:

```text
-Update           [object]        mandatory, pipeline by value
-Credential       [PSCredential]  optional
-AcceptLicense    [switch]        default false
-TrustRepository  [switch]        default false
-WhatIf / -Confirm                native ShouldProcess
```

Use `SupportsShouldProcess` with `ConfirmImpact = 'High'`. Output: one schema-1
`PSModuleUpdate.UpdateResult`. Do not add target-changing or force parameters.

## Implementation sequence

### Phase 3A — Contract fixtures and public shells

**Observable scenarios first**

1. Reject null, ambiguous, source-layout, and identity-mismatched target modules.
2. Validate the exact policy keys, types, defaults, and enum values.
3. Validate the one-repository literal contract.
4. Return one schema-1 plan object without credentials.
5. Reject manufactured, deserialized, wrong-schema, and field-inconsistent
   install plans.
6. Prove pipeline-by-value binding for `-Update` and no property-name binding.
7. Prove native `WhatIf`/Confirm wiring without mutation.

**Likely files**

- `src/public/Get-PSModuleUpdate.ps1`
- `src/public/Install-PSModuleUpdate.ps1`
- `src/private/planning/ConvertTo-UpdatePolicy.ps1`
- `src/private/planning/Test-UpdatePlan.ps1`
- `src/private/shared/Stop-PMUOperation.ps1`
- mirrored tests under `tests/public/`, `tests/private/planning/`, and
  `tests/private/shared/`

**Exit evidence**

- focused tests observed red before implementation and green after it
- exported parameter sets/defaults/types match the contract
- no credential-bearing property appears in plan/result/error fixtures

### Phase 3B — Identity, scope, and complete version handling

**Observable scenarios first**

1. Read active name, GUID, path, numeric version, and prerelease from the actual
   module and manifest.
2. Resolve CurrentUser and AllUsers roots on each supported platform through an
   isolated platform adapter.
3. Resolve only the installation in the requested scope.
4. Represent modules installed in both scopes without modifying or conflating
   them.
5. Detect PSModulePath shadowing and report active separately from selected
   installed state.
6. Compare stable and prerelease versions, including preview.2 versus
   preview.10 and prerelease versus stable.
7. Preserve supported four-component numeric versions and fail unsupported
   comparisons explicitly.

**Likely files**

- `src/private/identity/Get-ActiveModuleIdentity.ps1`
- `src/private/identity/Get-InstalledModuleIdentityList.ps1`
- `src/private/identity/Resolve-ModuleInstallationRoot.ps1`
- `src/private/version/ConvertTo-CompleteModuleVersion.ps1`
- `src/private/version/Compare-CompleteModuleVersion.ps1`
- `src/private/version/Test-CompleteModuleVersionNewer.ps1`
- mirrored tests and platform fixtures

**Exit evidence**

- deterministic unit tests for both scopes and mixed-scope precedence
- no use of a numeric directory name as complete-version evidence
- no silent fallback between scopes

### Phase 3C — Repository, credential, discovery, and selection

**Observable scenarios first**

1. Resolve one registered repository and safely compare an expected URI.
2. Reject a repointed repository.
3. Pass a direct `PSCredential` to provider calls without serializing it.
4. Use repository-configured authentication when direct credentials are absent.
5. Distinguish authentication failure, unavailable repository, package not
   found, and general discovery failure where provider evidence permits.
6. Select greatest stable or greatest stable/prerelease candidate according to
   policy and range.
7. Bind the exact target and retain it when a newer release later appears.
8. Return `UpToDate`, `AlreadyInstalledRestartRequired`, and `ActionRequired`
   for their distinct conditions.
9. Distinguish registered names from explicit URIs through parameter sets.
10. Establish a safe provider-supported URI transport mechanism, or document
    the explicit limitation without silently creating permanent registrations.
11. Test owned temporary registration, no overwrite/repointing, cleanup
    failures, termination, unrelated registration preservation, and concurrent
    cooperating operations separately from target locks.

**Likely files**

- `src/private/repository/Get-RepositorySnapshot.ps1`
- `src/private/repository/Test-RepositorySnapshot.ps1`
- `src/private/provider/Find-ProviderResource.ps1`
- `src/private/planning/Select-UpdateTarget.ps1`
- `src/private/planning/New-UpdatePlan.ps1`
- provider adapter and planning tests using controlled output

**Exit evidence**

- exact repository/source and exact target are present in the plan
- no fallback feed or recomputation of latest
- plan inspection and error records contain no credential material

### Phase 3D — Result model and stale-plan revalidation

**Observable scenarios first**

1. Reapplying a plan with an already healthy target returns `AlreadyInstalled`
   without provider installation.
2. A repository endpoint change returns `PMU.RepositoryChanged`.
3. A selected-scope installation change returns
   `PMU.InstalledStateChanged`.
4. Active identity/path, provider, or destination changes return
   `PMU.PlanStale`.
5. A newer publication does not change the exact target.
6. Active, installed, target, and restart fields remain separate.

**Likely files**

- `src/private/installation/Test-UpdatePlanPrecondition.ps1`
- `src/private/installation/New-UpdateResult.ps1`
- mirrored tests

**Exit evidence**

- stale plans cannot silently overwrite changed state
- all outcomes and stable error IDs are asserted

### Phase 4A — Lock and PMU-controlled data paths

**Observable scenarios first**

1. Lock identity differs by module, scope, and canonical root.
2. A second process times out with `PMU.LockTimeout`.
3. It acquires after normal release and after holder termination.
4. A second updater revalidates and avoids redundant replacement.
5. Lock and data paths are outside the Modules tree and respect scope-specific
   permission boundaries.

**Likely files**

- `src/private/locking/Get-InstallationLockIdentity.ps1`
- `src/private/locking/Resolve-PMUDataRoot.ps1`
- `src/private/locking/Enter-InstallationLock.ps1`
- `src/private/locking/Exit-InstallationLock.ps1`
- child-process test helpers

**Exit evidence**

- real process-level lock tests on the development platform
- deterministic timeout and release behavior
- Windows/Linux qualification remains explicitly pending until executed

### Phase 4B — Staging and package validation

**Observable scenarios first**

1. Save the exact stable and prerelease target from the exact repository.
2. Reject missing manifest, wrong name, wrong version/prerelease, unexpected
   GUID, malformed structure, corrupt extraction, and source mismatch before
   mutation.
3. Do not import or execute staged module code.
4. Preserve provider-owned dependency resolution for final installation.

**Likely files**

- `src/private/provider/Save-ProviderResource.ps1`
- `src/private/staging/New-StagedPackage.ps1`
- `src/private/staging/Get-StagedModuleIdentity.ps1`
- `src/private/staging/Test-StagedPackage.ps1`
- disposable local-feed integration fixtures

**Exit evidence**

- intended red-to-green tests for every validation failure
- old installation unchanged for all pre-mutation failures

### Phase 4C — Persistent journal and backup

**Observable scenarios first**

1. Persist every defined journal state with exactly one valid transition path.
2. Do not claim `BackupReady` until the backup is complete and verified.
3. Use safe repeated transitions and atomic file replacement where supported.
4. Reject corrupt journals, invalid module/root/version relationships, path
   traversal, external paths, and unsafe symbolic links.
5. Never serialize credentials.

**Likely files**

- `src/private/recovery/New-RecoveryJournal.ps1`
- `src/private/recovery/Read-RecoveryJournal.ps1`
- `src/private/recovery/Set-RecoveryJournalState.ps1`
- `src/private/recovery/Test-RecoveryJournal.ps1`
- `src/private/recovery/New-InstallationBackup.ps1`
- mirrored tests with test-owned roots

**Exit evidence**

- journals survive a child-process exit
- invalid paths cannot cause deletion or restoration
- file-ending and JSON round-trip checks pass

### Phase 4D — Normal install and Strategy C replacement

**Observable scenarios first**

1. Normal different-numeric-version install uses plain exact
   `Install-PSResource`.
2. Exact healthy repeat is a no-op.
3. Same-base preview progression and preview-to-stable use Strategy C.
4. `-Reinstall` is invoked only for a validated same-base collision.
5. GUID mismatch aborts before mutation.
6. Another scope and unrelated numeric versions remain untouched.
7. CurrentUser permission failure maps correctly.
8. AllUsers permission failure maps to `PMU.PermissionDenied`, never fallback or
   elevation.

**Likely files**

- `src/private/provider/Install-ProviderResource.ps1`
- `src/private/installation/Invoke-NormalInstallation.ps1`
- `src/private/installation/Invoke-SameBaseReplacement.ps1`
- `src/private/installation/Invoke-UpdateInstallation.ps1`
- unit and isolated integration tests

**Exit evidence**

- CurrentUser progression `preview.1 -> preview.2 -> preview.3 -> stable`
- provider call assertions prove selective `-Reinstall`
- AllUsers success remains a qualification gap until an approved disposable
  elevated host is available

### Phase 4E — Verification, rollback, and next-run recovery

**Observable scenarios first**

1. Detect a provider success that leaves the old full version installed.
2. Detect missing, unexpected, modified, and partially copied files.
3. Account only for documented provider-generated metadata.
4. Restore and verify backup after provider exception or verification failure.
5. Report both installation and rollback failure when rollback fails.
6. On next run, restore an incomplete replacement when a valid backup survives.
7. Recognize an already complete target and complete the journal without
   needless replacement.
8. Preserve evidence and return `PMU.RecoveryRequired` or
   `PMU.RecoveryFailed` when repair is unsafe.

**Likely files**

- `src/private/verification/Get-FileTreeInventory.ps1`
- `src/private/verification/Compare-FileTreeInventory.ps1`
- `src/private/verification/Test-InstalledModule.ps1`
- `src/private/recovery/Restore-InstallationBackup.ps1`
- `src/private/recovery/Repair-UnfinishedInstallation.ps1`
- fault-injection and child-process test helpers

**Exit evidence**

- exception rollback and verification-failure rollback pass
- simulated process termination is detected on the next run
- no atomicity or guaranteed power-loss claim is made

### Phase 4F — Restart semantics and terminal-facing behavior

**Observable scenarios first**

1. Loaded old version remains active after a side-by-side update.
2. Loaded files replaced by a same-base transition require restart.
3. A same-version repair of loaded files also requires restart.
4. An unloaded verified target does not require restart solely because versions
   differ.
5. Progress identifies checking, staging, replacing, verifying, and recovering
   phases without invented percentages.
6. Noninteractive execution suppresses prompts and progress and fails
   actionably when required inputs are absent.

**Likely files**

- `src/private/installation/Test-RestartRequired.ps1`
- public command orchestration updates
- public unit and built-module integration tests

**Exit evidence**

- structured objects remain on the success stream
- diagnostics use appropriate PowerShell streams
- cmdlet UX is reviewed separately from any future Gerber CLI UX

## Test strategy

### Unit tests

Use mirrored, dot-source-first Pester tests for policy, identity, version,
planning, validation, errors, journal transitions, tree comparison, and
restart calculation. Mock provider and filesystem adapters when isolating the
owning unit.

### Isolated integration tests

Use disposable module names, local package feeds, HOME/module roots, staging,
backup, lock, and journal locations. Child processes are required for locking,
loaded-module behavior, and interruption. Tests must never mutate real installed
modules or perform a real normal-suite AllUsers write.

On macOS, changing HOME does not isolate PSResourceGet repository registrations.
Any provider integration that requires registration must use a unique owned name,
preserve a before hash, unregister only that name in `finally`, and prove the
store and existing registrations are unchanged.

### Platform qualification

Run the maintained integration matrix on:

- PowerShell 7.4 on Windows
- PowerShell 7.4 on macOS
- PowerShell 7.4 on Linux

Additional provider versions are separate matrix rows. Successful AllUsers
qualification requires an authorized disposable elevated host; it must not be
simulated or run against a developer's machine.

### Repository protocol qualification

Use the same PMU integration for all scenarios, with optional per-call
`PSCredential`, exact source binding, and no fallback:

1. PSGallery: live public exact/prerelease discovery, acquisition, and isolated
   installation of a valid PowerShell module.
2. NuGet.org: live NuGet v3 exact/prerelease discovery and acquisition; reject
   general .NET packages without weakening module validation. A missing suitable
   module fixture is a qualification limitation, not permission to install
   arbitrary NuGet packages.
3. Private Azure Artifacts: authorized caller-supplied credentials, exact and
   prerelease discovery, acquisition, isolated installation, same-base
   progression, and verification where suitable packages exist. Do not publish
   fixtures or change feed permissions.
4. Nexus: expected compatibility through the same NuGet v3 provider behavior;
   report live execution as not tested without an authorized endpoint.

PSResourceGet 1.2.0 requires repository registration for Find, Save, and Install.
Direct URI-as-name execution returned `RepositoryNameIsNotResolved`. Verify the
real registration store and protect mutations; HOME isolation is not sufficient.
Keep credentials out of registration configuration, plans, journals, logs, and
test output. Label implemented, tested, not-tested, and blocked behavior
separately, and never equate mocked contracts with live repository support.

## Documentation work after implementation

When public commands exist:

1. Build and import the generated module.
2. Generate and update PlatyPS help for both public commands.
3. Document both scopes, policy defaults, direct/configured credentials,
   Strategy C, journals, rollback limits, locking, errors, result fields, and
   restart behavior.
4. Update `README.md` with supported workflows rather than implementation
   internals.
5. Update `CHANGELOG.md` and `RELEASE_NOTE.md` under the repository release
   policy when the public behavior is implemented.
6. Keep Gerber integration documentation out of PMU command help except for a
   neutral consumer example.

## Validation order retained from implementation

The following describes the implementation workflow, not checks rerun by this
documentation-only closure. The recorded residual CodeScene/SIG findings have
explicit G-4A3 owner acceptance; the historical numerical targets below do not
authorize score-only refactoring or negate that acceptance.

For each behavior increment:

1. Add focused tests and observe the intended red result.
2. Implement the smallest behavior.
3. Run the focused tests green.
4. Run focused ScriptAnalyzer through repository-approved settings when
   PowerShell files exist.
5. Measure every new or changed supported code/test/helper file with CodeScene;
   new files have no historical baseline and target 10.0.
6. Refactor while focused tests remain green.

Before implementation handoff, run in repository order:

1. `./scripts/build/Invoke-ScriptAnalyzerCI.ps1`
2. `Invoke-NovaBuild`
3. `Invoke-NovaTest`
4. `Test-NovaBuild`
5. `pwsh -NoLogo -NoProfile -File ./run.ps1`
6. the relevant provider/platform integration matrix
7. CodeScene review/score for all touched supported code, targeting 10.0

Do not bypass a missing or failed wrapper with direct alternatives. Both local
wrappers are present; final local execution passed as recorded in the closure.

Documentation-only Phase 1/2 validation is limited to Markdown structure,
repository text formatting, diff inspection, and repository-boundary checks.

## Accepted implementation criteria

The owner accepted the functional criteria below within the recorded environment.
CodeScene/SIG residual findings are risk accepted, rather than an all-pass score
gate. Additional platform qualification remains separate:

- both public commands and exact parameter contracts exist
- plan/result/error contracts are tested
- CurrentUser and AllUsers logic is implemented without scope fallback
- same-base preview progression and preview-to-stable work through Strategy C
- staging, GUID validation, backup, journal, rollback, next-run recovery, lock,
  and tree verification are implemented
- active, installed, target, and restart state are independently reported
- credentials never enter persistent state or output
- relevant unit/integration tests, analyzer, Nova build/test, wrapper, and
  CodeScene gates have current evidence
- known platform/provider gaps are labeled unverified rather than passed

## Historical conflict reconciliation

| Historical position | Current implementation direction |
| --- | --- |
| G-4A1 CurrentUser-only; block AllUsers/mixed scope | Both scopes required; explicit selected-scope update, no fallback, mixed state reported |
| G-4A1/G-4A2 reject same-base collisions | Strategy C supports normal prerelease progression and stable promotion |
| No `-Reinstall` | Internal exact `-Reinstall` only for validated collisions |
| No automatic rollback | Best-effort backup/restore plus persistent next-run recovery |
| Small short-lived coordination lock | OS exclusive lock covers recovery through completion and is keyed by module/scope/root |
| Manifest/version verification sufficient | Manifest identity plus deterministic file-tree verification |
| Private Azure authentication blocked | Final G-4A3 stable install and unregistered HTTPS-v3 transport passed; private prerelease and broader dependency behavior remain unverified |
| AllUsers not supported | Required in code; successful real mutation remains an explicit qualification gap |
| Active and installed version treated closely | Active, selected installed, exact target, and restart state are separate contracts |

## Separate qualification phase / resume here

No product-design questions reopen the completed G-4A3 implementation. Approved
closure is recorded in `DECISIONS.md`; infrastructure choices in the
[strategy](CROSS_PLATFORM_TESTING.md) remain proposals requiring approval.

Evidence gaps to resolve through the new qualification roadmap:

- exact cross-platform PMU data-directory locations and permissions
- maintained compatibility rows beyond PSResourceGet 1.2.0
- successful disposable AllUsers execution
- Windows loaded-file replacement behavior
- real-provider and additional-platform hard-kill journal repair, beyond the
  passed macOS controlled-process fixtures
- private-feed prerelease/dependency behavior beyond the passed stable updates

Next action: approve the testing architecture, ownership, costs, and initial
matrix in [the qualification roadmap](TEST_IMPLEMENTATION_ROADMAP.md), then
authorize its phases separately. Do not restart Phase 3A, refactor to chase
scores, implement Gerber integration, or change Nova Init as part of closure.

## G-4A4 — Cross-platform qualification and GitHub Actions design

Planning is complete in [G4A4/](G4A4/README.md): workflow map, Nova release
analysis, architecture, runner feasibility, test policy, release gating,
security, ownership, roadmap, and decision register. Next action: owner approval
of [the decisions](G4A4/DECISION_REGISTER.md), then separate authorization per
roadmap phase. Nothing is implemented.

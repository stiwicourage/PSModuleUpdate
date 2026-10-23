# PSModuleUpdate architecture

## Purpose and status

PSModuleUpdate (PMU) is an independent PowerShell 7.4+ module that plans and
applies an update for one explicitly identified PowerShell module. It is a thin
orchestration layer over `Microsoft.PowerShell.PSResourceGet`, not a package
manager, repository registry, credential store, background updater, or general
installed-module inventory.

This document is the implementation architecture for G-4A3. It transfers the
approved G-4A1 contract and the superseding G-4A2-FIX2 decisions into the PMU
repository. Source, tests, and command help now exist; this architecture is
not a substitute for executed qualification or a passing readiness gate.

The historical evidence remains owned by the read-only sibling Gerber
repository:

- `docs/architecture/G-4A0-shared-self-update-analysis.md`
- `docs/architecture/G-4A1-psmoduleupdate-design.md`
- `docs/architecture/G-4A2-psresourceget-provider-qualification.md`
- `docs/architecture/G-4A2-FIX1-azure-artifacts-authentication.md`
- `docs/architecture/G-4A2-FIX2-installation-scope-and-prerelease-replacement.md`

## Product boundary

PMU owns:

- the `Get-PSModuleUpdate` and `Install-PSModuleUpdate` public cmdlets
- full-version identity, release selection, plan validation, and stale-plan
  detection
- explicit CurrentUser and AllUsers scope handling
- the PSResourceGet adapter and provider error translation
- cooperative locking, staging, validation, replacement, verification,
  rollback, and persistent recovery
- structured plan, result, and error contracts
- PMU tests, command help, build metadata, and release lifecycle

PMU does not own:

- Gerber `/update`, Gerber terminal rendering, or Gerber configuration
- NovaModuleTools update behavior or build implementation
- persistent consumer repository configuration, repository trust persistence, credential-provider
  installation, vault configuration, elevation, or package publication
- automatic module reload or removal from the current session
- consumer-specific module or plugin discovery
- custom NuGet transport, dependency resolution, or Azure authentication

PMU is one shared, normally installed PowerShell module, not an implementation
embedded in each consumer. Consumers may declare it in `RequiredModules`, but
the target module need not depend on PMU, contain PMU-specific code, be the
caller, or be loaded. A caller may update separate installed modules with
different repository, credential, scope, and policy inputs.

Consumers pass an installed target module identity and policy to PMU. PSResourceGet owns
feed access, package discovery, dependency resolution, download, extraction,
and the underlying install operation. PMU adds policy, safety, verification,
and recovery around those operations.

## Runtime and provider baseline

- PowerShell: 7.4 or later
- Platforms: Windows, macOS, and Linux
- Provider: `Microsoft.PowerShell.PSResourceGet`
- Qualified behavioral baseline: 1.2.0
- Initial compatibility policy: stable provider versions `>= 1.2.0` and
  `< 2.0.0`, limited to versions included in the executed compatibility matrix

PMU must check provider availability and compatibility when a PMU command is
invoked. It must not install, upgrade, downgrade, or silently substitute a
provider. Behavior observed in 1.2.0, especially same-base replacement and
provider-generated metadata, must be requalified before a later provider
version is declared supported.

## Public API

### `Get-PSModuleUpdate`

`Get-PSModuleUpdate` is read-only for module installations. It performs
repository discovery and local inspection but does not install, remove, repair,
lock a destructive operation, create an installation journal, change scope, or
persist credentials. Any explicit-URI registration mechanism is subject to the
narrow transport exception below.

The command distinguishes registered-name and explicit-URI parameter sets:

| Parameter | Type | Binding and default |
| --- | --- | --- |
| `Module` | `System.Management.Automation.PSModuleInfo` | Mandatory scalar installed target, which need not be loaded or be the caller. No name-only inference. |
| `Repository` | `string` | Mandatory in the registered-name set. Non-empty literal name; no wildcard, array, or all-repository search. |
| `RepositoryUri` | `System.Uri` | Mandatory in the explicit-URI set; mutually exclusive with `Repository`. Supported transport safety must be established before claiming URI support. |
| `Policy` | `hashtable` | Optional. Omitted fields receive the defaults below. Unknown keys or invalid types are errors. |
| `Credential` | `System.Management.Automation.PSCredential` | Optional, in-memory, per-call credential passed only to provider operations. |

The `Policy` schema is:

| Field | Type | Default | Contract |
| --- | --- | --- | --- |
| `Channel` | `string` enum: `Stable`, `IncludePrerelease` | `Stable` | `IncludePrerelease` permits stable and prerelease releases; it is not preview-only. |
| `Scope` | `string` enum: `CurrentUser`, `AllUsers` | `CurrentUser` | Selects the installation to inspect and later update. PMU never changes or falls back from it. |
| `ExpectedRepositoryUri` | `System.Uri` or null | null | Optional deployment-approved endpoint. When supplied, the registered endpoint must match using safe URI comparison. |
| `VersionRange` | `string` or null | null | Optional provider-supported NuGet range. PMU does not invent a second range syntax. |

The target may be obtained from `Get-Module -ListAvailable` without importing
its code. Active state describes any matching module actually loaded in the
session, not the supplied target object; it may be absent.
The active module may resolve from a different scope than `Policy.Scope`. PMU
must explicitly resolve the matching module name and GUID in the requested
scope, record both states, and never modify the other scope. If no matching
installation exists in the requested scope, the initial self-update contract
returns `PMU.UnsupportedInstallation`; it does not create a new shadowing copy.

### `Install-PSModuleUpdate`

`Install-PSModuleUpdate` is the only public mutation command. It has one
parameter set, `ByUpdatePlan`, and uses
`[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]`.

| Parameter | Type | Binding and default |
| --- | --- | --- |
| `Update` | `object` validated as a live `PSModuleUpdate.UpdatePlan` | Mandatory; accepts pipeline input by value only. Property-name binding is not supported. |
| `Credential` | `System.Management.Automation.PSCredential` | Optional. It must be supplied again when direct credentials were used during planning. |
| `AcceptLicense` | `switch` | False. Explicit permission for the exact planned package's provider license requirement. |
| `TrustRepository` | `switch` | False. Operation-scoped provider permission; it must not persistently change repository trust. |
| `WhatIf`, `Confirm` | PowerShell common parameters | Native `ShouldProcess` behavior. PMU adds no custom prompt. |

The command does not expose `Name`, `Version`, `Repository`, `Scope`, `Force`,
`Reinstall`, custom path, arbitrary scriptblock, or provider override
parameters. A caller obtains a new plan to change any planned action.

### Consent and `ShouldProcess`

Consent to install, repository trust, license acceptance, and credentials are
separate concerns:

1. PMU validates the plan and performs read-only revalidation.
2. `ShouldProcess` describes the exact module, full target version, repository,
   and scope before any lock, staging write, journal write, recovery mutation,
   or provider install.
3. A declined `ShouldProcess` call returns `Outcome = 'Cancelled'`.
4. `-WhatIf` may perform read-only revalidation and may fail because discovery
   or authentication is unavailable. It returns `Outcome = 'WhatIf'` and must
   not acquire the mutation lock, stage a package, repair recovery state,
   write a journal, install, or change repository settings.
5. `-Confirm:$false` suppresses native install confirmation only. It does not
   imply `-TrustRepository`, `-AcceptLicense`, valid credentials, or permission
   to elevate.
6. After approval, recovery is limited to an unfinished PMU operation for the
   same module, scope, resolved root, and validated PMU-controlled paths. If
   recovery changes the installed preconditions, PMU completes safe recovery
   and then requires a fresh plan instead of silently applying a now-stale
   update.

Consumers with their own exact-action confirmation may call the cmdlet with
`-Confirm:$false` after obtaining that consent. Noninteractive callers must
supply every required input explicitly; PMU must not initiate a custom prompt
or silently answer a provider prompt.

## Update plan contract

`Get-PSModuleUpdate` returns exactly one data-only object with:

- `PSTypeName = 'PSModuleUpdate.UpdatePlan'`
- `SchemaVersion = 1`

It is a live in-process plan, not a signed authorization token. Persisted,
serialized, or deserialized plans are outside the initial public contract.
Every field is validated and relevant state is independently re-read before
mutation.

| Group | Fields |
| --- | --- |
| Contract | `SchemaVersion`, `CreatedAtUtc`, `PmuVersion`, `ProviderName`, `ProviderVersion` |
| Active identity | `ModuleName`, `ModuleGuid`, `ActiveVersion`, `ActivePath`, `ActiveScope` |
| Selected installation | `Scope`, `DestinationRoot`, `InstalledVersion`, `InstalledManifestPath`, `ObservedInstalledVersions` |
| Repository | `RepositoryName`, `RepositoryUri`, `RepositoryApiVersion`, `RepositoryTrusted` |
| Selection policy | `Channel`, `VersionRange` |
| Exact target | `TargetVersion`, `TargetNumericVersion`, `TargetPrerelease`, `TargetIsPrerelease`, `TargetInstalledPath` |
| Decision | `UpdateAvailable`, `Disposition`, `Reason`, `RestartRequired` |
| Prerequisites | `RequiresRepositoryTrust`, `RequiresLicenseAcceptance`, `DependencySummary` |

For an initially unregistered URI, `RepositoryName` is null: the stable source
identity is the URI and bound provider API, not a temporary transport name.
The `Active*` values are null when no matching target is loaded.

`ObservedInstalledVersions` contains non-secret records with full version,
numeric version, prerelease label, scope, resolved root, manifest path, and
manifest GUID. It is limited to the named module and the roots necessary to
explain selected-scope and active-resolution state.

Allowed dispositions are:

- `UpdateAvailable`
- `UpToDate`
- `AlreadyInstalledRestartRequired`
- `ActionRequired`

Network, authentication, source, and provider failures are errors, not
`UpToDate`. A target already verified in the selected scope is not reinstalled.
Unsupported layouts, ambiguous identity, or unsafe state produce
`ActionRequired` or a terminating structured error as appropriate.

Plans contain no credential, secure string, authorization header, token,
credential reference content, or credential fingerprint.

## Version and release selection

PMU preserves complete version identity:

```text
Numeric version + prerelease label = complete version
```

The manifest, not the numeric directory name, is authoritative for an installed
full version. For example, `2.0.0-preview.1`, `2.0.0-preview.2`, and `2.0.0`
can all occupy `<root>/<ModuleName>/2.0.0/`.

Selection rules are:

1. Resolve releases only from the one explicit repository.
2. Apply the optional provider-supported version range.
3. `Stable` excludes prereleases.
4. `IncludePrerelease` considers stable and prerelease releases together.
5. Select the greatest eligible complete version.
6. The candidate must be newer than both the active version and the verified
   installed version in the requested scope. PMU does not implicitly downgrade
   either state.
7. A newer release appearing after planning does not change the approved target.
8. An unavailable approved target fails; PMU does not substitute latest or
   another repository.
9. Distinct prerelease labels are never normalized into one identity.

Comparison must preserve PowerShell manifest numeric versions with up to four
components. Numeric components are compared as `System.Version` values.
When numeric components are equal, prerelease identifiers use semantic
prerelease ordering and stable sorts after prerelease. Implementation must not
blindly cast a nonzero four-component version to `System.Management.Automation.SemanticVersion`.
Unsupported provider/version forms fail explicitly.

## Credential abstraction and repository authentication

PMU supports two credential paths:

1. An optional direct `PSCredential` supplied independently to each public
   command and passed only to the corresponding PSResourceGet operation.
2. Authentication already configured on the registered PSResourceGet
   repository, including supported `CredentialInfo` or Azure Artifacts
   credential-provider behavior.

PMU does not read `ADO_PAT`, Gerber secrets, arbitrary environment credentials,
or consumer configuration directly. A consumer may construct a `PSCredential`
through its own approved secret abstraction and pass it to PMU.

PMU must not:

- persist credentials in a plan, result, journal, lock file, log, transcript,
  test output, or diagnostic attachment
- put credentials in a URL
- emit provider diagnostics that contain credential material
- install a credential provider, create a vault, persist a consumer repository, or
  change persistent repository trust

The G-4A2-FIX1 qualification proved authenticated discovery and
`Save-PSResource` against a project-scoped Azure Artifacts NuGet v3 feed with
PSResourceGet 1.2.0 and an in-memory credential. That endpoint is evidence, not
a PMU default and must never be hardcoded.

### Repository and authentication architecture clarification

Repository configuration belongs to the caller. PMU has no persistent consumer,
repository-configuration, credential, or authentication-mapping database.
All repositories use one PSResourceGet integration based on protocol
capabilities and explicit source identity, not vendor dispatch.

PSResourceGet 1.2.0 inspection and execution establish that Find, Save, and
Install accept registered names, not arbitrary URI parameters. A URI passed as
a repository name was rejected with `RepositoryNameIsNotResolved`. On the
development macOS host the store is
`LocalApplicationData/PSResourceGet/PSResourceRepository.xml`; changing HOME
does not establish registration isolation.

URI selection reuses one unique existing consumer registration and rejects
ambiguity. When none exists, PMU creates a collision-resistant owned name and
never overwrites, repoints, or changes the trust of another registration.
Provider-inferred API identity comes from native registration `-PassThru`,
not vendor dispatch or guessed URI patterns, and is durably bound before use.
Credentials are supplied to operations, never to registration metadata.

Cooperating PMU processes serialize registration changes separately from target
installation locks. Coordination and flushed nonsecret ownership receipts live
under native LocalApplicationData `PSModuleUpdate/RepositoryTransport`,
independently of child HOME. Receipts contain operation/process identity and an
endpoint hash, not raw repository URLs or authentication mappings.

Normal cleanup verifies exact ownership and configuration. Later operations
can reap a matching fully bound dead-owner registration. Termination between
registration and atomic API binding deliberately fails closed and may require
manual intervention; no automatic recovery of that window is claimed. These
locks do not coordinate unrelated external registry writers. See
[recovery guidance](RECOVERY.md).

The plan stays bound to the caller's endpoint/API while fresh temporary names
are acquired separately for discovery and approved installation. Install
`-WhatIf` creates no registration. This narrow transport exception does not
authorize persistent consumer repository configuration or source fallback.

Qualification scenarios are:

- PSGallery: public module discovery, prereleases, exact acquisition, isolated
  installation, and verification.
- NuGet.org: public NuGet v3 discovery and acquisition; general .NET packages
  lacking a valid PowerShell module must be rejected before mutation.
- Private Azure Artifacts: caller-supplied credentials, discovery, exact
  acquisition, isolated installation, prerelease progression, and verification.
  The historical endpoint is evidence, never a built-in configuration.
- Nexus: expected compatibility through a PSResourceGet-supported NuGet v3
  endpoint and authentication configuration, with no vendor-specific adapter.
  No live Nexus qualification is implied.

Live execution, mocked contracts, and unavailable credentials/packages are
reported separately. Provider limitations never justify a custom NuGet client,
weaker module validation, or implicit repository fallback.

## Installation workflow

After `ShouldProcess` approval, `Install-PSModuleUpdate` performs:

1. Acquire the OS-level exclusive lock keyed by module name, scope, and
   canonical destination root.
2. Revalidate the plan, active identity, selected installed state, repository,
   provider, destination, and exact target.
3. Detect and safely complete or fail unfinished recovery for the same lock
   identity.
4. Save the exact target from the exact repository into PMU-controlled staging
   with `Save-PSResource`.
5. Validate the staged package without importing or executing it.
6. If no target numeric directory exists, use the normal exact
   `Install-PSResource` path.
7. If the target numeric directory exists with a different complete version,
   use Strategy C.
8. Verify the resulting manifest, scope, discoverability, and complete file
   tree.
9. Return a structured result only after verification.

### Strategy C replacement

For a same-numeric-base collision:

1. Validate staged name, numeric version, prerelease, complete version, GUID,
   structure, extraction integrity, and available source metadata.
2. Create and verify a backup outside the Modules tree.
3. Durably create the recovery journal without claiming the backup exists
   before it is verified.
4. Transition the journal to `BackupReady`, then `ReplacementInProgress`.
5. Run exact `Install-PSResource -Reinstall` for this collision only.
6. Transition to `Verification`.
7. Verify installed identity and compare the installed tree with staging.
8. On success, mark `Completed` before removing temporary data.
9. On exception or mismatch, restore and verify the backup.
10. Preserve the journal and recoverable evidence if rollback cannot be
    confirmed.

`-Reinstall` is an internal provider detail. It is not used for a normal
side-by-side numeric-version install, an already-correct target, or an identity
whose GUID does not match policy.

## Locking, journal, and recovery

The lock is an exclusive OS file handle, not a lock-file existence test. The
lock file is outside the module installation tree in a PMU-controlled,
scope-appropriate data directory. Acquisition has a bounded timeout and emits
`PMU.LockTimeout` on failure. The OS releases ownership after process
termination; the file may remain.

The lock covers revalidation, recovery, staging, backup, journal transitions,
replacement, verification, rollback, and completion. A second cooperating PMU
process must revalidate after acquiring the lock and return `AlreadyInstalled`
when the first process already completed the target.

Journal states are:

- `Preparation`
- `BackupReady`
- `ReplacementInProgress`
- `Verification`
- `Completed`
- `RecoveryRequired`
- `RecoveryCompleted`

The journal stores only non-secret identity, scope, canonical root, previous and
target complete versions, expected GUID, validated PMU-controlled staging and
backup paths, state, and recovery status. Durable updates use write-flush and
atomic replacement where supported. PMU makes no stronger crash-durability
claim than the implementation and platform evidence establish.

Journal paths are untrusted input on a later run. PMU must normalize and verify
ownership, expected roots, module identity, version directory, and symbolic-link
behavior before reading, restoring, or deleting anything. Unsafe recovery stops
with `PMU.RecoveryRequired` or `PMU.RecoveryFailed`.

Recovery guarantees are best effort:

- safe abort before mutation
- rollback after recoverable exceptions or verification failure
- detection of interrupted replacement
- next-run repair when a valid backup survives

PMU does not claim atomic installation, guaranteed power-loss survival,
recovery when both installed data and backup are damaged, or protection from
non-cooperating package managers.

## Verification

Provider success is never sufficient. PMU verifies:

- module name
- numeric version
- prerelease label and complete version
- manifest GUID
- selected scope and canonical destination root
- actual manifest path
- repository/source metadata where independently available
- module discoverability
- installed file integrity

The tree comparison is deterministic and detects missing, unexpected, modified,
or partially copied files. Provider-generated `PSGetModuleInfo.xml` is the
initial documented intentional difference between staged and installed trees.
Any further exclusion requires evidence, documentation, and tests; arbitrary
exclusion patterns are forbidden.

## Result contract

`Install-PSModuleUpdate` returns one
`PSModuleUpdate.UpdateResult` object with:

- `SchemaVersion`
- `Outcome`: `Installed`, `AlreadyInstalled`, `Cancelled`, or `WhatIf`
- `ModuleName`, `ModuleGuid`, `RepositoryName`, `RepositoryUri`, `Scope`
- `ActiveVersion`
- `InstalledVersion`
- `TargetVersion`
- `InstalledPath`
- `VerificationStatus`
- `RestartRequired`
- non-secret dependency observations
- `RecoveryStatus`
- safe `RecoveryGuidance`

`ActiveVersion` is captured from the loaded module before mutation.
`InstalledVersion` comes from the verified manifest after the operation.
`TargetVersion` is the exact planned full version.

`RestartRequired` is true when the current process has the module loaded and
the operation changed files belonging to that loaded installation, including a
same-full-version repair. It is not calculated only by comparing version text.
PMU does not remove, force-import, or hot-reload the module.

## Error contract

Failures are terminating `ErrorRecord` instances with stable identifiers,
appropriate categories, safe target objects, actionable recovery guidance, and
provider details only after redaction.

| Area | Stable identifiers |
| --- | --- |
| Request and plan | `PMU.InvalidRequest`, `PMU.InvalidPlan`, `PMU.PlanStale` |
| Identity and layout | `PMU.ModuleIdentityMismatch`, `PMU.GuidMismatch`, `PMU.UnsupportedInstallation` |
| Provider | `PMU.ProviderUnavailable`, `PMU.ProviderIncompatible`, `PMU.UnsupportedProviderBehavior` |
| Repository and discovery | `PMU.RepositoryUnavailable`, `PMU.RepositoryChanged`, `PMU.RepositoryTrustRequired`, `PMU.DiscoveryFailed`, `PMU.PackageNotFound` |
| Access and consent | `PMU.AuthenticationFailed`, `PMU.PermissionDenied`, `PMU.LicenseAcceptanceRequired` |
| Concurrency and state | `PMU.LockTimeout`, `PMU.InstalledStateChanged` |
| Installation | `PMU.InstallationFailed`, `PMU.VerificationFailed` |
| Recovery | `PMU.RecoveryRequired`, `PMU.RecoveryFailed`, `PMU.RollbackFailed` |

`PMU.RepositoryChanged` is used when a repository name resolves to a different
endpoint or relevant registration state than the plan. `PMU.InstalledStateChanged`
is used when the selected installation changed after planning. `PMU.PlanStale`
covers other material plan precondition changes, such as active identity/path,
provider context, or destination policy.

No error may include credential values, authorization headers, encoded
credentials, credential fingerprints, or sensitive authenticated URLs.

## Internal responsibility domains

Implementation should preserve Nova's function-per-file conventions and keep
public commands thin. Likely private domains are:

- `identity`: active/installed manifest and scope resolution
- `version`: complete-version construction and comparison
- `repository`: source resolution and provider discovery
- `planning`: policy validation and plan construction
- `provider`: narrow PSResourceGet command adapters and error translation
- `installation`: orchestration and idempotency
- `staging`: package save and metadata validation
- `locking`: lock identity, path, acquisition, and release
- `recovery`: journal, backup, rollback, and next-run repair
- `verification`: manifest, discovery, and tree integrity
- `shared`: structured errors and small cross-domain value helpers only

The exact file list is established test-first during implementation. No private
domain should become a catch-all workflow context or expose provider quirks to
the public commands.

## Qualification boundary

Historical executable evidence covers macOS PowerShell 7.6.6 and PSResourceGet
1.2.0 for CurrentUser installation, same-base replacement mechanics, locking,
selected rollback paths, and private-feed discovery/save. The following remain
unverified until Phase 6 qualification:

- PowerShell 7.4 execution
- Windows and Linux behavior
- successful AllUsers installation and replacement
- real Windows loaded-file replacement behavior
- hard-kill journal recovery end to end
- two real cooperating replacement processes
- private-feed installation, prerelease, and dependency behavior
- later PSResourceGet versions

These gaps do not reduce the required implementation scope and must not be
described as passed.

# PSModuleUpdate decisions

## Status legend

- **DECIDED**: approved for G-4A3 implementation.
- **SUPERSEDED**: historical G-4A1/G-4A2 position replaced by a later approved
  finding.
- **QUALIFICATION GAP**: implementation is required, but executable support
  evidence is incomplete.
- **ACCEPTED / CLOSED**: owner-approved completed scope; outstanding
  qualification and accepted risks remain explicitly recorded.
- **PROPOSED** testing architecture: not approved or implemented merely because
  it is documented in the strategy.

## D-001 — Independent module ownership (DECIDED)

PSModuleUpdate is an independent, shared PowerShell module with its own public API,
source, tests, help, packaging, versioning, and releases. Gerber is a consumer,
not a runtime dependency or code owner. PMU production code must not depend on
Gerber paths, commands, types, configuration, secrets, or terminal UI.
NovaModuleTools may remain development tooling but is not a PMU runtime
dependency.

Consumers use one normally installed PMU module rather than embedding copies.
An installed target need not be the caller, be loaded, declare PMU in
`RequiredModules`, or contain PMU-specific code. Consumer-specific discovery,
configuration, scheduling, and UI remain consumer responsibilities.

## D-002 — Standard provider foundation (DECIDED)

PMU uses `Microsoft.PowerShell.PSResourceGet` rather than implementing feed
transport, package resolution, or Azure authentication. Version 1.2.0 is the
qualified behavioral baseline. Compatible later stable 1.x versions require
explicit matrix evidence; PMU never silently switches provider versions or
falls back to PowerShellGet.

## D-003 — Two-command public surface (DECIDED)

The initial public API contains only:

- `Get-PSModuleUpdate`
- `Install-PSModuleUpdate`

Planning and mutation remain separate. There is no registration API, callback
framework, global consumer inventory, provider SDK, background scheduler, or
public repair command in the initial contract.

## D-004 — Exact public parameters (DECIDED)

`Get-PSModuleUpdate` accepts an installed target and mutually exclusive
registered-name or explicit-URI repository parameter sets:

- mandatory scalar `[PSModuleInfo] $Module`
- mandatory literal `[string] $Repository` in the registered-name set
- mandatory `[Uri] $RepositoryUri` in the explicit-URI set, subject to the
  provider transport safety decision D-021
- optional validated `[hashtable] $Policy`
- optional `[PSCredential] $Credential`

`Install-PSModuleUpdate` has one `ByUpdatePlan` parameter set:

- mandatory pipeline-by-value `$Update`, validated as a live schema-1
  `PSModuleUpdate.UpdatePlan`
- optional `[PSCredential] $Credential`
- optional `[switch] $AcceptLicense`
- optional `[switch] $TrustRepository`
- native `-WhatIf` and `-Confirm` through `SupportsShouldProcess`

Install does not expose target-changing or force parameters. Persisted and
deserialized plans are outside the initial contract.

## D-005 — Policy schema and defaults (DECIDED)

The policy contains only `Channel`, `Scope`, `ExpectedRepositoryUri`, and
`VersionRange`. Defaults are `Stable`, `CurrentUser`, null, and null
respectively. Unknown keys and invalid types fail. `IncludePrerelease` means
stable plus prerelease, not prerelease-only. A range uses provider-supported
NuGet syntax.

## D-006 — Both installation scopes (DECIDED; supersedes G-4A1)

CurrentUser and AllUsers are both required. PMU resolves the selected scope's
actual provider destination, never changes scope, never falls back to
CurrentUser, and never self-elevates. The selected installation must already
exist with matching module identity; PMU does not create a new copy in another
scope as a self-update side effect.

Mixed-scope installations are represented explicitly. Active module resolution
and selected-scope installation are separate facts. PMU never modifies the
other scope merely because its version differs.

The earlier G-4A1 CurrentUser-only and mixed-scope rejection is
**SUPERSEDED**.

## D-007 — Full version identity and selection (DECIDED)

Complete identity consists of numeric manifest version plus prerelease label.
The manifest is authoritative; a numeric directory name is insufficient.

Stable policy excludes prereleases. IncludePrerelease considers both. PMU
selects the greatest eligible release from the exact repository and range, and
never downgrades the active or selected installed state. An approved plan binds
one exact target; later publication does not change it.

Four-component PowerShell versions are preserved and compared without blindly
casting them to `SemanticVersion`. Unsupported forms fail explicitly.

## D-008 — Same-base progression through Strategy C (DECIDED; supersedes G-4A2)

Normal release progression must support:

```text
2.0.0-preview.1 -> 2.0.0-preview.2 -> 2.0.0-preview.3 -> 2.0.0
```

Same-numeric-base collisions are not rejected as a class. PMU stages with
`Save-PSResource`, validates identity, creates a recoverable backup and journal,
uses exact `Install-PSResource -Reinstall` only for the collision, verifies the
manifest and tree, and rolls back on recoverable failure.

The earlier G-4A1/G-4A2 fail-closed collision policy and blanket ban on
`-Reinstall` are **SUPERSEDED**. Raw `-Reinstall` is not exposed publicly or
used indiscriminately.

## D-009 — GUID continuity (DECIDED)

Name equality is not sufficient identity. When an installation already exists,
the target manifest GUID must match the planned and installed GUID. An
unexpected GUID fails before destructive mutation with a stable identity error.
PSResourceGet's willingness to replace a different GUID is not accepted as PMU
policy.

## D-010 — Persistent recovery and best-effort rollback (DECIDED; supersedes G-4A1)

PMU creates a persistent, non-secret recovery journal before destructive
replacement and keeps a verified backup outside the Modules tree. It restores
and verifies the prior tree after installation or verification failure where
possible. On the next run, recovery for the same lock identity is completed
before a new update proceeds.

The earlier "no automatic rollback" and short-lived-lock-only model is
**SUPERSEDED**.

PMU does not claim atomicity, guaranteed power-loss survival, or recovery when
the installation and backup are both damaged.

## D-011 — OS-level cooperative locking (DECIDED)

Mutation uses a bounded OS-level exclusive file handle keyed by module name,
scope, and canonical installation root. Lock-file existence does not establish
ownership. The lock covers revalidation through recovery and completion.
Cooperation does not protect against direct provider use, other package
managers, or manual filesystem changes.

The historical `PMU.UpdateInProgress` concept is replaced in the current
contract by `PMU.LockTimeout` plus post-acquisition revalidation.

## D-012 — Full installed-tree verification (DECIDED)

Provider return status, directory existence, manifest existence, version text,
or file count alone cannot establish success. PMU verifies complete manifest
identity, selected scope, discoverability, and deterministic tree integrity.
The initial intentional tree difference is provider-generated
`PSGetModuleInfo.xml`; further exclusions require evidence and tests.

## D-013 — Active, installed, and target state (DECIDED)

Results separately report `ActiveVersion`, `InstalledVersion`,
`TargetVersion`, and `RestartRequired`. Active state is captured before
mutation; installed state is read from the verified disk manifest.

Restart is required whenever loaded files were replaced, including a
same-full-version repair. PMU never removes and reimports a running consumer.
Gerber Core hot reload is specifically forbidden by Gerber integration policy,
while PMU remains consumer-neutral.

## D-014 — Credential abstraction (DECIDED)

PMU accepts an optional per-call `PSCredential` or relies on authentication
already configured for the registered PSResourceGet repository. Direct
credentials must be supplied independently to plan and install calls. PMU never
persists, fingerprints, logs, or reconstructs credentials.

PMU does not read `ADO_PAT` or a consumer's secret store. Consumers may obtain a
credential through their own abstraction and pass it in memory. PMU does not
install credential providers or configure vaults. Caller-approved ephemeral
repository registration for URI transport is governed by D-021.

## D-015 — Consent separation (DECIDED)

`Install-PSModuleUpdate` uses native `ShouldProcess` with high confirm impact and
no custom prompt. Install consent does not imply repository trust, license
acceptance, credential availability, provider setup, or elevation.

`-WhatIf` is read-only and performs no lock, staging, repair, journal, or
install mutation. Recovery after approval is restricted to a validated
unfinished PMU operation for the same module/scope/root; if recovery changes
plan preconditions, PMU requires a fresh plan.

## D-016 — Stable structured errors (DECIDED)

PMU uses terminating `ErrorRecord` objects and the identifiers listed in
`ARCHITECTURE.md`. The revised contract adds explicit permission, lock,
installed-state, recovery, rollback, package-not-found, GUID, and unsupported
provider behavior errors while preserving the G-4A1 input, provider,
repository, discovery, installation, and verification families.

Errors retain actionable non-secret context and redact credential-bearing
provider details.

## D-017 — No automatic dependency bootstrap or elevation (DECIDED)

Missing or incompatible PMU/provider/authentication setup produces actionable
guidance. PMU does not install or update itself, install its provider,
automatically trust a repository, request elevation, or silently retry a
destructive operation.

## D-018 — Qualification claims remain evidence-bound (DECIDED)

Implementation targets PowerShell 7.4+ on Windows, macOS, and Linux, but each
claim is limited to its recorded artifact, runtime, provider, and scenario.
Disposable CurrentUser live batches on macOS with PowerShell 7.6.6 and
PSResourceGet 1.2.0 have verified public PSGallery and authenticated private
Azure stable updates, and NuGet.org acquisition with nonmodule rejection.
Their reports identify the actual module SHA256; results never qualify a
different artifact by implication. Final-artifact qualification also verified
actual unregistered private HTTPS-V3 discovery and installation, with separate
credentials, unchanged WhatIf, and complete registration/receipt cleanup.

Successful real AllUsers mutation, Windows, Linux, PowerShell 7.4, and live
Nexus remain **QUALIFICATION GAPS**. Private Azure prerelease progression is
**NOT TESTED** unless an authorized live progression is recorded. Local
provider progression and process/recovery fixtures are separate evidence, not
substitutes for a live private-feed test. Documentation and release claims must
distinguish implemented behavior from qualified behavior.

## D-019 — Nova scaffold ownership (DECIDED)

`project.json` is the source of build, manifest, package, and test metadata.
Nova generates module artifacts under `dist/`; PMU source must not hand-author a
root module or manifest. Public commands remain thin, private helpers are
domain-owned and function-per-file, and tests mirror source ownership.

The local `run.ps1` uses the repository analyzer wrapper and Nova commands in
the documented order, not an alternative build system.

## D-020 — Protocol-based repository integration (DECIDED)

PSGallery, NuGet.org, compatible private Azure Artifacts feeds, and compatible
Nexus NuGet v3 endpoints use one generic PSResourceGet adapter. No vendor-specific
package-management, authentication framework, fallback source, or embedded
consumer updater is introduced. Repository identity and credentials are
caller-owned and independently supplied for discovery and installation.

NuGet.org transport compatibility does not make general NuGet packages
PowerShell modules. Packages lacking the required manifest, identity, and
structure are rejected without weakening installation validation.

## D-021 — Explicit repository URI contract (DECIDED; implemented)

The architecture clarification adds mutually exclusive `Repository` and
`RepositoryUri` inputs. Credentials remain optional, with no authentication
Boolean. The exact source is retained in the plan and revalidated before
acquisition and installation.

PSResourceGet 1.2.0 requires registered names for Find, Save, and Install.
PMU reuses a unique consumer registration or creates an operation-owned
temporary registration under a separate native per-user registry lock.
Flushed ownership receipts bind operation/process identity, endpoint hash, and
the provider-returned API configuration. No `Force`, existing-registration
mutation, persistent trust change, or credential-bearing repository
configuration is permitted.

This is an additive clarification of D-004 and a narrow exception to the
original no-registration-write planning policy. Normal and fully bound stale
cleanup validate exact ownership; the registration-to-API-binding crash window
fails closed and can require manual intervention. That boundary and
non-cooperating writer limitations are explicit, not atomic-cleanup claims.

## D-022 — G-4A3 functional closure and quality acceptance (ACCEPTED / CLOSED)

On 2026-10-23 the owner accepted G-4A3 as functionally complete within the
qualified macOS PowerShell 7.6.6 / PSResourceGet 1.2.0 scope.
[G4A3_CLOSURE.md](G4A3_CLOSURE.md) preserves the final reports, artifact
identity, 287 unit/five integration passes and their skips, four separate live
runs, packaging evidence, and the outstanding platform/provider gaps.

The owner explicitly accepts the recorded CodeScene 9.68/five-parameter public
command finding and the eight manual SIG findings. Status is **risk accepted**,
not an assertion that all quality thresholds passed. Scores are indicators, not
absolute G-4A3 acceptance requirements. Do not alter the approved public API,
split coherent functions, or rewrite branches merely to satisfy parameter,
line-count, or complexity targets. Test/support and production responsibilities
can have legitimately different complexity characteristics.

This is a bounded acceptance of the existing implementation, not a blanket
waiver for future defects or a rewrite of shared quality instructions. No
implementation/tests/refactoring are authorized by closure. The resolved
pre-initial-commit Git-hook HEAD issue requires no Nova Init change.

## D-023 — Separate cross-platform qualification design (PROPOSED)

The [cross-platform strategy](CROSS_PLATFORM_TESTING.md),
[technology comparison](TEST_TECHNOLOGY_COMPARISON.md),
[matrix](TEST_MATRIX.md), and [roadmap](TEST_IMPLEMENTATION_ROADMAP.md)
propose reusable infrastructure for PMU, Gerber Core, and future modules.
They do not qualify any new platform or authorize pipeline/container/VM
implementation. Ownership, CI provider, architecture coverage, privileged
environments, and credential infrastructure require owner approval.

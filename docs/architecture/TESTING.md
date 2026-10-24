# Testing and qualification

## Local entrypoints

Use the installed NovaModuleTools build and test commands. PMU's build is
defined by `project.json`; the module root and manifest are generated under
`dist/PSModuleUpdate/`.

```powershell
pwsh -NoLogo -NoProfile -File ./run.ps1
```

GitHub Actions (`.github/workflows/ci.yml`) runs the same Nova build, unit and
integration phases per platform lane through
`./scripts/build/ci/Invoke-PlatformLane.ps1 -LaneId <lane-id>`; see
[G4A4/PHASE1_IMPLEMENTATION.md](G4A4/PHASE1_IMPLEMENTATION.md).

The local wrapper runs, in order:

1. `scripts/build/Invoke-ScriptAnalyzerCI.ps1`
2. `Invoke-NovaBuild`
3. `Invoke-NovaTest`
4. `Test-NovaBuild`
5. `scripts/build/Test-TextFileFormatting.ps1`

Before those checks, the wrapper imports an installed Pester version in Nova's
supported range, 5.7.1 through 5.10.0. This prevents analyzer tooling from
autoloading Pester 6 and causing an assembly collision when Nova selects Pester
5. No dependency is installed or upgraded by the wrapper.

A failed prerequisite stops the pipeline. The analyzer covers authored source,
tests, helpers, and root PowerShell scripts, not generated `dist/` or
`artifacts/` files. Its settings retain default rules and fail on Error or
Warning diagnostics, except the approved `PSAvoidUsingWriteHost` exclusion in
the shared settings for intentional host output.

Use `Invoke-NovaTest -TagFilter BuildTooling` for the quality-entrypoint tests.
Use `Invoke-NovaTest` for unit validation and `Test-NovaBuild` for the separate
built-module integration flow. Do not substitute a direct Pester invocation:
Nova owns discovery, supported Pester selection, StrictMode, and result output.

Nova writes unit results to `artifacts/UnitTestResults.xml`. Unit coverage is
enabled in `project.json`, targets the authored source paths, and writes JaCoCo
to `artifacts/coverage.xml` with the existing 90 percent target. Integration
tests remain a separate phase and do not generate the unit coverage report.
The test/coverage workflow runs `Invoke-NovaTest` before `Test-NovaBuild` and
uploads that report for CodeScene and Codecov; test counts alone do not
establish a measured coverage percentage.

### Phase 1 skips and platform evidence

The [Phase 1 skipped-test inventory](G4A4/PHASE1_IMPLEMENTATION.md#skipped-test-inventory)
identifies the initial macOS unit skip (native Windows ACL metadata) and all
three integration skips (explicitly opted-out live repository scenarios),
along with additional Windows/Linux conditional skips. An expected skip is
not a passing test. The ordinary Phase 1 gate must not enable live credentials
or silently accept additional unidentified skips.

Nova's summary-only NUnit XML has no per-test identities or skip reasons.
Counts alone cannot prove that a particular permitted test was skipped:
qualification needs matching detailed execution evidence, nonempty unit and
integration execution, and consistent result counts.

The hardened lane retains `unit-details.json` and `integration-details.json`
alongside each summary XML and its Detailed/Ansi execution log. Exact
file/name/OS skips are allowlisted in `scripts/build/ci/CiSkipPolicy.json`;
an unknown skip, missing detail, mismatched count or inconclusive result
fails qualification. The gate revalidates the retained evidence rather than
trusting manifest counts alone. Nova's summary XML remains unchanged.

The lane entrypoint provisions dependencies with `Save-Module` into a newly
owned disposable directory, restricts child `PSModulePath` to that directory
and the selected PowerShell's built-ins, and removes the owned directory in
cleanup. It does not install into the developer's CurrentUser or AllUsers
module paths. Do not uninstall an existing module to reproduce CI.
An optional `-ModuleRoot` must be a directory created by the CI dependency
provisioner; the lane consumes and removes it. The ordinary `run.ps1` still
uses existing dependencies and does not install anything.

The workflow and each phase invoke the provisioned absolute `pwsh` path.
Runtime witnesses inside Nova's unit/integration runspaces verify the actual
selected version and Pester 5.7.1; `PATH` ordering is not sufficient evidence.
Local macOS ARM64 hardening passed under 7.4.21 and stable 7.6.8, each with
413 unit passes/one expected skip and six integration passes/three expected
skips. The repository wrapper, 135 BuildTooling tests and actionlint passed;
before/after dependency and repository-store fingerprints were unchanged.

GitHub's current standard public-runner reference explicitly maps `macos-15`
to ARM64; this documented mapping does not replace runtime validation or the
real six-lane GitHub execution. The first hosted run passed both Mac lanes but
failed Windows/Linux unit tests; see the [hosted result and fixes](G4A4/PHASE1_IMPLEMENTATION.md#first-hosted-run-and-platform-fixes-2026-10-23).
The complete matrix remains unqualified until the fixes pass on GitHub.
No Windows/Linux qualification is inferred from local macOS results.

## Test ownership

Unit tests mirror source paths under `tests/public/` and
`tests/private/<domain>/`. They dot-source the owning source and required real
collaborators, mocking external effects where appropriate. Shared fixtures
belong under `tests/TestHelpers/`.

Public `.Integration.Tests.ps1` files may import the generated module to prove
exports, packaging, and command wiring. Cross-cutting tests exercise complete
replacement, recovery, or locking contracts; they are not substitutes for
focused unit assertions.

## Isolation requirements

All mutation tests must use disposable module names and test-owned roots.
Normal test runs must not write to real AllUsers locations or request elevation.
Mocks can prove AllUsers routing and permission errors but do not qualify a real
elevated installation.

Provider qualification must pin PSResourceGet 1.2.0. Isolate CurrentUser
installation in a child process with a disposable HOME where supported, and
verify the provider's actual destination before installation. Changing
PSModulePath alone does not redirect provider installation.

On macOS, changing HOME does not necessarily isolate repository registrations:
PSResourceGet may use the real user's application-data directory. Use only
uniquely named test-owned registrations, remove only those registrations in
cleanup, and compare the pre-existing registration state before and afterward.
Never restore an entire registration file over possible concurrent changes.

Linux has a different native-store rule: `LocalApplicationData` follows
`XDG_DATA_HOME`, or the child HOME's `.local/share` when that variable is unset.
Two different HOMEs therefore need not share a repository store or transport
lease. Shared-store coordination tests must explicitly select a common native
store and independently verify the provider's actual location. This does not
change the production rule that cooperating operations on the same store must
share their transport lease.

Use child processes for exclusive-lock contention, holder termination,
loaded-module behavior, and interrupted replacement. Preserve usable backup and
journal evidence when a failure is under investigation. Credentials and raw
authenticated provider errors must not enter test reports.

## Required behavior matrix

Qualification covers read-only planning, exact source/target selection,
semantic prerelease ordering, scope isolation, stale-plan rejection, consent
and WhatIf, staged identity validation, selective same-base replacement,
full-tree verification, rollback, persistent next-run recovery, concurrent
cooperating updates, and active/installed/target/restart reporting.

Distinguish tests written, tests executed, tests passed, skipped cases, and
unavailable environments. A mocked provider or disposable filesystem test does
not prove real provider installation. A real provider test on one platform does
not establish cross-platform compatibility.

## Platform and provider qualification

G-4A3 is functionally complete and accepted within the final-artifact macOS,
PowerShell 7.6.6, and PSResourceGet 1.2.0 evidence. See
[closure](G4A3_CLOSURE.md) for counts, skips, quality acceptance and provenance.
Earlier provider-only evidence is not execution evidence for a different PMU
artifact.

The following require explicit executed qualification:

- PowerShell 7.4 on Windows, macOS, and Linux
- successful authorized AllUsers installation and replacement
- Windows loaded-file replacement behavior
- real-provider process termination, VM restart, and additional-platform
  recovery/races beyond the passed macOS controlled-process fixtures
- private-feed prerelease progression and broader dependencies beyond the
  passed authenticated stable installations
- live Nexus
- later PSResourceGet versions

See [the implementation plan](PLAN.md) for delivery criteria and
[recovery guidance](RECOVERY.md) for the recovery guarantee boundary.
The proposed [cross-platform testing strategy](CROSS_PLATFORM_TESTING.md)
defines a separate qualification phase, environment safety rules, minimum and
extended matrices, and approval decisions. None of that infrastructure is
implemented by the strategy documentation.

## Opt-in live repository checks

The normal suite does not contact live feeds. The qualification launcher uses a
disposable child HOME, asserts the actual provider destination, and compares
existing registration state before and after its owned test registration.
The switches below explicitly authorize those test-owned registry mutations,
not changes to an existing registration or a real installed module.

After a current successful Nova build:

```powershell
$options = @{
    Scenario = 'Gallery'
    ModulePath = './dist/PSModuleUpdate/PSModuleUpdate.psd1'
}
./scripts/qualification/Invoke-RepositoryQualification.ps1 -Options $options -EnableLive -ProviderStoreApproved
```

Use `Scenario = 'NuGet'` for exact NuGet.org acquisition and nonmodule rejection.
For a caller-approved private feed, supply the endpoint and pinned fixture
versions rather than relying on built-in vendor configuration:

```powershell
$options = @{
    Scenario = 'Private'
    ModulePath = './dist/PSModuleUpdate/PSModuleUpdate.psd1'
    RepositoryUri = $repositoryUri
    SeedName = $testModuleName
    SeedVersion = $seedVersion
    TargetVersion = $targetVersion
}
./scripts/qualification/Invoke-RepositoryQualification.ps1 -Options $options -Credential $credential -EnableLive -ProviderStoreApproved
```

The harness can also obtain its caller credential from an inherited `ADO_PAT`;
this is a test-caller convenience, not a PMU production authentication source.
No secret is passed on a process command line or serialized into fixture files.
Each child has a bounded timeout. Never bypass failed cleanup or replace the
real user's entire registration store to make a test pass.

The equivalent Pester integration scenarios have tag `RepositoryLive` and are
enabled only with `PMU_QUALIFICATION_LIVE=1` and
`PMU_QUALIFICATION_STORE_APPROVED=1`. Private execution additionally requires
caller-selected `PMU_QUALIFICATION_PRIVATE_URI`,
`PMU_QUALIFICATION_PRIVATE_MODULE`, `PMU_QUALIFICATION_PRIVATE_SEED`,
`PMU_QUALIFICATION_PRIVATE_TARGET`, and an authorized `ADO_PAT`.
`Test-NovaBuild` rebuilds before those tests; do not run it concurrently with
another build or registration-mutating qualification batch.

Live evidence is recorded under `artifacts/qualification/`. Its module SHA256
identifies the artifact actually exercised; a result for an approved older
artifact is not evidence for concurrently changing source.

### Recorded G-4A3 final-artifact evidence

The final macOS PowerShell 7.6.6 / PSResourceGet 1.2.0 report is
`artifacts/qualification/final-20261023T044229Z/G-4A3-final-live-report.json`.
Historical reports remain preserved separately.

| Scenario | Actual outcome |
| --- | --- |
| PSGallery | ThreadJob 2.0.3 to 2.1.0 installed and verified; 62 Pester prereleases discovered. |
| NuGet.org | Exact NuGet.Versioning 6.12.1 acquired; PMU rejected the nonmodule before installation mutation; two Newtonsoft.Json prereleases discovered. |
| Azure private | HashUtil 1.4.74 to 1.4.75 installed and verified with separately supplied credentials. |
| Unregistered private HTTPS-V3 | Endpoint had zero registrations before PMU planning; temporary Get/Install transport, unchanged WhatIf, verified installation, credential-free objects, and cleanup passed. |

These are four real standalone child-process runs, not additional Pester
integration-test counts. They left zero qualification/native registrations and
zero transport receipts, and preserved unrelated registration snapshots.
Offline native-provider Pester integration separately verified registered-name
then unregistered-file-URI progression through previews, stable, and a
four-component version.

Private Azure prerelease progression remains **NOT TESTED**. HashUtil had no
previews; that does not establish the absence of previews across the feed.
Nexus, Windows/Linux, PowerShell 7.4 execution, real AllUsers writes, and later
provider versions remain separate qualification gaps. Coverage was not
measured. The owner explicitly accepted the remaining CodeScene/SIG findings;
this is recorded risk acceptance, not a claim that all thresholds passed.

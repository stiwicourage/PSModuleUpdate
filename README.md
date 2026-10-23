# PSModuleUpdate

Generic self-update functionality for PowerShell modules.

PSModuleUpdate is a standalone shared module installed through normal
PowerShell module management. Consumers may reference it through
`RequiredModules`; they do not embed copies of its update implementation.
PMU can update another installed module even when that target does not depend
on PMU or contain any PMU-specific code.

## Plan and install an update

PSModuleUpdate separates read-only discovery from an explicitly approved
installation. It targets PowerShell 7.4+ and uses
`Microsoft.PowerShell.PSResourceGet` 1.2.0 as its qualified provider baseline.
It never persistently configures consumer repositories, stores credentials,
elevates privileges, or reloads the updated module.

Pass an installed module object, not just its name. The target need not be the
caller or already loaded:

```powershell
$module = Get-Module -ListAvailable -Name ExampleModule |
    Sort-Object Version -Descending |
    Select-Object -First 1
$update = Get-PSModuleUpdate -Module $module -Repository PSGallery
$update | Select-Object ModuleName, ActiveVersion, InstalledVersion, TargetVersion, Disposition
$update | Install-PSModuleUpdate -WhatIf
```

After reviewing the plan, install it:

```powershell
$update | Install-PSModuleUpdate
```

Installation uses native PowerShell confirmation. For automation,
`-Confirm:$false` suppresses that confirmation only; it does not accept a
license, trust a repository, provide credentials, or grant filesystem access.
Pass `-AcceptLicense` or `-TrustRepository` only when you explicitly approve
those separate requirements. Repository trust is operation-scoped.

### Scope and prereleases

The policy defaults to stable releases in `CurrentUser`. Choose another scope
or include prereleases explicitly:

```powershell
$policy = @{
    Scope = 'AllUsers'
    Channel = 'IncludePrerelease'
}
$update = Get-PSModuleUpdate -Module $module -Repository CompanyModules -Policy $policy
```

PMU updates an existing matching installation in the selected scope. It does
not silently create a copy in another scope or fall back to CurrentUser when
AllUsers is not writable. Run in an appropriately authorized shell when system
permissions are necessary; PMU never requests elevation.

`IncludePrerelease` considers stable and prerelease releases together. Complete
versions use semantic prerelease ordering: `preview.10` follows `preview.2`,
and a stable release follows prereleases with the same numeric base.
Optional policy fields are `ExpectedRepositoryUri` and `VersionRange`.

### Private repositories

Use an already registered PSResourceGet repository. PMU supports its configured
authentication or an in-memory `PSCredential` supplied separately to both calls:

```powershell
$update = Get-PSModuleUpdate -Module $module -Repository CompanyModules -Credential $credential
$update | Install-PSModuleUpdate -Credential $credential
```

To select by endpoint instead of registration name, use the mutually exclusive
`-RepositoryUri` parameter:

```powershell
$update = Get-PSModuleUpdate -Module $module -RepositoryUri $repositoryUri -Credential $credential
$update | Install-PSModuleUpdate -Credential $credential
```

Credentials are optional for both forms. There is no separate authentication
flag. The selected source remains bound to the plan; installation never searches
another repository for a matching module name.

An unregistered URI requires a short-lived PSResourceGet registration because
the provider accepts names, not direct URIs. PMU uses owned random names,
separate per-user coordination, and nonsecret cleanup receipts without
changing existing registrations or trust. Install `-WhatIf` creates no
registration. Interrupted API binding can require manual review; see
[recovery and transport safety](docs/architecture/RECOVERY.md).

Obtain `$credential` through your approved secret-management workflow. PMU
does not read a particular environment variable or install credential providers.
Plans are live in-process objects, not portable authorization records; obtain
a new plan after restarting the shell or changing installation/repository state.

Repository selection is always caller-owned and source-bound. PMU never
searches another feed just because it contains the same package name. PSGallery,
public NuGet v3 repositories such as NuGet.org, and authenticated private
NuGet v3 repositories use the same PSResourceGet integration. General .NET
NuGet packages are not installable PowerShell modules merely because they can
be discovered or downloaded. Nexus is expected to work with compatible NuGet v3
capabilities, but no live Nexus qualification is implied.

## Replacement, recovery, and restart

Same-base transitions such as `2.0.0-preview.1` to `2.0.0-preview.2` and then
`2.0.0` require staged replacement because those versions share a numeric
installation directory. PMU validates the staged identity and GUID, preserves a
verified backup outside the Modules tree, records recovery state, and verifies
the installed file tree. Provider success alone is not proof of installation.

A cooperating PMU process holds an exclusive filesystem lock throughout the
operation. Interrupted replacements are checked on the next approved
installation attempt. Recoverable failures trigger best-effort rollback;
unsafe or unsuccessful recovery stops further installation and preserves
available evidence. This is not an atomic installation or a power-loss
guarantee, and it cannot coordinate unrelated package managers.

Results distinguish the loaded `ActiveVersion`, verified on-disk
`InstalledVersion`, exact `TargetVersion`, and `RestartRequired`. A loaded
module is never automatically removed or re-imported. Restart when the result
requires it, including when loaded files were replaced without changing the
displayed numeric version.

See [recovery guidance](docs/architecture/RECOVERY.md), [architecture](docs/architecture/ARCHITECTURE.md),
[decisions](docs/architecture/DECISIONS.md), and the
[implementation and qualification plan](docs/architecture/PLAN.md) for safety contracts,
limitations, and outstanding qualification. Windows, Linux, PowerShell 7.4,
and successful real AllUsers mutation require their own executed qualification;
the runtime target is not a claim that those environments have been tested.
See [testing and live repository qualification](docs/architecture/TESTING.md) for isolated
PSGallery, NuGet.org, and private-feed checks.

**G-4A3 is functionally complete and accepted within its qualified scope.**
See [closure evidence and accepted quality findings](docs/architecture/G4A3_CLOSURE.md).
Further platform/environment qualification is a separate phase described in
the proposed [cross-platform testing strategy](docs/architecture/CROSS_PLATFORM_TESTING.md);
the strategy does not implement infrastructure or expand tested-platform claims.

## Agentic Copilot workflow

Follow this workflow when working with Copilot in this repository.

1. **Design**
    - Start with `/agent architect`, `.github/agents/architect.agent.md`, and `.github/prompts/design-change.prompt.md` to scope the change before implementation.
2. **Implement**
    - Use `/agent powershell-developer`, `.github/agents/powershell-developer.agent.md`, and `.github/prompts/implement-issue.prompt.md` when the change is already scoped.
    - If the work is mainly about tests or coverage, use `/agent test-engineer`, `.github/agents/test-engineer.agent.md`, and `.github/prompts/improve-test-coverage.prompt.md`.
3. **Review**
    - Use `/agent reviewer`, `.github/agents/reviewer.agent.md`, and `.github/prompts/review-change.prompt.md` before handoff or pull request review.
4. **Prepare release**
    - Use `/agent release-manager`, `.github/agents/release-manager.agent.md`, and `.github/prompts/prepare-release.prompt.md` when preparing the pull request summary and release-facing follow-up.

## Nova project expectations

- Use Nova commands and `project.json` for build, test, package, and release behavior.
- Treat `project.json` `Manifest.PowerShellHostVersion` as the compatibility target for PowerShell code, tests, and examples. If it is `5.1`, do not introduce PowerShell 7.x-only features.
- Keep local quality checks ordered as ScriptAnalyzer first, then `Invoke-NovaBuild`, then `Invoke-NovaTest`, then `Test-NovaBuild` when your project defines both test flows.
- Use `Invoke-NovaTest` for unit validation and `Test-NovaBuild` for build-validation integration runs. Do not validate with direct `Invoke-Pester`, because it can bypass Nova's build/import/StrictMode flow and disagree with later user-visible test runs.
- Keep public command unit coverage in `tests/public/<Command>.Tests.ps1` and keep per-command integration ownership in `tests/public/<Command>.Integration.Tests.ps1` when built-module behavior itself needs validation.
- For destructive or environment-coupled public commands, prefer safe `-WhatIf` integration coverage when that still proves `ShouldProcess` wiring and command behavior.
- If the repository quality loop or `Invoke-ScriptAnalyzerCI.ps1` reports ScriptAnalyzer findings, fix them before review or handoff.
- Follow `.github/instructions/psscriptanalyzer.instructions.md` as the ScriptAnalyzer workflow source of truth. Prefer `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` and the repository quality loop, when present, and use direct `Invoke-ScriptAnalyzer` only for focused local checks that reuse the repo-approved settings.
- Keep one externally called function per file and match the file name to that function. Public files own one command each; private files may keep extra related functions only as same-file top-level support helpers, and PowerShell functions must not declare nested functions inside their bodies.
- Follow `.github/instructions/code-quality-matrix.instructions.md` as the best-effort maintainability guidance for source/helper scripts, and `.github/instructions/testing-policy.instructions.md` for test design. These guide agents and reviewers in this generated project.
- Generate valid PlatyPS help under `docs/PSModuleUpdate/en-US/` whenever command help changes. Use `New-MarkdownCommandHelp`, `Update-MarkdownCommandHelp`, and `Test-MarkdownCommandHelp` instead of hand-writing the help structure.
- Every new public entry point must add its matching help file in the same change.
- Make every changed or generated text file end immediately after exactly one newline terminator; do not leave a blank spacer line at the bottom. Use `pwsh -NoLogo -NoProfile -File ./scripts/build/Test-TextFileFormatting.ps1` for a focused check, and keep `tests/TextFileFormatting.Tests.ps1` passing when the project uses Pester.
- Do not exclude or suppress PSScriptAnalyzer rules; fix analyzer findings in the code.
- Do not hand-create module `.psm1` or module `.psd1` files in source; Nova generates them under `dist/PSModuleUpdate/`.
- Add PlatyPS-compatible help under `docs/PSModuleUpdate/en-US/` when public commands or public classes change.
- Keep tests mirrored to source files: every new or changed `src/**/*.ps1` file should have one focused `.Tests.ps1` file, for example `src/private/foo/Get-Thing.ps1` -> `tests/private/foo/Get-Thing.Tests.ps1`.
- For public commands, the mirrored unit-test owner is `tests/public/<Command>.Tests.ps1`; add `tests/public/<Command>.Integration.Tests.ps1` when the built public command behavior itself needs integration coverage.
- Put shared test setup in `tests/TestHelpers/` or a test-support file instead of grouping unrelated source coverage into broad catch-all tests.

## Start here

Use this repository as the starting point for your module.

- Review `README.md`, `CONTRIBUTING.md`, and `.github/copilot-instructions.md`.
- Use `Invoke-NovaBuild` / `% nova build` to produce the first local build.
- Use `Invoke-NovaTest` / `% nova test` for unit tests and `Test-NovaBuild` / `% nova test --build` for build-validation integration tests before opening a pull request.

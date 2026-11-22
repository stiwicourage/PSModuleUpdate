# Release notes

This file summarizes public cmdlet, CLI, configuration, and migration changes for PSModuleUpdate.
`CHANGELOG.md` remains the exhaustive record of all changes in each release. **UNRELEASED** changes will be included in the next **stable** release!

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [0.3.0] - 2026-11-16

### Added

- Use `Install-PSModuleUpdate -ReplaceUnmanagedInstallation` to explicitly
  update a manually copied installation with no root `PSGetModuleInfo.xml`.
  The default remains fail-closed. Unreadable or mismatching existing metadata
  is never bypassed, and exact-target verification and recovery remain enabled.
- Inspect an approved exact target with `Get-PSModuleUpdateTargetManifest`
  before deciding to install. Its `Manifest` hashtable includes full
  PrivateData without loading or running the target. Installation rejects
  manifest content changed after inspection, even under the same version;
  obtain a fresh plan to approve different content.
- Plan module updates with `Get-PSModuleUpdate`, preview them with
  `Install-PSModuleUpdate -WhatIf`, and explicitly approve installation.
- Update independent installed modules without embedding PMU or requiring a PMU
  dependency in each target. Choose a repository name or URI and supply optional
  credentials separately for planning and installation.
- Select CurrentUser or AllUsers and stable or prerelease releases through the
  update policy. PMU never silently changes scope or elevates privileges.
- Same-base prerelease replacement uses staged verification and best-effort
  recovery. Results distinguish active, installed, and target versions and
  indicate when a shell restart is required.
- PowerShell 7.4+ is the runtime target; unexecuted platform, provider, and
  successful AllUsers qualification remain documented limits.

### Changed

- Contributor tests, security checks, and publishing now use shared
  `powershell-ci` workflows with the same caller convention as the reference
  modules, including weekly grouped dependency updates. Local `run.ps1` and the six-platform/runtime CI
  lanes remain in place. Stable publishing moves both changelog and release
  notes. PSModuleUpdate references temporarily use `develop` during qualification;
  public module commands and installation behavior are unchanged.
- Managed-module updates use native `Update-Module` without Force or an
  automatic install fallback. The unmanaged opt-in uses exact-version native
  `Install-Module`, with Force only for a target-directory collision.
  Exact target/source, consent and restart requirements stay
  in effect. Prerelease updates use native-compatible labels such as `preview03`;
  dotted labels such as `preview.3` are not supported by the native installer.
  Temporary repository setup also handles automatically registered defaults
  without changing your repository settings.

### Fixed

- Platform CI uses the already-qualified native PowerShellGet 2.2.5 in its
  owned runtimes; public commands and ambient installations are unchanged.
- Contributor tests for Windows installation roots no longer fail on Linux
  runners without a Documents folder.
- Contributor CI no longer rejects the required provider merely because
  PowerShell also bundles a newer PSResourceGet version.
- Update checks now report `PMU.PackageNotFound` when the selected repository
  has no matching package. No update plan is returned, and PMU does not try
  another feed or expose raw provider diagnostics.
- PMU now declares its qualified PSResourceGet 1.2.0 runtime dependency.
- Linux updates no longer falsely reject a live approving process. Legacy
  Linux repository receipts require
  [authorized manual review](docs/architecture/RECOVERY.md#interrupted-repository-transport)
  rather than automatic cleanup.
- Contributor CI setup handles a missing Gallery registration and temporary
  package download failures without changing the selected dependency versions.
- Updates now request the exact selected version in the form accepted by the
  download provider, including prereleases such as `0.1.1-preview01`.
  Dependencies must still resolve successfully before installation can finish.
- Update checks no longer fail merely because `en-US` or `resources` folders
  coexist with a versioned module installation. Existing files are left intact.

## [0.2.0] - 2026-10-27

### Changed

- Updates of existing installations use native PowerShellGet `Update-Module`
  without Force or an install fallback. Exact target and source validation,
  consent and recovery remain in effect, and your repository settings are not
  changed.
- Prerelease updates support alphanumeric labels such as `preview03`; dotted
  labels such as `preview.3` are not supported by the native installer.

### Fixed

- PMU declares Microsoft.PowerShell.PSResourceGet 1.2.0 as a required module, so
  a missing provider is reported before PMU commands run.
- Linux updates no longer falsely reject a live approving process. Legacy Linux
  repository receipts require explicit recovery rather than automatic cleanup.
- Prerelease targets found on PSGallery now install instead of failing during
  staging.
- Update checks no longer fail when resource folders coexist with numeric
  version folders. No installation is migrated or removed.

## [0.1.0] - 2026-10-24

### Added

- Plan module updates with `Get-PSModuleUpdate` and install an approved plan
  with `Install-PSModuleUpdate`. Targets can be independent modules without a
  PMU dependency.
- Choose a repository by registered name or URI, and supply optional credentials
  separately for planning and installation. PMU never falls back to another
  repository.
- Select CurrentUser or AllUsers scope and stable or prerelease releases through
  the update policy. PMU never elevates privileges, stores credentials or reloads
  modules.
- Same-base prerelease updates use staged verification, backups and recovery.
  Results distinguish active, installed and target versions and indicate when a
  restart is required.

[Unreleased]: https://github.com/stiwicourage/PSModuleUpdate/compare/0.3.0...HEAD
[0.3.0]: https://github.com/stiwicourage/PSModuleUpdate/compare/0.2.0...0.3.0
[0.2.0]: https://github.com/stiwicourage/PSModuleUpdate/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/stiwicourage/PSModuleUpdate/releases/tag/0.1.0

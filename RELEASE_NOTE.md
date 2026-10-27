# Release notes

This file summarizes public cmdlet, CLI, configuration, and migration changes for PSModuleUpdate.
`CHANGELOG.md` remains the exhaustive record of all changes in each release. **UNRELEASED** changes will be included in the next **stable** release!

## [Unreleased]

### Added

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

- Existing-module updates now use native `Update-Module` without Force or an
  install fallback. Exact target/source, consent and restart requirements stay
  in effect. Prerelease updates use native-compatible labels such as `preview03`;
  dotted labels such as `preview.3` are not supported by the native installer.
  Temporary repository setup also handles automatically registered defaults
  without changing your repository settings.

### Deprecated

### Removed

### Fixed

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

### Security

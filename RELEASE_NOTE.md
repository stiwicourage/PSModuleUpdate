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

### Deprecated

### Removed

### Fixed

### Security

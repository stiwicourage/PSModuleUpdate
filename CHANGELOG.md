# Changelog

All notable changes to this project will be documented in this file and **UNRELEASED** changes will be included in the next **stable** release!

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Standalone `Get-PSModuleUpdate` planning and `Install-PSModuleUpdate`
  installation contracts for explicitly identified modules and repositories,
  with CurrentUser/AllUsers scope policies and stable/prerelease selection.
  Targets may be unloaded, independent modules without a PMU dependency.
  Registered-name and explicit-URI selectors share one protocol-based
  PSResourceGet adapter, with optional credentials supplied separately to both
  operations and no implicit repository fallback.
- Strategy C safety architecture for same-numeric-base prerelease progression:
  exact staging, GUID continuity, verified backups, persistent recovery journals,
  cooperative installation locks, rollback, and complete installed-tree
  verification.
- Separate active, installed, and target version reporting and restart semantics;
  no automatic elevation, credential persistence, or module reload.
- Standalone architecture, decision, implementation, recovery, and testing
  documentation, including explicit platform and provider qualification limits.
  G-4A3 is closed as functionally complete within the recorded qualified scope,
  with explicitly accepted quality findings and preserved historical evidence.
  A proposed reusable cross-platform strategy, technology comparison, minimum
  and extended matrices, and phased roadmap separate future PMU/Gerber Core
  qualification from completed development; no testing infrastructure is added.
- Local Nova quality entrypoints with strict ScriptAnalyzer findings,
  build/unit/integration ordering, failure propagation, and formatting checks.
  Compatible installed Pester selection prevents a Pester 5/6 assembly collision.
- Opt-in disposable live qualification for PSGallery, NuGet.org nonmodule
  rejection, and caller-approved authenticated private feeds, with explicit
  registration cleanup and artifact-specific evidence.

### Changed

### Deprecated

### Removed

### Fixed

- Pass the owned temporary dependency root between `Run Tests` workflow steps
  so NovaModuleTools is discoverable for CI and changelog validation, with
  ownership-validated cleanup even after a failed consumer step.

### Security

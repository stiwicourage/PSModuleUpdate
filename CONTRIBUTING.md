# Contributing

Thank you for contributing. Keep changes small, reviewable, and easy to validate.

G-4A3's [accepted closure](docs/architecture/G4A3_CLOSURE.md) is separate from future platform
qualification. Review the proposed [cross-platform strategy](docs/architecture/CROSS_PLATFORM_TESTING.md)
before implementing testing infrastructure; its matrices and roadmap are not
currently available commands or pipelines.

Before opening a pull request:

- run `pwsh -NoLogo -NoProfile -File ./run.ps1`; see [testing and qualification](docs/architecture/TESTING.md) for entrypoints and isolation requirements
- update tests when behavior changes
- keep tests mirrored to changed source files: one focused `.Tests.ps1` file for every new or changed `src/**/*.ps1` file
- use `tests/TestHelpers/` or test-support files for shared setup instead of broad catch-all test files
- add or update PlatyPS-compatible help under `docs/PSModuleUpdate/en-US/` when public commands or public classes change
- when you add a new public function, create its matching help file in the same change
- use Nova commands and `project.json` for build, test, package, and release behavior
- keep PowerShell code, tests, and examples compatible with `project.json` `Manifest.PowerShellHostVersion`; if the project targets `5.1`, do not add PowerShell 7.x-only features
- keep local quality checks ordered as ScriptAnalyzer, then `Invoke-NovaBuild`, then `Invoke-NovaTest`, then `Test-NovaBuild` when your project defines both test flows
- use `Invoke-NovaTest` for unit validation and `Test-NovaBuild` for build-validation integration runs; do not validate with direct `Invoke-Pester`
- keep public command unit ownership in `tests/public/<Command>.Tests.ps1`
- keep per-command public integration ownership in `tests/public/<Command>.Integration.Tests.ps1` when built-module behavior itself needs validation
- for destructive or environment-coupled commands, prefer safe `-WhatIf` integration coverage when appropriate
- if the repository quality loop or `Invoke-ScriptAnalyzerCI.ps1` reports ScriptAnalyzer findings, fix them before you ask for review
- follow `.github/instructions/psscriptanalyzer.instructions.md` as the ScriptAnalyzer workflow source of truth; use direct `Invoke-ScriptAnalyzer` only for focused local checks that reuse the repo-approved settings
- keep one externally called function per file and match the file name to that function; private files may keep extra related functions only as same-file top-level support helpers, and PowerShell functions must not declare nested functions inside their bodies
- follow `.github/instructions/code-quality-matrix.instructions.md` for source/helper-script maintainability and `.github/instructions/testing-policy.instructions.md` for test design
- keep `docs/PSModuleUpdate/en-US/*.md` as valid PlatyPS command help by using `New-MarkdownCommandHelp`, `Update-MarkdownCommandHelp`, and `Test-MarkdownCommandHelp`
- make every changed or generated text file end immediately after exactly one newline terminator with no blank spacer line at the bottom; use `pwsh -NoLogo -NoProfile -File ./scripts/build/Test-TextFileFormatting.ps1` for a focused check, and keep `tests/TextFileFormatting.Tests.ps1` green when Pester is enabled
- do not exclude or suppress PSScriptAnalyzer rules
- do not hand-create module `.psm1` or module `.psd1` files in source
- review `README.md`, `CHANGELOG.md`, and `RELEASE_NOTE.md` when the workflow or public behavior changed
- keep PowerShell cmdlet guidance, CLI guidance, and contributor guidance clearly separated
- validate the changed path before you ask for review

## Agentic Copilot workflow

Recommended flow:

1. **Design**
    - Use `/agent architect`, `.github/agents/architect.agent.md`, and `.github/prompts/design-change.prompt.md` when the scope still needs analysis.
2. **Implement**
    - Use `/agent powershell-developer`, `.github/agents/powershell-developer.agent.md`, and `.github/prompts/implement-issue.prompt.md` to implement the agreed change.
    - If the work is mainly about tests or coverage, use `/agent test-engineer`, `.github/agents/test-engineer.agent.md`, and `.github/prompts/improve-test-coverage.prompt.md`.
3. **Review**
    - Use `/agent reviewer`, `.github/agents/reviewer.agent.md`, and `.github/prompts/review-change.prompt.md` before handoff or pull request review.
4. **Prepare release**
    - Use `/agent release-manager`, `.github/agents/release-manager.agent.md`, and `.github/prompts/prepare-release.prompt.md` when release-facing files change.

The [G-4A4 plan](docs/architecture/G4A4/README.md) designs the GitHub Actions matrix and release gating. Phase 1
(`.github/workflows/ci.yml`, `scripts/build/ci/`) has executed on GitHub: both macOS lanes passed, while
Windows/Linux fixes still require a successful rerun; see
[PHASE1_IMPLEMENTATION.md](docs/architecture/G4A4/PHASE1_IMPLEMENTATION.md) for triggers, lanes, the `ci-gate`,
artifacts and local validation. To reproduce a lane locally, run
`pwsh -NoLogo -NoProfile -File ./scripts/build/ci/Invoke-PlatformLane.ps1 -LaneId <lane-id>` on a matching OS,
architecture and PowerShell version; a mismatching host fails by design.
Use the absolute provisioned `pwsh` path when reproducing a selected CI version.
The lane saves dependencies into an owned temporary module directory, passes
its isolated `PSModulePath` to every child and removes that directory afterward;
it does not install dependencies in CurrentUser or AllUsers. Existing
PSResourceGet repository state is preserved by the provider fixtures, not by
assuming that `HOME` or `PSModulePath` redirects registrations. Unexpected
skips and incomplete XML/log/runtime evidence fail the lane.

The separate `Run Tests` workflow also saves dependencies to an owned temporary
root. Each PowerShell consumer step uses the install step's `moduleRoot` output
to set an isolated `PSModulePath`; installed modules and imports do not carry
over automatically between steps. An always-run cleanup step validates ownership
before removing that root, including when tests or changelog validation fail.

Workflow policy tests distinguish the platform matrix from the other workflows.
`ci.yml` retains full-SHA action pins, fixed runner labels, read-only permissions,
and no secrets or publishing. Separate test/coverage, analysis, dependency-review,
and publish workflows may use version-tagged actions, moving runner labels, and
their purpose-specific permissions and secrets. All workflows reject
`pull_request_target`, and the dedicated publisher must not trigger on pull requests.
These policy checks do not qualify publishing or verify hosted execution.

# Shared infrastructure ownership recommendation

## TL;DR

Start **project-local** (workflows and `scripts/ci` live in PMU). Do not create a
shared repository or a testing framework. After Gerber adopts the same pattern
(two real consumers), decide between publishing a small reusable workflow from a
shared location or keeping copies. Project tests, requirements and qualification
scenarios stay project-owned throughout.

## Options

| Option | Pros | Cons | Verdict |
| --- | --- | --- | --- |
| A Project-local workflows | No coupling, simplest, matches Nova and SemanticRelease today | Duplication of boilerplate | Start here |
| B Reusable workflows (`workflow_call`) | One definition of the matrix and gate | Cross-repository use needs access (public repos, or explicit access settings for private); version pinning by tag/SHA; Gerber visibility is NOT VERIFIED | Later, after two consumers |
| C Nova-provided scripts/templates | Fits Nova conventions | Nova would own CI templates for modules that are not Nova; couples Nova release cadence to PMU CI; circular risk because Nova tests itself | Not recommended as the owner. Nova may document the convention |
| D Composite actions | Already used (five actions copied between Nova and SemanticRelease) | Copy drift; third-party ref policy | Copy-adapt now; extract with B |
| E Shared infrastructure repository | Single source | New repository, release process, review ownership; unjustified for two consumers | Do not create yet |
| F Combination | | | **Recommended**: A + D now, B (and possibly E) only if reuse is proven |

## Boundaries

| Concern | Owner |
| --- | --- |
| PMU tests, scenarios, qualification scripts, `project.json`, branch/environment settings | PMU |
| Gerber tests (credential, terminal, native stores), requirements | Gerber |
| Runner/PowerShell provisioning script, lane manifest schema, gate pattern | Initially PMU; shared candidate |
| Build, test, package, version, release commands | Nova (unchanged) |
| SemanticRelease | Not a dependency; reference only |

Design rules for the shared candidate: no hidden runtime dependency (scripts are
vendored or pinned by SHA), no secrets in shared code, no assumption that a
consumer project's tests exist, semantic versioning for any extracted artifact.
Decision D-4A4-10 records when to extract.

## Gerber reuse model (PROPOSED)

| Layer | Reused | Gerber-owned |
| --- | --- | --- |
| Runner/runtime lane | Six-lane matrix, PowerShell 7.4/latest provisioning, lane manifest | none |
| Quality | `ci-gate` pattern | `run.ps1` steps, ScriptAnalyzer settings |
| Tests | Pester via Nova | Credential service tests (native stores), terminal PTY regression (`scripts/build/Invoke-TerminalRegressionCI.ps1`, Python/pexpect, Unix-only) |

Gerber's `run.ps1` ends with the terminal regression CI, whose Unix PTY harness is
not Windows-compatible (EXISTING, from the earlier matrix). The six lanes
establish Nova component evidence on Windows, not a full Windows `run.ps1`;
Windows terminal qualification is Phase 3 work.

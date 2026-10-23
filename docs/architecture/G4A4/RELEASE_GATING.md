# Release-gating design

## TL;DR

PROPOSED: one `release.yml` that *calls* the same reusable `ci.yml` used for pull
requests, then runs a `release` job with `needs: [validate]`, a protected
`release` environment, a concurrency lock and a stale-tip check. Only the
`release` job can read `PSGALLERY_API`. A single aggregate job (`ci-gate`)
requires every mandatory job to be exactly `success`; skipped, cancelled and failed
all block publication. Nova stays the engine; `-SkipTests` remains, but only
because the explicit gate has already proven the tests for the same SHA.

## Current behavior (IMPLEMENTED in Nova; PMU has none)

See [NOVA_RELEASE_ANALYSIS.md](NOVA_RELEASE_ANALYSIS.md): no cross-workflow
dependency, partial tests, publish-then-commit ordering, no concurrency lock, no
environment. G-4A4 does not copy these gaps into PMU.

## Options evaluated

| Option | Verdict | Reason |
| --- | --- | --- |
| Single workflow with dependent jobs | Part of the recommendation | `needs` is the only mechanism that is verifiable inside one run and bound to one SHA |
| Reusable workflow via `workflow_call` | **Recommended** | PR/develop/main/release run the same job definitions; the caller gets one aggregate result bound to `github.sha` |
| `workflow_run` | Rejected for gating | Executes in the default-branch context, can observe a different SHA than the pushed one, races with concurrent pushes and gives stale or missing upstream results |
| Required status checks / branch protection | Complementary | Protect merges to `develop`/`main`; configuration lives in GitHub settings (cannot be shipped in the repository; NOT VERIFIED until the owner sets it) |
| GitHub environments | Recommended for release secrets | Environment secrets exist only for jobs that reference the environment; required reviewers are optional (availability on private repositories depends on the plan; NOT VERIFIED) |
| Release job dependency | Required | `needs: [validate]` plus `if: needs.validate.result == 'success'` |
| Commit-SHA validation | Required | Release job asserts `git rev-parse HEAD == github.sha` and that `origin/main` still equals `github.sha`; otherwise stop with a clear message |

## Proposed job graph (PROPOSED)

```text
push main / workflow_dispatch(main)
  └─ validate   (uses: ./.github/workflows/ci.yml, profile=release)
       ├─ quality              ubuntu-24.04
       ├─ platform (6 lanes)   windows-2025 / ubuntu-24.04 / macos-15 × {7.4, latest}
       ├─ release-required qualification subset (tier 3, same six lanes)
       └─ ci-gate              always(); fails unless every needed result == success
  └─ release    needs: validate; environment: release; concurrency: release-main
       1. checkout github.sha (fetch-depth: 0); assert tip == github.sha
       2. Nova: Invoke-NovaRelease -Repository PSGallery -ApiKey … -SkipTests
       3. changelog move, verified commit, fast-forward main, annotated tag (existing Nova actions)
```

`ci-gate` pattern (PROPOSED): `needs: [quality, platform, extended]` with
`if: always()` and a step that fails if any `needs.*.result` is not `success`.
Without `if: always()` a skipped dependency would also skip the gate and a
required check in "skipped" state can be treated as passing, which is exactly the
failure the brief forbids. Matrix expansion is checked inside `platform`
itself: its aggregate result is `failure` if any lane fails or is cancelled. A
lane that is missing from a matrix would not be detected by `needs`; the gate
therefore also verifies the expected lane set from the uploaded manifests
(six lane IDs).

## Validated artifact versus released artifact

Nova rebuilds after `Update-NovaModuleVersion`, so the published module is
`validated SHA + version metadata`. Two levels:

| Level | What is validated | Cost | Status |
| --- | --- | --- | --- |
| A (baseline, recommended first) | The pushed `main` SHA with all mandatory lanes; the release job then asserts that the files changed by Nova (before commit) are limited to an allow-list (`project.json` version, changelog/release-note files) and records the package hash | No extra test runs | PROPOSED |
| B (stronger, optional later) | A candidate tree created by `Update-NovaModuleVersion` in an isolated job, validated by the matrix, then released from exactly that tree | Matrix runs twice on `main` or release becomes two-stage; Nova cannot publish a prebuilt package, so B still rebuilds | PROPOSED, needs approval (D-4A4-07) |

In both levels, after Nova builds the release package a Linux job (or the release
job itself, before the publishing call is possible only if Nova is split into
`Update-NovaModuleVersion`, `Invoke-NovaBuild`, `New-NovaModulePackage`) installs
that package from a local disposable repository and verifies the manifest,
exported functions and help. NOT VERIFIED: whether splitting Nova's release into
those public commands is behavior-equivalent to `Invoke-NovaRelease`; it needs a
Phase 2 spike and Nova-owner review. Do not modify Nova for this.

## Hazards and mitigations

| Hazard | Mitigation |
| --- | --- |
| Concurrent pushes to `main` | `concurrency: { group: release-main, cancel-in-progress: false }` on the release job; stale-tip check; non-forced ref update (existing) |
| Cancelled/incomplete lane | Gate requires `success` for every `needs`; verify the six manifests; GitHub treats cancelled as not success |
| Stale successful result | No `workflow_run`; no reuse of earlier runs; the gate result belongs to the same run and `github.sha` |
| Different commit SHA | Release job checks out `github.sha` explicitly and compares with the remote tip |
| Release-generated commit re-triggering | Keep Nova's guard that skips when the head commit message starts with `chore(release): `; the generated commit is not itself qualified (it is the validated tree plus allow-listed metadata). Whether the generated commit satisfies branch protection on `main` is NOT VERIFIED |
| Tag creation | After commit; tag targets the generated commit, as in Nova |
| Publish succeeds, later step fails | Cannot unpublish; ordering kept; job fails loudly, and the runbook says "resume by completing commit/tag manually" (documented in Phase 2) |
| Develop prereleases | Out of scope unless approved (D-4A4-08); Nova's `develop` branch steps are currently unreachable |

## What is not proposed

No skipping of tests because `develop` passed; no `workflow_run`; no change to
Nova's engine; no second packaging or versioning mechanism; no PSGallery
publication of test packages.

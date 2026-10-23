# Security and credential model

## TL;DR

Pull-request jobs are secret-free and read-only. Cross-platform jobs use only
disposable local feeds and synthetic credentials. Protected integration jobs use
environment secrets, run only on manual or scheduled triggers from trusted
branches, and never on fork PRs. Only the release job, after the gate, can see the
PSGallery key.

## Workflow permissions (PROPOSED)

| Workflow / job | `permissions` | Secrets | Trigger boundary |
| --- | --- | --- | --- |
| `ci.yml` jobs | `contents: read` | none | `pull_request` (not `pull_request_target`), `push`, `workflow_call` |
| `qualification.yml` | `contents: read` | none | `schedule`, `workflow_dispatch`; same-repository code only |
| `external-integration.yml` | `contents: read` (+ `id-token: write` only if OIDC is later approved) | environment `external-*` secrets | `workflow_dispatch` (and optional schedule); environment approval; refuses `fork` events |
| `release.yml` `validate` | `contents: read` | none | `push` to `main`, `workflow_dispatch` |
| `release.yml` `release` | `contents: write` (verified commit, ref update, tag) | `PSGALLERY_API` from environment `release` | `needs: validate` success only |

Nova's `Publish.yml` currently grants `contents: write` and `actions: write` to
the entire workflow and passes `PSGALLERY_API` only to publishing steps. PMU
narrows permissions per job. `actions: write` is not needed unless a step
dispatches workflows (NOT VERIFIED; do not copy it by default).

## Rules

1. Use `pull_request`, never `pull_request_target`, for any job that checks out or
   executes pull-request code. Fork PRs receive no secrets and a read-only token
   (documented GitHub behavior).
2. Never expose `PSGALLERY_API`, Azure/Nexus tokens or other production secrets
   to `ci.yml` or `qualification.yml`. Release secrets live in the `release`
   environment only; branch/tag restriction on that environment limits it to
   `main`.
3. Cross-platform tests use a disposable local feed under a job temp directory,
   synthetic modules (random names) and a synthetic `PSCredential`. Local feed
   credentials, if needed, are generated per job and masked with `::add-mask::`.
4. Mask all dynamically created secrets; keep `ErrorAction` output and verbose
   logs free of credentials. Reports pass through the existing redaction checks
   (G-4A3 secret-value scan precedent) before upload; the upload action runs
   after the scan and uploads only an allow-listed directory.
5. Never upload credential stores, complete profiles, authenticated transcripts
   or journals containing credentials; PMU journals are credential-free by design.
6. Third-party actions: pin to commit SHAs (Nova pins only the third-party
   PSScriptAnalyzer action today; first-party actions use mutable major tags).
   Policy choice D-4A4-15.
7. Isolation per job: job-owned `PSModulePath`, temp roots, journals and backups;
   record the PSResourceGet store snapshot before registration tests and restore
   by exact ownership (existing PMU contract). Changing `HOME` alone does not
   isolate the registration store (G-4A3 evidence); the hosted runner VM is the
   isolation boundary, and each job runs in a fresh VM. Registry-mutating tests
   still run serially within a job.
8. Privileged steps (`sudo`, administrator) apply only to disposable module names
   and a unique root; a guard aborts if a target path matches an existing
   non-test module.

## External integration (tier 4)

| Concern | Design (PROPOSED) |
| --- | --- |
| Fork PRs | No secrets, job refuses to run; the workflow has no `pull_request` trigger |
| Approval | Environment (`external-azure`, `external-nexus`) with required reviewers if the plan allows; otherwise manual dispatch only by maintainers |
| Credentials | Scoped read-only feed tokens; stored as environment secrets; separate discovery vs installation tokens |
| Cleanup | `finally` removes temporary registrations; the job fails if cleanup cannot be proved |
| Availability | Missing secret/endpoint → job result `blocked` (reported as non-success in qualification; not a pass) |
| Support claims | Required for release only when the project claims support for that provider |

## Gerber credential implications

Gerber's credential service (Devlooped.CredentialManager 2.7.0) uses Apple
Keychain, Windows Credential Manager or Linux Secret Service, with no plaintext
fallback (read from `docs/architecture/credential-service.md`). These are native
stores: they are not PSCredential handling, serialization or an environment
variable. Hosted-runner suitability (all NOT VERIFIED):

| Platform | Native store on a hosted runner | Plan |
| --- | --- | --- |
| Windows | Credential Manager exists per user session; non-interactive service session behavior unknown | Spike |
| macOS | Login keychain may be locked/prompt in a non-GUI session; may need a disposable keychain created with `security` | Spike; never the developer keychain |
| Linux | Needs D-Bus session, `libsecret` and a Secret Service provider (for example `gnome-keyring`) installed via `apt` and started under `dbus-run-session` | Spike; Gerber already tests "unavailable store → fail, no plaintext" which needs no vault |

No Gerber test or code is created here.

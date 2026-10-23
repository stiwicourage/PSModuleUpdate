# Recovery and filesystem safety

## What PMU protects

PMU coordinates its own cooperating processes for one module, selected scope,
and resolved installation root. It cannot lock out direct PSResourceGet calls,
other package managers, manual changes, or malicious privileged processes.
Do not run those operations concurrently against the same installation.

Same-base replacement uses a staged package and a verified backup outside the
Modules tree. A persistent journal records the operation before destructive
replacement. File-tree verification checks content, not merely a manifest
version or provider exit status. The only intentional provider-metadata
difference is `PSGetModuleInfo.xml`; arbitrary content is not excluded.

The journal records non-secret identity, scope, root, previous/target versions,
GUID, staging/backup locations, state, and recovery status. Credentials are
never part of this record.

## Interrupted operations

On an approved installation attempt, PMU acquires the same installation lock
and inspects unfinished recovery state before attempting another update.
It validates journal contents and referenced paths rather than following
arbitrary paths supplied by a journal.

If the target is already complete, verification can finish the interrupted
operation. Otherwise, a surviving valid backup enables best-effort restoration
of the previous installation. Recovery is restricted to the same module,
scope, and root; it is not permission to update unrelated modules.

Recovery can invalidate a previously created plan. Obtain a fresh plan after
repair when instructed. `-WhatIf` does not acquire a mutation lock, repair an
installation, or write a journal.

If the original numeric directory disappeared, obtain the module reference
from the surviving PMU backup manifest. PMU accepts that reference only when
it matches a validated unfinished journal, original scope/root, GUID, and
complete version; arbitrary backup or source layouts remain unsupported.
An approved installation attempt can restore the original installation, but
invalidates its plan. Follow the structured error's instruction to obtain a
fresh plan from the restored installation before continuing.

## Interrupted repository transport

Unregistered URI operations use temporary provider registrations and separate
nonsecret ownership receipts under native LocalApplicationData
`PSModuleUpdate/RepositoryTransport`. Their coordination root is independent
of disposable HOME installation roots, because HOME does not isolate the
provider's repository store.

Normal completion verifies and removes owned registrations. A later operation
can clean up a dead owner's fully bound receipt only when its name, URI hash,
API version, trust, and priority still match. It never removes a live owner's
registration, a repointed registration, or a name merely sharing a prefix.

Termination between native registration and atomic API-bound receipt
replacement leaves an unproven API identity. Cleanup deliberately stops with a
structured recovery error instead of deleting that registration. Preserve the
named receipt and registration, stop concurrent registry writers, and obtain
authorized manual review of that individual registration. Never reset the
provider XML store or bulk-remove PMU-prefixed names.

## When recovery cannot finish

Errors such as `PMU.RecoveryRequired`, `PMU.RecoveryFailed`, or
`PMU.RollbackFailed` stop installation. Preserve the error identifier and its
safe diagnostic context. Do not delete the journal, staging evidence, or the
only usable backup to make a later attempt proceed.

Before manual intervention:

1. Stop cooperating update attempts and unrelated package-manager activity.
2. Confirm the module name, GUID, selected scope, root, and affected numeric
   version directory from the reported context.
3. Preserve available backup and journal evidence outside the Modules tree.
4. Inspect the reported failure and correct permissions or damaged state
   through an authorized recovery procedure.
5. Obtain a new update plan after the installation has been independently
   verified.

Do not paste credentials, authorization headers, or unredacted authenticated
provider exceptions into diagnostic reports.

## Guarantees and limits

Rollback is best effort. PMU verifies a restoration before reporting recovery
completion, and a failed update is never reported as a successful installation.
Unrelated numeric versions and installations in another scope must remain
untouched.

Neither installation nor recovery is a fully atomic transaction. Journal file
flushing and replacement reduce interruption risk but do not establish
guaranteed power-loss durability. Recovery is not guaranteed if the backup and
installation are both damaged, storage fails, or another process changes the
same files.

An on-disk restoration does not unload code already active in the current
PowerShell process. Follow `RestartRequired` and restart the shell when needed;
PMU never attempts a hot reload.

Successful recovery on one platform does not qualify Windows, Linux, every
filesystem, PowerShell 7.4, or elevated AllUsers behavior. See
[the implementation plan](PLAN.md) for outstanding qualification.

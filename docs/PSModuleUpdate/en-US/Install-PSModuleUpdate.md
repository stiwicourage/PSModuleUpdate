---
document type: cmdlet
external help file: PSModuleUpdate-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSModuleUpdate
ms.date: 10.23.2026
PlatyPS schema version: 2024-05-01
title: Install-PSModuleUpdate
---

# Install-PSModuleUpdate

## SYNOPSIS

Applies one live exact-version module update plan.

## SYNTAX

### ByUpdatePlan (Default)

```
Install-PSModuleUpdate -Update <Object> [-Credential <pscredential>] [-AcceptLicense]
 [-TrustRepository] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has no aliases.


## DESCRIPTION

Revalidates and stages the exact package without importing it.
Same-base replacement uses
a verified backup, durable journal, exclusive OS handle lock, and best-effort rollback.
Only provider-generated root PSGetModuleInfo.xml is excluded from SHA256 tree comparison.
No module is hot reloaded.
Interrupted operations require safe recovery and a fresh plan.
The target is the compatible installed module bound by the plan, not
necessarily the caller or a loaded module. No dependency on PMU is required.

## EXAMPLES

### EXAMPLE 1

```powershell
$plan | Install-PSModuleUpdate -WhatIf
```

Revalidates read-only without locking, staging, installing, or repairing recovery state.

### EXAMPLE 2

```powershell
$plan | Install-PSModuleUpdate -AcceptLicense -TrustRepository
```

Requests native confirmation before applying the exact approved target and scope.

## PARAMETERS

### -AcceptLicense

Explicitly accepts provider package license requirements for this operation.
Also required when the provider does not disclose whether acceptance is

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByUpdatePlan
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Credential

Per-call provider credential; never persisted.

```yaml
Type: System.Management.Automation.PSCredential
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByUpdatePlan
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -TrustRepository

Allows this operation against an untrusted repository without changing its registration.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByUpdatePlan
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Update

An unmodified live PSModuleUpdate.UpdatePlan from this module instance; pipeline by value.

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByUpdatePlan
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Object

An unmodified live `PSModuleUpdate.UpdatePlan` from this module instance.
Pipeline binding is by value only; serialized and manufactured plans are rejected.

## OUTPUTS

### PSModuleUpdate.UpdateResult

A schema-1 result reporting Outcome, ActiveVersion, InstalledVersion,
TargetVersion, verification, dependency observations, recovery, and restart
requirements independently. Outcomes are Installed, AlreadyInstalled, Cancelled,
and WhatIf. Provider success alone never produces Installed.

## NOTES

Planning and WhatIf never perform recovery writes. After native approval, an
exclusive OS handle lock covers revalidation, staging, backup, replacement,
verification, rollback, and journal completion. Lock acquisition is bounded.
The exact target and selected CurrentUser or AllUsers scope never change.
AllUsers permission failures do not cause elevation or CurrentUser fallback.
The bound endpoint, API version, and trust state are revalidated before staging
and again before installation. Bound consumer registrations cannot be
repointed or silently replaced by aliases. An initially unregistered URI uses a
fresh operation-owned temporary registration after approval, with checked
cleanup. `-WhatIf` never creates one. Existing registrations are never modified.

Same-numeric-version prerelease progression uses exact Save-PSResource staging
and internal Install-PSResource -Reinstall only for a validated collision.
Backups are outside Modules. Journals use flushed temporary files and atomic
file replacement; PMU does not claim atomic installation or guaranteed
power-loss recovery. Interrupted state and journal paths are untrusted and
validated before repair. Recovery that restores prior files requires a fresh
plan. A complete target is recognized only after complete-tree verification.

TrustRepository is operation-scoped and never changes repository trust.
AcceptLicense is independent of confirmation and trust. Missing or malformed
provider license metadata conservatively requires explicit acceptance.
Prerequisites are checked before quiet provider staging and installation, and
checked again under the mutation lock. Direct credentials are never persisted
or retained for later calls.

PMU does not import staged code or reload a consumer. RestartRequired includes
replacement of loaded files even when version text is unchanged. When a newer
target is installed while an older module remains loaded, restart is needed to
use the target.

Stable error identifiers include PMU.InvalidPlan, PMU.PlanStale,
PMU.RepositoryChanged, PMU.InstalledStateChanged, PMU.PermissionDenied,
PMU.LockTimeout, PMU.VerificationFailed, PMU.RecoveryRequired,
PMU.RecoveryFailed, and PMU.RollbackFailed. Preserve recovery evidence if repair
cannot be verified. A surviving verified PMU backup may supply the module
identity only when it matches a validated unfinished journal. Recovery requires
a fresh plan even if a complete interrupted target was already installed.

Windows, Linux, PowerShell 7.4, real AllUsers writes, and later provider versions
require separate qualification. Private stable installation has live
artifact-specific evidence; private prerelease progression remains NOT TESTED
unless an authorized live progression is recorded.

## RELATED LINKS

- [about_Modules](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_modules)

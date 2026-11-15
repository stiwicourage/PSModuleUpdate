---
document type: cmdlet
external help file: PSModuleUpdate-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSModuleUpdate
ms.date: 10.31.2026
PlatyPS schema version: 2024-05-01
title: Get-PSModuleUpdateTargetManifest
---

# Get-PSModuleUpdateTargetManifest

## SYNOPSIS

Downloads and safely reads the exact target manifest of one live update plan.

## SYNTAX

### __AllParameterSets

```
Get-PSModuleUpdateTargetManifest [-Plan] <Object> [[-Credential] <pscredential>] [-TrustRepository]
 [-AcceptLicense] [<CommonParameters>]
```

## ALIASES

None.


## DESCRIPTION

Inspects only the bound repository and exact planned candidate in an owned temporary
workspace.
Does not install, import, or execute the target.
Binds the manifest internally
to the unmodified live plan; installation rejects a differing staged manifest.

## EXAMPLES

### EXAMPLE 1

```powershell
$target = $plan | Get-PSModuleUpdateTargetManifest -TrustRepository -AcceptLicense
$target.Manifest.PrivateData
```

Inspect the candidate metadata before independently approving installation with
`Install-PSModuleUpdate`. Credentials and consent must be supplied again to that
separate operation.

## PARAMETERS

### -AcceptLicense

Explicit acceptance of declared or undisclosed package license requirements.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
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

Optional per-call provider credential.
Never retained; supply it again to installation.

```yaml
Type: System.Management.Automation.PSCredential
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Plan

An unmodified live plan from Get-PSModuleUpdate in this same module instance.

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -TrustRepository

Explicit operation-scoped approval of an untrusted repository.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
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

An unmodified live `PSModuleUpdate.UpdatePlan` from this same module instance.
Cloned, deserialized, edited, and other-instance plans are rejected.

## OUTPUTS

### PSModuleUpdate.TargetManifest

A data-only object with `Manifest` (the safely imported manifest hashtable,
including GUID, ModuleVersion, and complete PrivateData), `ModuleName`,
`ModuleGuid`, `Version` (the exact semantic target identity, including prerelease),
and sanitized `RepositoryUri`.

## NOTES

Only the exact planned version and bound endpoint are queried. Inspection uses
the same native acquisition and package validation adapters as installation,
in an operation-owned temporary workspace under CurrentUser PMU data. It does
not import the target, execute its RootModule or scripts, mutate installed
files, or interpret consumer-specific PrivateData.

The public plan remains unchanged. PMU privately binds the inspected manifest
bytes to the original live plan. Installation compares its newly staged
manifest before installed-file mutation and terminates with
`PMU.TargetManifestChanged` if the content differs, even if name, GUID and version
still match. Editing this result cannot change that binding. Reinspection of
changed content requires a fresh plan; changes to whitespace alone also require
fresh approval. Plans that have not been inspected retain their existing behavior.

Repository trust and license acceptance have the same opt-in meanings as
installation. Inspection does not transfer consent or retain credentials.
Owned transport registrations and the inspection workspace are cleaned on
success and failure; unsafe cleanup fails closed. Planning and installation
`-WhatIf` remain acquisition-free.

## RELATED LINKS

- [about_Modules](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_modules)

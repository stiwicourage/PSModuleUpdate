---
document type: cmdlet
external help file: PSModuleUpdate-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSModuleUpdate
ms.date: 10.30.2026
PlatyPS schema version: 2024-05-01
title: Get-PSModuleUpdate
---

# Get-PSModuleUpdate

## SYNOPSIS

Creates a read-only exact-version update plan for an installed PowerShell module.

## SYNTAX

### ByModule (Default)

```
Get-PSModuleUpdate -Module <psmoduleinfo> -Repository <string> [-Policy <hashtable>]
 [-Credential <pscredential>] [<CommonParameters>]
```

### ByRepositoryUri

```
Get-PSModuleUpdate -Module <psmoduleinfo> -RepositoryUri <uri> [-Policy <hashtable>]
 [-Credential <pscredential>] [<CommonParameters>]
```

## ALIASES

This cmdlet has no aliases.


## DESCRIPTION

Inspects a compatible installed module in CurrentUser or AllUsers and one explicitly selected repository.
The target need not be loaded, be the caller, or depend on PSModuleUpdate.
PMU is a standalone shared module; consumers own repository configuration and
the decision about when to check for updates.
Policy defaults to Stable and CurrentUser.
Credentials are used only in memory.

`Policy` accepts only `Channel` (`Stable` or `IncludePrerelease`), `Scope`
(`CurrentUser` or `AllUsers`), `ExpectedRepositoryUri` (`System.Uri` or null),
and `VersionRange` (provider-supported NuGet range string or null). The latter
two default to null. IncludePrerelease includes stable releases as well.
The explicitly selected scope must already contain the matching name and GUID;
PMU never creates a shadow installation or changes scope.

Ordinary resource folders beside numeric version directories do not count as
installed copies. This allows a versioned installation to coexist with resource
folders left by a legacy flat installation, without migrating or selecting the
flat copy. Numeric directories and directories containing the target module's
manifest still undergo manifest and layout validation.

The manifest supplies installed prerelease identity. The `Active*` fields
describe a matching module actually loaded in the session and are null when
the target is unloaded.
`RestartRequired` inspects actual loaded copies; PMU never imports the target
to plan or apply an update. A plan binds one exact
target from one repository and never authorizes a downgrade. Planning does not
write installation locks, staging files, or installation journals.

Choose either `Repository` or `RepositoryUri`, never both. A unique existing
registration for the URI is reused and source-bound; ambiguous registrations
are rejected. An unregistered URI uses an operation-owned temporary
registration. The endpoint, provider API, and trust policy remain bound across
discovery and installation even though temporary transport names change.
Removing or repointing a bound consumer registration never causes alias
selection or fallback to another source.

If the provider does not disclose a package's license-acceptance requirement,
the plan conservatively sets `RequiresLicenseAcceptance` to true. Installation
then requires explicit `-AcceptLicense`; PMU never interprets absent metadata
as permission to accept a license or allow a provider prompt.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-PSModuleUpdate -Module (Get-Module ExampleModule) -Repository PSGallery
```

Creates a stable CurrentUser update plan without changing installed files.

### EXAMPLE 2

```powershell
Get-PSModuleUpdate -Module $installed -RepositoryUri ([uri]'https://api.nuget.org/v3/index.json')
```

`$installed` is a compatible installed `PSModuleInfo`, not necessarily loaded.
An existing unique registration is reused; otherwise PMU temporarily registers
the endpoint for transport and cleans up its owned registration.
General NuGet packages without a valid PowerShell module manifest are rejected.

### EXAMPLE 3

```powershell
$plan = Get-PSModuleUpdate -Module $installed -RepositoryUri $privateRepositoryUri -Credential $credential
$plan | Install-PSModuleUpdate -Credential $credential -AcceptLicense -TrustRepository
```

The caller supplies the private endpoint and credential independently to each
command. PMU does not read an environment token, store credentials, or modify
an existing registration.

## PARAMETERS

### -Credential

Optional per-call provider credential.
Supply it again when installing.

```yaml
Type: System.Management.Automation.PSCredential
DefaultValue: ''
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

### -Module

One compatible installed module reference; no import or PMU dependency is required.
Name and GUID must match its on-disk manifest.

```yaml
Type: System.Management.Automation.PSModuleInfo
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Policy

Channel, Scope, ExpectedRepositoryUri (Uri), and VersionRange.
Unknown keys are rejected.

```yaml
Type: System.Collections.Hashtable
DefaultValue: '@{}'
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

### -Repository

One literal registered PSResourceGet repository name.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByModule
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -RepositoryUri

One absolute repository endpoint. Cannot be combined with `Repository`.
PMU reuses a unique existing registration or creates a temporary owned
registration; ambiguous consumer registrations are rejected.
Credentials, query strings, and fragments must not be embedded in the URI.
One absolute repository endpoint.
Cannot be combined with `Repository`.
PMU reuses a unique existing registration or creates a temporary owned
registration; ambiguous consumer registrations are rejected.
Credentials, query strings, and fragments must not be embedded in the URI.

```yaml
Type: System.Uri
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByRepositoryUri
  Position: Named
  IsRequired: true
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

## OUTPUTS

### PSModuleUpdate.UpdatePlan

A live schema-1, data-only plan with active and selected-scope installation
identity, repository snapshot, exact target, policy, disposition, and
prerequisites. It contains no credential and is not a durable authorization token.

## NOTES

Requires PowerShell 7.4 or later and the qualified PSResourceGet 1.2.0 baseline.
Missing provider setup, unavailable packages, authentication failures, unsafe
paths, and identity mismatches are terminating structured PMU errors, not
UpToDate results. Credentials must be supplied independently to installation.

When no eligible package exists in the explicitly selected repository,
discovery terminates with the stable error ID `PMU.PackageNotFound` and returns
no update plan. This includes the provider's structured `PackageNotFound`
failure. PMU does not query another feed or substitute another version.
Other discovery, authentication and permission failures retain their distinct
PMU errors; raw provider diagnostics are withheld to protect credentials.

PSResourceGet 1.2.0 Find/Save/Install expose repository names, not a direct URI
parameter. PMU serializes its own registration changes with a per-user
exclusive-handle lock and uses collision-resistant names plus flushed nonsecret
ownership receipts. It never overwrites a registration, changes global trust,
or stores credentials in registration metadata. Cleanup validates exact
ownership and configuration; it never removes registrations by prefix alone.
These safeguards do not establish a transaction with non-cooperating registry
writers. Termination between registration and durable provider-API binding can
require manual intervention; cleanup fails closed rather than guessing.
On macOS the provider store is under the actual LocalApplicationData
`PSResourceGet/PSResourceRepository.xml`; changing HOME alone does not isolate it.

One generic PSResourceGet adapter is used for compatible registered feeds.
PSGallery, NuGet.org, Azure Artifacts, and Nexus do not have vendor-specific
branches. External-feed behavior requires separate qualification; protocol
compatibility is not a live-validation claim.

If the original installation vanished, a module reference from its surviving
PMU backup can reach recovery only when the backup matches a validated
unfinished journal, scope, root, GUID, and complete version. Approval is still
required for repair, and recovery invalidates the old plan. If neither a valid
installation nor backup identity survives, manual recovery is required.

## RELATED LINKS

- [about_Modules](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_modules)

function Initialize-QualificationSession {
    param([hashtable]$Options)
    $root = $env:PMU_QUALIFICATION_ROOT
    $destination = Initialize-QualificationEnvironment $root
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0 -ErrorAction Stop
    Import-Module $Options.ModulePath -ErrorAction Stop
    Assert-QualificationJournalRoot "$root/home"
    [pscustomobject]@{
        Options = $Options; Root = $root; Destination = $destination
        Credential = (Get-QualificationCredential $Options.Scenario); RepositoryName = $null
        RepositoryStore = (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PSResourceGet/PSResourceRepository.xml')
        Before = @(Get-QualificationRepositoryState); RegistrationOwned = $false
        Evidence = [ordered]@{ Scenario = $Options.Scenario; Outcome = 'Failed'; Cleanup = 'NotRun'; Phase = 'Initialization' }
    }
}

function Assert-QualificationJournalRoot {
    param([string]$HomeRoot)
    $dataRoot = & (Get-Module PSModuleUpdate) { Resolve-PMUDataRoot 'CurrentUser' }
    Assert-QualificationDestination $dataRoot $HomeRoot
}

function Get-QualificationCredential {
    param([string]$Scenario)
    try {
        if ($Scenario -eq 'Private') { Get-QualificationPrivateCredential }
    } finally {
        Remove-Item Env:ADO_PAT, Env:PMU_QUALIFICATION_PASSWORD, Env:PMU_QUALIFICATION_USERNAME -ErrorAction SilentlyContinue
    }
}

function Initialize-QualificationEnvironment {
    param([string]$Root)
    $destination = [System.Management.Automation.Platform]::SelectProductNameForDirectory('USER_MODULES')
    Assert-QualificationDestination $destination "$Root/home"
    $env:PSModulePath = "$destination$([IO.Path]::PathSeparator)$env:PSModulePath"
    $destination
}

function Get-QualificationPrivateCredential {
    if ($env:PMU_QUALIFICATION_PASSWORD) {
        return [pscredential]::new($env:PMU_QUALIFICATION_USERNAME, (ConvertTo-QualificationSecret $env:PMU_QUALIFICATION_PASSWORD))
    }
    if ($env:ADO_PAT) {
        return [pscredential]::new('qualification', (ConvertTo-QualificationSecret $env:ADO_PAT))
    }
}

function ConvertTo-QualificationSecret {
    param([string]$Value)
    $secure = [securestring]::new()
    foreach ($character in $Value.ToCharArray()) { $secure.AppendChar($character) }
    $secure.MakeReadOnly()
    $secure
}

function Get-QualificationRepositoryState {
    foreach ($repository in Microsoft.PowerShell.PSResourceGet\Get-PSResourceRepository -ErrorAction Stop) {
        [System.Management.Automation.PSSerializer]::Serialize($repository)
    }
}

function Complete-QualificationSession {
    param([object]$Session)
    try {
        Invoke-QualificationRegistrationCleanup $Session
        Assert-QualificationRepositoryState $Session.Before @(Get-QualificationRepositoryState)
        $Session.Evidence.Cleanup = 'Passed'
    } catch {
        $Session.Evidence.Cleanup = 'Failed'
        $Session.Evidence.Outcome = 'Failed'
    }
    $Session.Evidence.ProviderVersion = '1.2.0'
    $Session.Evidence.DestinationIsDisposable = $true
    $Session.Evidence.RepositoryStoreIsHomeIsolated = $false
}

function Get-QualificationProviderParameter {
    param([object]$Session, [string]$Name, [string]$Version)
    $parameters = @{
        Name = $Name; Repository = $Session.RepositoryName; Version = $Version
        ErrorAction = 'Stop'; WarningAction = 'SilentlyContinue'; Verbose = $false; Debug = $false
    }
    if ($Session.Credential) { $parameters.Credential = $Session.Credential }
    $parameters
}

function Get-QualificationPolicy {
    param([object]$Session)
    @{
        Channel = 'Stable'; Scope = 'CurrentUser'
        ExpectedRepositoryUri = [uri]$Session.Options.RepositoryUri
        VersionRange = "[$($Session.Options.TargetVersion)]"
    }
}

function Get-QualificationModuleTree {
    param([string]$Root)
    foreach ($file in Get-ChildItem -LiteralPath $Root -File -Recurse -ErrorAction Stop) {
        "$($file.FullName)|$((Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash)"
    }
}

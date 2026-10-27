function Invoke-QualificationScenario {
    param([object]$Session)
    $Session.Evidence.Phase = 'ProviderDiscovery'
    Get-QualificationDiscoveryEvidence $Session
    if ($Session.Options.Scenario -eq 'NuGet') {
        Invoke-QualificationNonModule $Session
        return
    }
    $module = Save-QualificationSeed $Session
    $Session.Evidence.Phase = 'PMUPlanning'
    Test-QualificationSourcePolicy $Session $module
    $plan = Get-QualificationPlan $Session $module
    $Session.Evidence.Phase = 'PMUInstallation'
    Test-QualificationWhatIf $Session $plan
    $result = Install-PSModuleUpdate -Update $plan -Credential $Session.Credential -AcceptLicense -TrustRepository -Confirm:$false
    Assert-QualificationInstalledResult $Session $plan $result
    $Session.Evidence.Outcome = 'Passed'
}

function Get-QualificationDiscoveryEvidence {
    param([object]$Session)
    $parameters = Get-QualificationProviderParameter $Session $Session.Options.SeedName $Session.Options.TargetVersion
    $exact = @(Microsoft.PowerShell.PSResourceGet\Find-PSResource @parameters)
    if ($exact.Count -ne 1) {
        throw 'Exact provider fixture was not found.'
    }
    $Session.Evidence.ExactDiscoveredVersion = "$($exact[0].Version)"
    $parameters = Get-QualificationProviderParameter $Session $Session.Options.DiscoveryName '*'
    $parameters.Prerelease = $true
    $prereleases = @(Microsoft.PowerShell.PSResourceGet\Find-PSResource @parameters | Where-Object Prerelease)
    $Session.Evidence.PrereleaseCount = $prereleases.Count
    $Session.Evidence.PrereleaseInstallation = 'NOT TESTED: no approved progression fixture.'
}

function Save-QualificationSeed {
    param([object]$Session)
    $Session.Evidence.Phase = 'SeedAcquisition'
    Assert-QualificationDestination $Session.Destination "$($Session.Root)/home"
    New-Item -Path $Session.Destination -ItemType Directory -Force | Out-Null
    $parameters = Get-QualificationProviderParameter $Session $Session.Options.SeedName $Session.Options.SeedVersion
    Microsoft.PowerShell.PSResourceGet\Save-PSResource @parameters -Path $Session.Destination -TrustRepository -AcceptLicense
    $manifest = "$($Session.Destination)/$($Session.Options.SeedName)/$($Session.Options.SeedVersion)/$($Session.Options.SeedName).psd1"
    $module = Get-Module -ListAvailable -Name $manifest
    Assert-QualificationSeed $Session $module
    $module
}

function Assert-QualificationSeed {
    param(
        [object]$Session,
        [System.Management.Automation.PSModuleInfo]$Module
    )

    if (-not $Module) {
        throw 'The downloaded seed is not an available PowerShell module.'
    }
    if (@($Module.RequiredModules | Where-Object Name -EQ 'PSModuleUpdate').Count) {
        throw 'Fixture unexpectedly depends on PMU.'
    }
    if (Get-Module -Name $Module.Name) {
        throw 'The seed fixture must remain unloaded.'
    }
    $Session.Evidence.SeedHasPmuDependency = $false
    $Session.Evidence.SeedWasLoaded = $false
}

function Get-QualificationPlan {
    param(
        [object]$Session,
        [System.Management.Automation.PSModuleInfo]$Module
    )

    $parameters = @{
        Module = $Module
        Policy = (Get-QualificationPolicy $Session)
    }
    if ($Session.Credential) {
        $parameters.Credential = $Session.Credential
    }
    if ($Session.Options.Scenario -eq 'Gallery') {
        $parameters.Repository = $Session.RepositoryName
    } else {
        $parameters.RepositoryUri = [uri]$Session.Options.RepositoryUri
    }
    $plan = Get-PSModuleUpdate @parameters
    Assert-QualificationPublicObject $plan
    if ($plan.TargetVersion -cne $Session.Options.TargetVersion) {
        throw 'PMU selected a different exact version.'
    }
    if ($plan.RepositoryUri -cne $Session.Options.RepositoryUri) {
        throw 'PMU changed the selected source.'
    }
    Assert-QualificationPlanIdentity $Session $Module $plan
    $Session.Evidence.Plan = $plan
    $plan
}

function Test-QualificationWhatIf {
    param(
        [object]$Session,
        [object]$Plan
    )

    $before = @(Get-QualificationModuleTree $Session.Destination)
    $result = Install-PSModuleUpdate -Update $Plan -WhatIf -Credential $Session.Credential -InformationAction SilentlyContinue
    Assert-QualificationRepositoryState $before @(Get-QualificationModuleTree $Session.Destination)
    Assert-QualificationPublicObject $result
    $Session.Evidence.WhatIfInstallationUnchanged = $true
}

function Assert-QualificationInstalledResult {
    param(
        [object]$Session,
        [object]$Plan,
        [object]$Result
    )

    Assert-QualificationPublicObject $Result
    foreach ($field in @('ModuleName', 'ModuleGuid', 'RepositoryUri', 'Scope', 'ActiveVersion', 'TargetVersion')) {
        if ($Result.$field -cne $Plan.$field) {
            throw 'Installation result does not match the source-bound plan.'
        }
    }
    if ($Result.InstalledVersion -cne $Plan.TargetVersion) {
        throw 'The exact target version was not installed.'
    }
    if ($Result.VerificationStatus -ne 'Verified') {
        throw 'The installed package was not verified.'
    }
    Assert-QualificationResultStatus $Result
    Assert-QualificationDestination $Result.InstalledPath "$($Session.Root)/home"
    $Session.Evidence.Result = $Result
    $Session.Evidence.CredentialFree = $true
}

function Assert-QualificationPlanIdentity {
    param(
        [object]$Session,
        [System.Management.Automation.PSModuleInfo]$Module,
        [object]$Plan
    )

    if ($Plan.ModuleGuid -ne $Module.Guid) {
        throw 'Plan identity differs from the independent installed module.'
    }
    if ($Plan.InstalledVersion -cne $Session.Options.SeedVersion) {
        throw 'Plan observed a different installed version.'
    }
    Assert-QualificationUnloadedState $Plan
    if ($Plan.Scope -ne 'CurrentUser') {
        throw 'Plan changed the approved isolated scope.'
    }
    if (-not $Plan.UpdateAvailable) {
        throw 'The pinned newer target must be available.'
    }
}

function Assert-QualificationResultStatus {
    param([object]$Result)
    if ($Result.SchemaVersion -ne 1) {
        throw 'Unexpected public result schema.'
    }
    if ($Result.Outcome -ne 'Installed') {
        throw 'Expected a verified new installation.'
    }
    if ($Result.RestartRequired) {
        throw 'An unloaded module should not require restart.'
    }
    Assert-QualificationUnloadedState $Result
    if (Get-Module -Name $Result.ModuleName) {
        throw 'PMU unexpectedly loaded the independent target.'
    }
}

function Assert-QualificationUnloadedState {
    param([object]$Value)
    foreach ($field in @('ActiveVersion', 'ActivePath', 'ActiveScope')) {
        $property = $Value.PSObject.Properties[$field]
        if ($property -and $null -ne $property.Value) {
            throw 'An unloaded fixture must not report actual active state.'
        }
    }
}

function Test-QualificationSourcePolicy {
    param(
        [object]$Session,
        [System.Management.Automation.PSModuleInfo]$Module
    )

    $policy = Get-QualificationPolicy $Session
    $policy.ExpectedRepositoryUri = [uri]'https://qualification.invalid/not-the-approved-source'
    try {
        Get-PSModuleUpdate -Module $Module -Repository $Session.RepositoryName -Policy $policy -Credential $Session.Credential | Out-Null
    } catch {
        if ($_.FullyQualifiedErrorId -notmatch 'PMU\.RepositoryChanged') {
            throw 'Unexpected source-policy rejection.'
        }
        $Session.Evidence.SourcePolicyMismatchRejected = $true
        return
    }
    throw 'PMU accepted a mismatched source policy.'
}

function Invoke-QualificationNonModule {
    param([object]$Session)
    $Session.Evidence.Phase = 'ProviderExactDownload'
    if (-not (Save-QualificationNonModuleArchive $Session)) {
        return
    }
    $module = Initialize-QualificationNonModuleSeed $Session
    $before = @(Get-QualificationModuleTree $Session.Destination)
    $Session.Evidence.Phase = 'PMUNonModuleValidation'
    try {
        $plan = Get-QualificationPlan $Session $module
        Install-PSModuleUpdate -Update $plan -Credential $Session.Credential -AcceptLicense -TrustRepository -Confirm:$false | Out-Null
        throw 'PMU did not reject the nonmodule package.'
    } catch {
        Resolve-QualificationNonModuleRejection $Session $_
    }
    Assert-QualificationRepositoryState $before @(Get-QualificationModuleTree $Session.Destination)
    $Session.Evidence.InstallationUnchanged = $true
}

function Save-QualificationNonModuleArchive {
    param([object]$Session)
    $parameters = Get-QualificationProviderParameter $Session $Session.Options.SeedName $Session.Options.TargetVersion
    $path = New-Item "$($Session.Root)/download" -ItemType Directory
    try {
        Microsoft.PowerShell.PSResourceGet\Save-PSResource @parameters -Path $path.FullName -AsNupkg -TrustRepository -AcceptLicense
    } catch {
        $Session.Evidence.Outcome = 'ProviderLimitation'
        $Session.Evidence.PmuNonModuleValidation = 'NOT TESTED: provider exact acquisition rejected the nonmodule.'
        return $false
    }
    $Session.Evidence.ExactDownloadedBytes = (Get-ChildItem $path -Filter '*.nupkg' -File | Measure-Object Length -Sum).Sum
    $true
}

function Initialize-QualificationNonModuleSeed {
    param([object]$Session)
    $directory = "$($Session.Destination)/NuGet.Versioning/6.12.0"
    Assert-QualificationDestination $directory "$($Session.Root)/home"
    New-Item $directory -ItemType Directory -Force | Out-Null
    Set-Content "$directory/NuGet.Versioning.psm1" '# Isolated synthetic installed identity, not a downloaded PowerShell package.'
    New-ModuleManifest -Path "$directory/NuGet.Versioning.psd1" -RootModule 'NuGet.Versioning.psm1' -ModuleVersion '6.12.0' -Guid ([guid]::NewGuid())
    Get-Module -ListAvailable -Name "$directory/NuGet.Versioning.psd1"
}

function Resolve-QualificationNonModuleRejection {
    param(
        [object]$Session,
        [System.Management.Automation.ErrorRecord]$Failure
    )

    if ($Failure.FullyQualifiedErrorId -match 'PMU\.(ModuleIdentityMismatch|VerificationFailed|GuidMismatch)') {
        $Session.Evidence.Outcome = 'NonModuleRejected'
        $Session.Evidence.RejectionId = $Matches[0]
        return
    }
    if ($Failure.FullyQualifiedErrorId -match 'PMU\.(DownloadFailed|DiscoveryFailed)') {
        $Session.Evidence.Outcome = 'ProviderLimitation'
        $Session.Evidence.PmuNonModuleValidation = 'NOT TESTED: provider rejected the package before PMU manifest validation.'
        return
    }
    throw 'Unexpected PMU nonmodule outcome; diagnostics withheld.'
}

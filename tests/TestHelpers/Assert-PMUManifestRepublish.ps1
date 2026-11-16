function Assert-PMUManifestRepublish {
    param([object]$Fixture)
    $plan = Get-PMURepublishPlan $Fixture
    $null = Get-PSModuleUpdateTargetManifest -Plan $plan -TrustRepository -AcceptLicense
    Initialize-PMUManifestFixture $Fixture '8.0.0' $plan.TargetVersion
    $failure = try {
        $null = Install-PSModuleUpdate -Update $plan -TrustRepository -AcceptLicense -Confirm:$false
    } catch {
        $_
    }
    Assert-PMUManifestRepublishFailure $plan $failure
}

function Get-PMURepublishPlan {
    param([object]$Fixture)
    $version = '2.0.0-preview3'
    Initialize-PMULocalPackage $Fixture $version
    Initialize-PMUManifestFixture $Fixture '7.0.0' $version
    $path = Join-Path $Fixture.Module.ModuleBase "$($Fixture.Name).psd1"
    $module = Get-Module -ListAvailable $path
    $uri = [uri]::new([IO.Path]::GetFullPath($Fixture.Feed), [UriKind]::Absolute)
    Get-PSModuleUpdate -Module $module -RepositoryUri $uri -Policy @{
        Channel = 'IncludePrerelease'
    }
}

function Assert-PMUManifestRepublishFailure {
    param(
        [object]$Plan,
        [object]$Failure
    )
    if (-not $Failure -or $Failure.FullyQualifiedErrorId -cne 'PMU.TargetManifestChanged') {
        throw 'A republished manifest was not rejected by the built installer.'
    }
    $installed = Import-PowerShellDataFile -LiteralPath $Plan.InstalledManifestPath
    $version = "$($installed.ModuleVersion)-$($installed.PrivateData.PSData.Prerelease)"
    if ($version -cne $Plan.InstalledVersion) {
        throw 'Rejected inspected content mutated the installed target.'
    }
}

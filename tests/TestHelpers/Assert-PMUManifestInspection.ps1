function Assert-PMUManifestInspection {
    param(
        [object]$Plan,
        [object]$Fixture
    )
    $snapshot = ConvertTo-Json $Plan -Depth 12 -Compress
    $target = Get-PSModuleUpdateTargetManifest -Plan $Plan -TrustRepository -AcceptLicense
    Assert-PMUManifestCandidate $target $Plan $Fixture $snapshot
    $result = Install-PSModuleUpdate -Update $Plan -TrustRepository -AcceptLicense -Confirm:$false
    Assert-PMUManifestInstallation $result $target.Version
    Assert-PMUManifestRepublish $Fixture
    Write-PMUManifestFixtureResult $target.Version $result.Outcome
}

function Write-PMUManifestFixtureResult {
    param(
        [string]$Version,
        [string]$Outcome
    )
    [pscustomobject]@{
        Version = $Version
        Outcome = $Outcome
    } | ConvertTo-Json -Compress
}

function Assert-PMUManifestCandidate {
    param(
        [object]$Target,
        [object]$Plan,
        [object]$Fixture,
        [string]$Snapshot
    )
    if ($Target.Version -cne '2.0.0-preview2' -or $Target.Manifest.PrivateData.Gerber.MinimumGerberVersion -cne '7.0.0') {
        throw 'The public inspection substituted a different manifest.'
    }
    if ($snapshot -cne (ConvertTo-Json $Plan -Depth 12 -Compress) -or (Get-Module -Name $Fixture.Name)) {
        throw 'Inspection modified the plan or loaded the target.'
    }
}

function Assert-PMUManifestInstallation {
    param(
        [object]$Result,
        [string]$Version
    )
    if ($Result.VerificationStatus -cne 'Verified' -or $Result.InstalledVersion -cne $Version) {
        throw 'Unchanged inspected native installation did not verify.'
    }
}

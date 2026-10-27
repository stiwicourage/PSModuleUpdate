function Invoke-PMULocalRelease {
    param(
        [object]$Fixture,
        [string]$Version
    )

    Initialize-PMULocalPackage $Fixture $Version
    $selection = Get-PMULocalSelection $Fixture $Version
    $plan = Get-PSModuleUpdate -Module $Fixture.Module @selection -Policy @{ Channel = 'IncludePrerelease' }
    if (-not $plan.RequiresLicenseAcceptance) {
        throw 'The real licensed fixture must expose its explicit license prerequisite.'
    }
    $preview = $plan | Install-PSModuleUpdate -WhatIf
    if ($preview.Outcome -ne 'WhatIf') {
        throw 'Built-module WhatIf did not return the expected outcome.'
    }
    Assert-PMULicenseConsent $plan
    $result = $plan | Install-PSModuleUpdate -AcceptLicense -TrustRepository -Confirm:$false
    if ($result.TargetVersion -cne $Version) {
        throw 'The local provider substituted a different target.'
    }
    if ($null -ne $result.ActiveVersion) {
        throw 'An unloaded reference must not be reported as session-active.'
    }
    $result
}

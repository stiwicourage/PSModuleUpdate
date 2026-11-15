BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Get-BoundTargetManifest' -Tag 'PMU', 'PMUTargetManifest' {
    It 'does not acquire an exact target without rechecked license consent' {
        Mock Assert-ExactTarget {
        }
        Mock Assert-InstallationConsent {
            Write-PMUError 'PMU.LicenseAcceptanceRequired' 'Acceptance required.'
        }
        Mock Invoke-ManifestAcquisition {
        }
        {
            Get-BoundTargetManifest ([pscustomobject]@{
                })
        } | Should -Throw -ErrorId PMU.LicenseAcceptanceRequired
        Should -Invoke Invoke-ManifestAcquisition -Times 0
    }
}

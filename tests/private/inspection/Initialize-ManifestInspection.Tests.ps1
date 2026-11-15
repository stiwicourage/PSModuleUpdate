BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Initialize-ManifestInspection' -Tag 'PMU', 'PMUTargetManifest' {
    It 'checks consent before creating an inspection workspace' {
        Mock Initialize-InstallationRequest {
            [pscustomobject]@{
                Consent = $Consent
            }
        }
        Mock Assert-InstallationConsent {
            Write-PMUError 'PMU.RepositoryTrustRequired' 'Approval required.'
        }
        Mock ConvertTo-ManifestInspectionOperation {
        }
        {
            Initialize-ManifestInspection ([pscustomobject]@{
                }) $null $false $false
        } | Should -Throw -ErrorId PMU.RepositoryTrustRequired
        Should -Invoke ConvertTo-ManifestInspectionOperation -Times 0
    }
}

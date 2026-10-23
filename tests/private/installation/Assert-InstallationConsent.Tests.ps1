BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-InstallationConsent' -Tag 'PMU' {
    It 'keeps trust, license, and credentials independent from confirmation' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Record.RequiresCredential = $true
        { Assert-InstallationConsent $operation } | Should -Throw -ErrorId 'PMU.AuthenticationFailed'
        $operation.Record.RequiresCredential = $false
        $operation.Plan.RequiresLicenseAcceptance = $true
        $operation.Consent.AcceptLicense = $false
        { Assert-InstallationConsent $operation } | Should -Throw -ErrorId 'PMU.LicenseAcceptanceRequired'
        $operation.Plan.RequiresLicenseAcceptance = $false
        $operation.Plan.RequiresRepositoryTrust = $true
        $operation.Consent.TrustRepository = $false
        { Assert-InstallationConsent $operation } | Should -Throw -ErrorId 'PMU.RepositoryTrustRequired'
    }
}

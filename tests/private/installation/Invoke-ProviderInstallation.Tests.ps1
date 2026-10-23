BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Invoke-ProviderInstallation' -Tag 'PMU' {
    It 'records Verification and Completed only after independently verifying provider output' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        Mock Assert-RepositoryBinding {}
        Mock Install-ProviderResource {}
        Mock Assert-InstalledPackage {}
        Invoke-ProviderInstallation $operation @()
        Should -Invoke Assert-InstalledPackage -Times 1
        $operation.Journal.State | Should -Be 'Completed'
    }
}

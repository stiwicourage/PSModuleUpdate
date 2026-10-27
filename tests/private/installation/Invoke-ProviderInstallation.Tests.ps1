BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    function Assert-NativeRepositoryBinding {
    }
}
Describe 'Invoke-ProviderInstallation' -Tag 'PMU' {
    It 'leaves verified native output in Verification for the reacquired parent to complete' -Tag 'PMUNativeHandoff' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        Mock Assert-RepositoryBinding {}
        Mock Assert-NativeRepositoryBinding {}
        Mock Install-ProviderResource {}
        Mock Assert-InstalledPackage {}
        Invoke-ProviderInstallation $operation @()
        Should -Invoke Assert-InstalledPackage -Times 1
        $operation.Journal.State | Should -Be 'Verification'
    }
}

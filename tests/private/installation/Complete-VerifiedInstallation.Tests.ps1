BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Complete-VerifiedInstallation' -Tag 'PMU' {
    Context 'Verified idempotent result' {
        It 'verifies an existing target without reinstalling it' {
            $operation = Initialize-PMUTestOperation $TestDrive
            Mock Assert-InstalledPackage {}
            Mock Clear-CompletedOperation {}
            Mock Install-ProviderResource {}
            $result = Complete-VerifiedInstallation $operation @() $true
            $result.Outcome | Should -Be 'AlreadyInstalled'
            Should -Invoke Assert-InstalledPackage -Times 1
            Should -Invoke Install-ProviderResource -Times 0
        }
    }
}

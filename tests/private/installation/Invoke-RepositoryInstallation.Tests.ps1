BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Invoke-RepositoryInstallation' -Tag 'PMUUriBridge' {
    Context 'Close on installation failure' {
        It 'closes its transport with the original failure after the scoped workflow fails' {
            $operation = Initialize-PMUTestOperation $TestDrive
            Mock Open-RepositoryTransport { [pscustomobject]@{ Name = 'OwnedTransport' } }
            Mock Invoke-ScopedInstallation { Write-PMUError 'PMU.InstallationFailed' 'Safe fixture failure.' }
            Mock Close-RepositoryTransport { }
            { Invoke-RepositoryInstallation $operation } | Should -Throw -ErrorId 'PMU.InstallationFailed*'
            Should -Invoke Close-RepositoryTransport -Times 1 -ParameterFilter { $Original.FullyQualifiedErrorId -like 'PMU.InstallationFailed*' }
        }
    }
}

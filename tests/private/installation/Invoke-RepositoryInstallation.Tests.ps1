BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Invoke-RepositoryInstallation' -Tag 'PMUUriBridge' {
    It 'opens the exact planned source and closes the leased transport after installation' {
        $script:installationOperation = Initialize-PMUTestOperation $TestDrive
        $script:transportLease = [pscustomobject]@{ Name = 'OwnedTransport' }
        Mock Open-RepositoryTransport { $script:transportLease }
        Mock Invoke-ScopedInstallation {}
        Mock Close-RepositoryTransport {}

        Invoke-RepositoryInstallation $installationOperation

        $installationOperation.RepositoryName | Should -BeExactly 'OwnedTransport'
        Should -Invoke Open-RepositoryTransport -Times 1 -Exactly -ParameterFilter {
            $Source.Name -ceq $script:installationOperation.Plan.RepositoryName -and
            $Source.Uri -ceq $script:installationOperation.Plan.RepositoryUri -and
            $Source.ApiVersion -ceq $script:installationOperation.Plan.RepositoryApiVersion -and
            $Source.Trusted -eq $script:installationOperation.Plan.RepositoryTrusted
        }
        Should -Invoke Invoke-ScopedInstallation -Times 1 -Exactly -ParameterFilter {
            [object]::ReferenceEquals($Operation, $script:installationOperation)
        }
        Should -Invoke Close-RepositoryTransport -Times 1 -Exactly -ParameterFilter {
            [object]::ReferenceEquals($Lease, $script:transportLease) -and $null -eq $Original
        }
    }

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

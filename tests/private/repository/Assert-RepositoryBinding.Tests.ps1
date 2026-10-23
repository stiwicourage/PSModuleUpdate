BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-RepositoryBinding' -Tag 'PMU', 'PMURepositoryUri' {
    Context 'Immutable source binding' {
        It 'accepts the exact registered snapshot and rejects changed trust' {
            $operation = Initialize-PMUTestOperation $TestDrive
            $script:bindingSource = $operation.TestContext.Source
            Mock Get-RepositorySnapshot { $script:bindingSource }
            { Assert-RepositoryBinding $operation.Plan } | Should -Not -Throw
            $script:bindingSource.Trusted = $false
            { Assert-RepositoryBinding $operation.Plan } | Should -Throw -ErrorId 'PMU.RepositoryChanged'
        }
    }
}

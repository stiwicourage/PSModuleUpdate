BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-OperationRepositoryName' -Tag 'PMUUriBridge' {
    Context 'Ephemeral transport binding' {
        It 'uses the operation lease without changing the immutable plan source' {
            $operation = [pscustomobject]@{
                RepositoryName = 'pmu-uri-owned'
                Plan = [pscustomobject]@{ RepositoryName = $null }
            }
            Get-OperationRepositoryName $operation | Should -Be 'pmu-uri-owned'
            $operation.Plan.RepositoryName | Should -BeNullOrEmpty
        }
    }
}

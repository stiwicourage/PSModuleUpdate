BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Assert-RepositoryBinding' -Tag 'PMU', 'PMURepositoryUri' {
    Context 'Immutable source binding' {
        It 'validates an anonymous URI without looking up a named registration' {
            $operation = Initialize-PMUTestOperation $TestDrive
            $operation.Plan.RepositoryName = ''
            Mock Get-RepositorySnapshot { throw 'Named lookup must not run.' }

            @(Assert-RepositoryBinding $operation.Plan '').Count | Should -Be 0

            Should -Invoke Get-RepositorySnapshot -Times 0 -Exactly
        }

        It 'uses the plan name for an empty transport name and honors a transport override' -TestCases @(
            @{
                TransportName = ''
                ExpectedName = 'plan-source'
            }
            @{
                TransportName = 'transport-source'
                ExpectedName = 'transport-source'
            }
        ) {
            param($TransportName, $ExpectedName)

            $operation = Initialize-PMUTestOperation $TestDrive
            $operation.Plan.RepositoryName = 'plan-source'
            $script:bindingSource = $operation.TestContext.Source
            $script:bindingSource.Name = $ExpectedName
            Mock Get-RepositorySnapshot { $script:bindingSource }
            Assert-RepositoryBinding $operation.Plan $TransportName
            Should -Invoke Get-RepositorySnapshot -Times 1 -Exactly -ParameterFilter {
                $Name -eq $ExpectedName
            }
        }
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

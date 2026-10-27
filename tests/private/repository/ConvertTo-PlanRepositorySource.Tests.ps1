BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'ConvertTo-PlanRepositorySource' -Tag 'PMURepositoryUri' {
    It 'preserves source field order, types and anonymous values without leaking plan fields' {
        $uri = [uri]'https://feed.example.invalid/approved'
        $plan = [pscustomobject]@{
            RepositoryName = $null
            RepositoryUri = $uri
            RepositoryApiVersion = $null
            RepositoryTrusted = $false
            InternalMarker = 'not-a-source-field'
        }

        $source = ConvertTo-PlanRepositorySource $plan

        @($source.PSObject.Properties.Name) | Should -Be @('Name', 'Uri', 'ApiVersion', 'Trusted')
        $source.Name | Should -BeNullOrEmpty
        $source.ApiVersion | Should -BeNullOrEmpty
        [object]::ReferenceEquals($source.Uri, $uri) | Should -BeTrue
        $source.Trusted | Should -BeOfType ([bool])
        $source.Trusted | Should -BeFalse
    }

    It 'uses the planned name for an empty override and honors a nonempty transport name' -ForEach @(
        @{ Override = ''; Expected = 'PlanFeed' }
        @{ Override = 'OwnedTransport'; Expected = 'OwnedTransport' }
    ) {
        $plan = [pscustomobject]@{
            RepositoryName = 'PlanFeed'
            RepositoryUri = 'https://feed.example.invalid/approved'
            RepositoryApiVersion = 'V3'
            RepositoryTrusted = $true
        }

        $source = ConvertTo-PlanRepositorySource $plan $Override

        $source.Name | Should -BeExactly $Expected
        $plan.RepositoryName | Should -BeExactly 'PlanFeed'
        $source.ApiVersion | Should -BeExactly 'V3'
        $source.Trusted | Should -BeTrue
    }
}

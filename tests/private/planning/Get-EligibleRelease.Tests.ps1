BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-EligibleRelease' -Tag 'PMU' {
    Context 'Stable plus prerelease policy' {
        It 'retains stable releases in IncludePrerelease' {
            $release = [pscustomobject]@{ Version = ConvertTo-CompleteModuleVersion '2.0.0' }
            @(Get-EligibleRelease @($release) 'IncludePrerelease').Count | Should -Be 1
        }
    }
}

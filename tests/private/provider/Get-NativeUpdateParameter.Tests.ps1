BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-NativeUpdateParameter' -Tag 'PMU', 'PMUNativeAdapter' {
    It 'bounds only a same-numeric-base prerelease to stable promotion' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Plan.TargetVersion = '2.0.0'
        $operation.Plan.TargetIsPrerelease = $false
        $parameters = Get-NativeUpdateParameter $operation
        $parameters.MaximumVersion | Should -BeExactly '2.0.0'
        $parameters.ContainsKey('RequiredVersion') | Should -BeFalse
        $parameters.ContainsKey('AllowPrerelease') | Should -BeFalse
        $parameters.ContainsKey('Repository') | Should -BeFalse
        $parameters.ContainsKey('Force') | Should -BeFalse
    }
    It 'retains a literal exact requirement for every other approved target' -ForEach @(
        @{
            Installed = '2.0.0-preview.1'
            Target = '2.0.0-preview.2'
            Numeric = '2.0.0'
            Prerelease = $true
        }
        @{
            Installed = '2.0.0-preview.1'
            Target = '3.0.0'
            Numeric = '3.0.0'
            Prerelease = $false
        }
        @{
            Installed = '2.0.0'
            Target = '3.0.0'
            Numeric = '3.0.0'
            Prerelease = $false
        }
        @{
            Installed = '2.0.0'
            Target = '4.0.0.7'
            Numeric = '4.0.0.7'
            Prerelease = $false
        }
    ) {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Plan.InstalledVersion = $Installed
        $operation.Plan.TargetVersion = $Target
        $operation.Plan.TargetNumericVersion = $Numeric
        $operation.Plan.TargetIsPrerelease = $Prerelease
        $parameters = Get-NativeUpdateParameter $operation
        $parameters.RequiredVersion | Should -BeExactly $Target
        $parameters.ContainsKey('MaximumVersion') | Should -BeFalse
        $parameters.Scope | Should -BeExactly 'CurrentUser'
        $parameters.ContainsKey('Repository') | Should -BeFalse
    }
}

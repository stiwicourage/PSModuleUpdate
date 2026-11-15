BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-NativeInstallParameter' -Tag 'PMU', 'PMUUnmanaged' {
    It 'retains exact prerelease version, scope, source and credential for Collision=<Collision>' -ForEach @(
        @{ Collision = $false }
        @{ Collision = $true }
    ) {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.RepositoryName = 'ApprovedFeed'
        $operation.Credential = [pscredential]::new('fixture', [securestring]::new())
        if (-not $Collision) {
            $operation.Plan.TargetInstalledPath = Join-Path $TestDrive 'absent'
        }
        $parameters = Get-NativeInstallParameter $operation
        $parameters.Name | Should -BeExactly $operation.Plan.ModuleName
        $parameters.RequiredVersion | Should -BeExactly $operation.Plan.TargetVersion
        $parameters.AllowPrerelease | Should -BeTrue
        $parameters.AcceptLicense | Should -BeTrue
        $parameters.Repository | Should -BeExactly 'ApprovedFeed'
        $parameters.Scope | Should -BeExactly 'CurrentUser'
        $parameters.Credential | Should -Be $operation.Credential
        $parameters.ContainsKey('Force') | Should -Be $Collision
    }
    It 'keeps the exact stable target for a same-base promotion' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Plan.TargetVersion = '2.0.0'
        $operation.Plan.TargetIsPrerelease = $false
        $parameters = Get-NativeInstallParameter $operation
        $parameters.RequiredVersion | Should -BeExactly '2.0.0'
        $parameters.AllowPrerelease | Should -BeFalse
        $parameters.ContainsKey('MaximumVersion') | Should -BeFalse
    }
}

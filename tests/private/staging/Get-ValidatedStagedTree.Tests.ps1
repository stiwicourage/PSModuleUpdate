BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Get-ValidatedStagedTree' -Tag 'PMU', 'PMUTargetManifest' {
    It 'returns the validated exact package inventory without importing its throwing root module' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $null = Initialize-PMUTestPackage $operation.StageRoot $operation.Plan.TargetVersion
        $tree = @(Get-ValidatedStagedTree $operation)
        $tree.Count | Should -Be 2
        @(Get-Module FixtureModule).Count | Should -Be 0
    }
    It 'rejects a manifest-only extraction without publishing an incomplete inventory' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $null = Initialize-PMUTestPackage $operation.StageRoot $operation.Plan.TargetVersion
        $manifest = Join-Path $operation.StagedPath 'FixtureModule.psd1'
        $definition = [IO.File]::ReadAllText($manifest).Replace("RootModule = 'FixtureModule.psm1';", '')
        [IO.File]::WriteAllText($manifest, $definition)
        Remove-Item -LiteralPath (Join-Path $operation.StagedPath 'FixtureModule.psm1')
        { Get-ValidatedStagedTree $operation } | Should -Throw -ErrorId 'PMU.VerificationFailed' -ExpectedMessage 'The extracted module tree is incomplete.'
    }
}

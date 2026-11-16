BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Clear-StagingRoot' -Tag 'PMU' {
    It 'rejects an operation whose staging path was substituted outside its workspace' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.StageRoot = $TestDrive
        { Clear-StagingRoot $operation } | Should -Throw -ErrorId 'PMU.RecoveryRequired'
        Test-Path $operation.Plan.InstalledManifestPath | Should -BeTrue
    }
    It 'removes an inventoried staging tree without touching the installed module' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $null = Initialize-PMUTestPackage $operation.StageRoot $operation.Plan.TargetVersion
        Clear-StagingRoot $operation
        Test-Path -LiteralPath $operation.StageRoot | Should -BeFalse
        Test-Path -LiteralPath $operation.Plan.InstalledManifestPath | Should -BeTrue
    }
    It 'leaves staging intact when safe inventory validation rejects the tree' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $null = Initialize-PMUTestPackage $operation.StageRoot $operation.Plan.TargetVersion
        Mock Get-FileTreeInventory { throw [IO.IOException]::new('Unsafe staged inventory.') }
        { Clear-StagingRoot $operation } | Should -Throw -ExpectedMessage 'Unsafe staged inventory.'
        Test-Path -LiteralPath $operation.StagedPath -PathType Container | Should -BeTrue
        Test-Path -LiteralPath $operation.Plan.InstalledManifestPath | Should -BeTrue
    }
    It 'does not create staging when the expected directory is absent' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Clear-StagingRoot $operation
        Test-Path -LiteralPath $operation.StageRoot | Should -BeFalse
    }
}

BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Clear-ManifestInspection' -Tag 'PMU', 'PMUTargetManifest' {
    It 'clears owned files and drops the per-call credential' {
        $operation = ConvertTo-ManifestInspectionOperation (Initialize-PMUTestOperation $TestDrive)
        Initialize-ControlledDirectory $operation.WorkRoot
        [IO.File]::WriteAllText((Join-Path $operation.WorkRoot 'owned.txt'), 'fixture')
        $operation.Credential = [pscredential]::new('fixture', [securestring]::new())
        Clear-ManifestInspection $operation
        Test-Path $operation.WorkRoot | Should -BeFalse
        $operation.Credential | Should -BeNullOrEmpty
        {
            Clear-ManifestInspection $operation
        } | Should -Not -Throw
    }
    It 'fails closed rather than removing an unexpected workspace' {
        $operation = ConvertTo-ManifestInspectionOperation (Initialize-PMUTestOperation $TestDrive)
        $operation.WorkRoot = $TestDrive
        {
            Clear-ManifestInspection $operation
        } | Should -Throw -ErrorId PMU.RecoveryRequired
        Test-Path $TestDrive | Should -BeTrue
    }
}

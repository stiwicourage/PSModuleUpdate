BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Initialize-StagedPackage' -Tag 'PMU' {
    BeforeEach { Mock Assert-RepositoryBinding {} }
    It 'rejects an incomplete staged manifest without invoking provider installation' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Mock Save-ProviderResource {}
        Mock Install-ProviderResource {}
        { Initialize-StagedPackage $operation } | Should -Throw -ErrorId 'PMU.ModuleIdentityMismatch'
        Should -Invoke Install-ProviderResource -Times 0
    }
    It 'discards only owned stale staging before a fresh exact save' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Initialize-ControlledDirectory $operation.StageRoot
        [IO.File]::WriteAllText("$($operation.StageRoot)/leftover.txt", 'stale')
        Mock Save-ProviderResource {
            $null = Initialize-PMUTestPackage $Operation.StageRoot '2.0.0-preview.2'
        }
        $null = Initialize-StagedPackage $operation
        Test-Path "$($operation.StageRoot)/leftover.txt" | Should -BeFalse
    }
}

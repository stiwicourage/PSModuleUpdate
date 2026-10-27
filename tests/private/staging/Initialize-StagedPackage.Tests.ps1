BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    function Assert-NativeRepositoryBinding {
    }
}
Describe 'Initialize-StagedPackage' -Tag 'PMU' {
    BeforeEach {
        Mock Assert-RepositoryBinding {}
        Mock Assert-NativeRepositoryBinding {}
    }
    It 'checks the isolated native source before downloading any staged tree' -Tag 'PMUNativeHandoff' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Mock Assert-NativeRepositoryBinding { Write-PMUError 'PMU.SourceMismatch' 'fixture mismatch' }
        Mock Save-ProviderResource {}
        { Initialize-StagedPackage $operation } | Should -Throw -ErrorId 'PMU.SourceMismatch'
        Should -Invoke Save-ProviderResource -Times 0
    }
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

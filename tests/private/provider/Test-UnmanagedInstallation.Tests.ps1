BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Test-UnmanagedInstallation' -Tag 'PMU', 'PMUUnmanaged' {
    BeforeEach {
        $operation = Initialize-PMUTestOperation $TestDrive
        $script:selectedPath = Split-Path -Parent $operation.Plan.InstalledManifestPath
    }
    It 'requires explicit consent for the selected original path with no record' {
        Test-UnmanagedInstallation $operation $selectedPath | Should -BeFalse
        $operation.Consent.ReplaceUnmanagedInstallation = $true
        Test-UnmanagedInstallation $operation $selectedPath | Should -BeTrue
        Test-UnmanagedInstallation $operation (Join-Path $TestDrive 'other') | Should -BeFalse
    }
    It 'never classifies a present unreadable record as unmanaged' {
        $operation.Consent.ReplaceUnmanagedInstallation = $true
        [IO.File]::WriteAllText((Join-Path $selectedPath 'PSGetModuleInfo.xml'), 'not XML')
        Test-UnmanagedInstallation $operation $selectedPath | Should -BeFalse
    }
}

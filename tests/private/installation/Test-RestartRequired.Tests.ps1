BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Test-RestartRequired' -Tag 'PMU' {
    It 'does not request restart for an unrelated already-newer loaded copy of an unloaded target' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $path = Initialize-PMUTestPackage "$TestDrive/OtherModules" '3.0.0'
        $script:newerLoaded = Get-Module -ListAvailable "$path/FixtureModule.psd1"
        Mock Get-Module { $script:newerLoaded }
        Test-RestartRequired $operation.Plan 'Installed' | Should -BeFalse
    }
    It 'requires restart when loaded files were replaced even with unchanged version text' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $script:loadedFixture = [pscustomobject]@{
            ModuleBase = $operation.Plan.TargetInstalledPath
            Guid = $operation.Plan.ModuleGuid
        }
        Mock Get-Module { $script:loadedFixture }
        $operation.Plan.ActiveVersion = $operation.Plan.TargetVersion
        Test-RestartRequired $operation.Plan 'Installed' | Should -BeTrue
        Mock Get-Module { @() }
        Test-RestartRequired $operation.Plan 'Installed' | Should -BeFalse
    }
}

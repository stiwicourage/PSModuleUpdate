BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Test-InstalledPlanState' -Tag 'PMU' {
    It 'rejects a selected installed version changed after planning' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Mock Get-InstalledModuleIdentityList { [pscustomobject]@{
                FullVersion = '9.0.0'
                Guid = [guid]'a1111111-1111-1111-1111-111111111111'
            } }
        { Test-InstalledPlanState $operation } | Should -Throw -ErrorId 'PMU.InstalledStateChanged'
    }
}

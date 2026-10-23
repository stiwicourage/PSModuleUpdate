BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-ManifestModuleVersion' -Tag 'PMU' {
    Context 'Complete identity' {
        It 'retains a stable four-component manifest version' {
            (Get-ManifestModuleVersion @{ ModuleVersion = '1.2.3.4' }).FullVersion | Should -Be '1.2.3.4'
        }
    }
}

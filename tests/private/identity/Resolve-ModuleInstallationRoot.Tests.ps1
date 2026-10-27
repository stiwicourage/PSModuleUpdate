BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Resolve-ModuleInstallationRoot' -Tag 'PMU' {
    It 'resolves distinct scope destinations without writing either root' {
        $user = Resolve-ModuleInstallationRoot 'CurrentUser'
        $all = Resolve-ModuleInstallationRoot 'AllUsers'
        $user | Should -Not -Be $all
        if (-not $IsWindows) {
            $all | Should -Be '/usr/local/share/powershell/Modules'
        }
    }
}

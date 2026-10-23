BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Resolve-PMUDataRoot' -Tag 'PMU' {
    It 'uses scope-specific state locations outside module trees without creating them' {
        $user = Resolve-PMUDataRoot 'CurrentUser'
        $all = Resolve-PMUDataRoot 'AllUsers'
        $user | Should -Not -Be $all
        $user | Should -Not -Match '[/\\]Modules[/\\]'
        $all | Should -Not -Match '[/\\]Modules[/\\]'
    }
}

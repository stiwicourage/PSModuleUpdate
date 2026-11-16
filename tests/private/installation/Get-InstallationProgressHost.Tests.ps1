BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-InstallationProgressHost' -Tag 'PMU', 'PMUProgress' {
    Context 'Native host facts' {
        It 'reports native redirection and command-line interactivity without changing either' {
            $expectedRedirection = [Console]::IsOutputRedirected
            $expectedInteractivity = [Environment]::GetCommandLineArgs() -contains '-NonInteractive'
            $hostState = Get-InstallationProgressHost
            $hostState.OutputRedirected | Should -Be $expectedRedirection
            $hostState.NonInteractive | Should -Be $expectedInteractivity
            [Console]::IsOutputRedirected | Should -Be $expectedRedirection
        }
    }
}

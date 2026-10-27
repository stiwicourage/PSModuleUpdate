BeforeAll {
    . "$PSScriptRoot/../TestHelpers/Receive-PMUChildProcess.ps1"
    . "$PSScriptRoot/../TestHelpers/Invoke-PMULocalProviderProcess.ps1"
    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:builtModule = Join-Path $root 'dist/PSModuleUpdate/PSModuleUpdate.psd1'
}
Describe 'PMU isolated native Update-Module qualification' -Tag 'Integration', 'PMULocalProvider' {
    It 'performs licensed offline prerelease progression, stable promotion and four-component installation' -Skip:(-not $IsMacOS) {
        $fixture = Join-Path $TestDrive 'local-provider'
        $result = Invoke-PMULocalProviderProcess $fixture $builtModule
        $result.ExitCode | Should -Be 0 -Because $result.Error
        $result.Output | Should -Match 'from file:/{3}.+ into CurrentUser'
        $results = @($result.Output.Trim().Split("`n")[-1] | ConvertFrom-Json)
        $results.Count | Should -Be 5
        @($results.InstalledVersion) | Should -Be @('2.0.0-preview2', '2.0.0-preview3', '2.0.0', '3.0.0', '4.0.0.7')
        @($results.Outcome | Select-Object -Unique) | Should -Be @('Installed')
    }
}

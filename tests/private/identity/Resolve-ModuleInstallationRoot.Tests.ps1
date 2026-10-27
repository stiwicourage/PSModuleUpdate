BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Resolve-ModuleInstallationRoot' -Tag 'PMU', 'PMUCoverageFollowUp' {
    It 'resolves distinct scope destinations without writing either root' {
        $user = Resolve-ModuleInstallationRoot 'CurrentUser'
        $all = Resolve-ModuleInstallationRoot 'AllUsers'
        $user | Should -Not -Be $all
        if (-not $IsWindows) {
            $all | Should -Be '/usr/local/share/powershell/Modules'
        }
    }
    It 'resolves Windows AllUsers modules beneath ProgramFiles without creating the root' {
        $originalWindows = $IsWindows
        $originalProgramFiles = $env:ProgramFiles
        try {
            Set-Variable IsWindows $true -Force
            $env:ProgramFiles = Join-Path $TestDrive 'Program Files'
            $expected = Join-Path $env:ProgramFiles 'PowerShell/Modules'
            Mock Assert-SafePath { $Path }
            Resolve-ModuleInstallationRoot 'AllUsers' | Should -BeExactly $expected
            Should -Invoke Assert-SafePath -Times 1 -Exactly -ParameterFilter { $Path -ceq $expected }
            Test-Path $env:ProgramFiles | Should -BeFalse
        } finally {
            Set-Variable IsWindows $originalWindows -Force
            $env:ProgramFiles = $originalProgramFiles
        }
    }
}

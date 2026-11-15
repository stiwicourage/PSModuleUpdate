BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Resolve-ModuleInstallationRoot' -Tag 'PMU', 'PMUCoverageFollowUp', 'PMUInstallationRoot' {
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
    It 'routes Windows CurrentUser modules through the native Documents folder and path safety validation' {
        # Unit routing only: the controlled Join-Path result is not Windows filesystem qualification.
        $originalWindows = $IsWindows
        $nativeDocuments = Join-Path $TestDrive 'Documents'
        $expectedRoot = Join-Path $nativeDocuments 'PowerShell/Modules'
        $safePathCommand = (Get-Command Assert-SafePath).ScriptBlock
        Mock Get-WindowsDocumentsPath { $nativeDocuments }
        Mock Assert-SafePath { & $safePathCommand $Path }
        Mock Join-Path { $expectedRoot } -ParameterFilter {
            $Path -ceq $nativeDocuments -and $ChildPath -ceq 'PowerShell/Modules'
        }
        try {
            Set-Variable IsWindows $true -Force
            Resolve-ModuleInstallationRoot 'CurrentUser' | Should -BeExactly $expectedRoot
            Should -Invoke Join-Path -Times 1 -Exactly -ParameterFilter {
                $Path -ceq $nativeDocuments -and $ChildPath -ceq 'PowerShell/Modules'
            }
            Should -Invoke Assert-SafePath -Times 1 -Exactly -ParameterFilter { $Path -ceq $expectedRoot }
            Should -Invoke Get-WindowsDocumentsPath -Times 1 -Exactly
            Test-Path -LiteralPath $expectedRoot | Should -BeFalse
        } finally {
            Set-Variable IsWindows $originalWindows -Force
        }
    }
    It 'rejects an empty Windows Documents fact before path safety instead of selecting another root' {
        $originalWindows = $IsWindows
        Mock Get-WindowsDocumentsPath { '' }
        Mock Assert-SafePath { throw 'An unbound path must not reach path safety validation.' }
        try {
            Set-Variable IsWindows $true -Force
            $failure = { Resolve-ModuleInstallationRoot 'CurrentUser' } |
                Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException]) -PassThru
            $failure.Exception.GetType().FullName | Should -BeExactly 'System.Management.Automation.ParameterBindingValidationException'
            $failure.FullyQualifiedErrorId | Should -BeExactly 'ParameterArgumentValidationErrorEmptyStringNotAllowed,Microsoft.PowerShell.Commands.JoinPathCommand'
            Should -Invoke Assert-SafePath -Times 0 -Exactly
        } finally {
            Set-Variable IsWindows $originalWindows -Force
        }
    }
}

BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-WindowsDocumentsPath' -Tag 'PMU', 'PMUInstallationRoot' {
    Context 'Installation-root integration' {
        It 'supplies its native fact to Windows CurrentUser routing without filesystem writes' {
            $nativeDocuments = Get-WindowsDocumentsPath
            $expectedRoot = Join-Path $TestDrive 'native-documents/PowerShell/Modules'
            $originalWindows = $IsWindows
            Mock Join-Path { $expectedRoot } -ParameterFilter {
                $Path -ceq $nativeDocuments -and $ChildPath -ceq 'PowerShell/Modules'
            }
            try {
                Set-Variable IsWindows $true -Force
                if ([string]::IsNullOrEmpty($nativeDocuments)) {
                    { Resolve-ModuleInstallationRoot 'CurrentUser' } |
                        Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
                } else {
                    Resolve-ModuleInstallationRoot 'CurrentUser' | Should -BeExactly $expectedRoot
                    Should -Invoke Join-Path -Times 1 -Exactly -ParameterFilter {
                        $Path -ceq $nativeDocuments -and $ChildPath -ceq 'PowerShell/Modules'
                    }
                }
                Test-Path -LiteralPath $expectedRoot | Should -BeFalse
            } finally {
                Set-Variable IsWindows $originalWindows -Force
            }
        }
    }
}

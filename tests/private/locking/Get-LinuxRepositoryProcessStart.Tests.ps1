BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-LinuxRepositoryProcessStart' -Tag 'PMUUriBridge' {
    It 'reads a live kernel identity and reports a missing kernel PID without consulting a reconstructed date' {
        if ($IsLinux) {
            Get-LinuxRepositoryProcessStart $PID | Should -Match '^1[0-9]{17}$'
            Get-LinuxRepositoryProcessStart ([int]::MaxValue) | Should -BeNullOrEmpty
        } else {
            # The platform adapter must not consult procfs on other supported hosts.
            Mock Get-LinuxRepositoryProcessStart { throw 'Linux adapter must not run here.' }
            Get-PlatformRepositoryProcessStart $PID | Should -Match '^[0-9]{18}$'
            Should -Invoke Get-LinuxRepositoryProcessStart -Times 0
        }
    }
    It 'returns no kernel identity for a nonexistent PID on every supported host' {
        Get-LinuxRepositoryProcessStart ([int]::MaxValue) | Should -BeNullOrEmpty
    }
    Context 'Isolated proc snapshot' {
        BeforeEach {
            $procRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            $processRoot = Join-Path $procRoot '7'
            $null = New-Item -ItemType Directory -Path $processRoot -Force
            $processStat = Join-Path $processRoot 'stat'
            $bootStat = Join-Path $procRoot 'stat'
            [IO.File]::WriteAllText($processStat, ('7 (worker ) with spaces) S ' + ('0 ' * 18) + '12345 0 0'))
            [IO.File]::WriteAllText($bootStat, "cpu 0`nbtime 1790000000`n")
            Mock Get-LinuxClockTickFrequency { '100' }
        }
        It 'derives the receipt identity from the selected proc snapshot without rewriting it' {
            $hash = (Get-FileHash -LiteralPath $processStat).Hash
            Get-LinuxRepositoryProcessStart 7 $procRoot | Should -BeExactly '117900001234500000'
            (Get-FileHash -LiteralPath $processStat).Hash | Should -BeExactly $hash
        }
        It 'returns no owner when the selected process disappears before its stat is read' {
            Remove-Item -LiteralPath $processStat
            Get-LinuxRepositoryProcessStart 7 $procRoot | Should -BeNullOrEmpty
            Test-Path -LiteralPath $bootStat | Should -BeTrue
            Should -Invoke Get-LinuxClockTickFrequency -Times 0 -Exactly
        }
        It 'refuses a snapshot whose boot metadata disappeared instead of synthesizing a live owner' {
            Remove-Item -LiteralPath $bootStat
            $failure = { Get-LinuxRepositoryProcessStart 7 $procRoot } |
                Should -Throw -ExceptionType ([Management.Automation.MethodInvocationException]) -PassThru
            $failure.Exception.GetBaseException() | Should -BeOfType ([IO.FileNotFoundException])
            Test-Path -LiteralPath $processStat | Should -BeTrue
        }
        It 'preserves process evidence when the clock command fails' {
            Mock Get-LinuxClockTickFrequency { throw [IO.InvalidDataException]::new('Clock frequency unavailable.') }
            { Get-LinuxRepositoryProcessStart 7 $procRoot } |
                Should -Throw -ExceptionType ([IO.InvalidDataException]) -ExpectedMessage 'Clock frequency unavailable.'
            Test-Path -LiteralPath $processStat | Should -BeTrue
            Test-Path -LiteralPath $bootStat | Should -BeTrue
        }
    }
}

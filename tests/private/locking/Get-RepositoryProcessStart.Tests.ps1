BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    $entry = "$PSScriptRoot/../../../src/private/locking/Get-RepositoryProcessStart.ps1"
    $sources = @($entry) + @(Get-PMUTestSourcePath $entry)
    $imports = $sources | ForEach-Object { ". '$($_.Replace("'", "''"))'" }
    $script:identityCommand = ($imports -join "`n") + "`nGet-RepositoryProcessStart $PID"
}
Describe 'Get-RepositoryProcessStart' -Tag 'PMUUriBridge', 'PMUCoverageFollowUp' {
    It 'returns no owner identity when the platform reports an absent process' {
        Mock Get-PlatformRepositoryProcessStart { throw [ArgumentException]::new('Process does not exist.') }
        Get-RepositoryProcessStart 1234 | Should -BeNullOrEmpty
        Should -Invoke Get-PlatformRepositoryProcessStart -Times 1 -Exactly -ParameterFilter { $ProcessId -eq 1234 }
    }

    It 'requires recovery when the platform cannot verify a receipt owner' {
        Mock Get-PlatformRepositoryProcessStart { throw [InvalidOperationException]::new('Untrusted process detail.') }
        { Get-RepositoryProcessStart 1234 } |
            Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired' -ExpectedMessage 'Cannot verify the repository receipt owner process.'
    }

    Context 'PID reuse resistant owner identity' {
        It 'reports an 18-digit current process identity and absence of a nonexistent PID' {
            Get-RepositoryProcessStart $PID | Should -Match '^[0-9]{18}$'
            Get-RepositoryProcessStart ([int]::MaxValue) | Should -BeNullOrEmpty
        }
        It 'reports exactly the same live parent identity from three fresh processes' {
            $expected = Get-RepositoryProcessStart $PID
            foreach ($observer in 1..3) {
                $child = [Diagnostics.Process]::Start((Get-PMUIdentityProbeStartInfo $identityCommand))
                try {
                    $result = Receive-PMUChildProcess $child
                    $result.ExitCode | Should -Be 0 -Because $result.Error
                    $result.Output.Trim() | Should -BeExactly $expected
                } finally {
                    Close-PMUChildProcess @($child)
                }
            }
        }
        It 'reports absence after a known live process exits' {
            $child = [Diagnostics.Process]::Start((Get-PMUIdentityProbeStartInfo '$null = [Console]::In.ReadLine()'))
            try {
                Get-RepositoryProcessStart $child.Id | Should -Match '^[0-9]{18}$'
                $child.Kill()
                $child.WaitForExit(10000) | Should -BeTrue
                Get-RepositoryProcessStart $child.Id | Should -BeNullOrEmpty
            } finally {
                Close-PMUChildProcess @($child)
            }
        }
    }
}

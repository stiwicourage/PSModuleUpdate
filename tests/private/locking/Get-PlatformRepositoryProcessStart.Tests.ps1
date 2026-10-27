BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-PlatformRepositoryProcessStart' -Tag 'PMUUriBridge', 'PMUCoverage' {
    It 'preserves the native non-Linux process start timestamp and routes Linux to kernel metadata' {
        $process = [Diagnostics.Process]::GetCurrentProcess()
        try {
            if ($IsLinux) {
                Mock Get-LinuxRepositoryProcessStart { '117900001234500000' }
                Get-PlatformRepositoryProcessStart $PID | Should -BeExactly '117900001234500000'
                Should -Invoke Get-LinuxRepositoryProcessStart -Times 1 -ParameterFilter { $ProcessId -eq $PID }
            } else {
                Get-PlatformRepositoryProcessStart $PID | Should -BeExactly "$($process.StartTime.ToUniversalTime().Ticks)"
            }
        } finally {
            $process.Dispose()
        }
    }

    Context 'Platform routing' {
        BeforeEach {
            $script:originalLinux = $IsLinux
            Mock Get-LinuxRepositoryProcessStart { '117900001234500000' }
        }
        AfterEach {
            Set-Variable IsLinux $script:originalLinux -Force
        }

        It 'returns the Linux kernel timestamp without native timestamp conversion' {
            Set-Variable IsLinux $true -Force
            Get-PlatformRepositoryProcessStart $PID | Should -BeExactly '117900001234500000'
            Should -Invoke Get-LinuxRepositoryProcessStart -Times 1 -Exactly -ParameterFilter { $ProcessId -eq $PID }
        }

        It 'returns UTC start ticks without consulting Linux metadata on other platforms' {
            Set-Variable IsLinux $false -Force
            $process = [Diagnostics.Process]::GetCurrentProcess()
            try {
                Get-PlatformRepositoryProcessStart $PID | Should -BeExactly "$($process.StartTime.ToUniversalTime().Ticks)"
                Should -Invoke Get-LinuxRepositoryProcessStart -Times 0
            } finally {
                $process.Dispose()
            }
        }
    }
}

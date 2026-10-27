BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-PlatformRepositoryProcessStart' -Tag 'PMUUriBridge' {
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
}

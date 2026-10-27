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
}

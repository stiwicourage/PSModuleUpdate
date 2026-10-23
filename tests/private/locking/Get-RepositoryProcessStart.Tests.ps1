BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-RepositoryProcessStart' -Tag 'PMUUriBridge' {
    Context 'PID reuse resistant owner identity' {
        It 'reports current process UTC ticks and absence of a nonexistent PID' {
            Get-RepositoryProcessStart $PID | Should -Match '^[0-9]{18}$'
            Get-RepositoryProcessStart ([int]::MaxValue) | Should -BeNullOrEmpty
        }
    }
}

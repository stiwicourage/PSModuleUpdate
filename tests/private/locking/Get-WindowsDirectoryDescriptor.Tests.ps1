BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-WindowsDirectoryDescriptor' -Tag 'PMU' {
    Context 'Native Windows descriptor' {
        It 'reads current-user ACL metadata from a disposable directory' -Skip:(-not $IsWindows) {
            $descriptor = Get-WindowsDirectoryDescriptor $TestDrive
            $descriptor.Trusted | Should -Contain $descriptor.Owner
        }
    }
}

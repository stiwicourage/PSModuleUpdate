BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'ConvertFrom-LinuxProcessStat' -Tag 'PMUUriBridge' {
    It 'reads field 22 independently of spaces, parentheses and newlines in the command name' {
        $stat = "7 (worker ) with`n spaces) S " + ('0 ' * 18) + '123451 0 0'
        ConvertFrom-LinuxProcessStat $stat | Should -Be 123451
    }
    It 'rejects incomplete process metadata' {
        { ConvertFrom-LinuxProcessStat '7 (worker) S' } |
            Should -Throw -ExceptionType ([IO.InvalidDataException])
    }
}

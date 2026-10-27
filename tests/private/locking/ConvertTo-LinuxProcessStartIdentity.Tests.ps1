BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'ConvertTo-LinuxProcessStartIdentity' -Tag 'PMUUriBridge' {
    It 'uses the reported clock frequency without losing the kernel start counter at <Frequency> Hz' -ForEach @(
        @{ Frequency = 100; Counter = 12345; Expected = '117900001234500000' }
        @{ Frequency = 1000; Counter = 123451; Expected = '117900001234510000' }
    ) {
        $stat = '7 (worker ) with spaces) S ' + ('0 ' * 18) + "$Counter 0 0"
        ConvertTo-LinuxProcessStartIdentity $stat "cpu 0`nbtime 1790000000`n" $Frequency |
            Should -BeExactly $Expected
    }
    It 'rejects invalid kernel clock metadata rather than guessing' -ForEach @(
        @{ Boot = ''; Frequency = '100' }
        @{ Boot = 'btime 1790000000'; Frequency = '0' }
        @{ Boot = 'btime 1790000000'; Frequency = '3' }
        @{ Boot = 'btime 1790000000'; Frequency = 'not-a-frequency' }
    ) {
        $stat = '7 (worker) S ' + ('0 ' * 18) + '12345'
        { ConvertTo-LinuxProcessStartIdentity $stat $Boot $Frequency } | Should -Throw -ExceptionType ([IO.InvalidDataException])
    }
    It 'rejects incomplete process metadata' {
        { ConvertTo-LinuxProcessStartIdentity '7 (worker) S' 'btime 1790000000' 100 } |
            Should -Throw -ExceptionType ([IO.InvalidDataException])
    }
}

BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Get-ProviderInvocationParameter' -Tag 'PMU' {
    It 'returns only provider diagnostic policy in a fresh mutable hashtable' {
        $first = Get-ProviderInvocationParameter
        $second = Get-ProviderInvocationParameter

        $first | Should -BeOfType [hashtable]
        @($first.Keys | Sort-Object) | Should -Be @('Debug', 'ErrorAction', 'Verbose', 'WarningAction')
        $first.ErrorAction | Should -BeExactly 'Stop'
        $first.WarningAction | Should -BeExactly 'SilentlyContinue'
        $first.Verbose | Should -BeFalse
        $first.Debug | Should -BeFalse

        $first.ErrorAction = 'Continue'
        $first.Name = 'CallerOwned'
        $second.ErrorAction | Should -BeExactly 'Stop'
        $second.ContainsKey('Name') | Should -BeFalse
        [object]::ReferenceEquals($first, $second) | Should -BeFalse
    }
}

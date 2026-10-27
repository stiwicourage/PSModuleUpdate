BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'ConvertTo-UpdateDecision' -Tag 'PMU' {
    It 'maps <Disposition> to the existing flat decision contract' -ForEach @(
        @{
            Disposition = 'UpToDate'
            Available = $false
            Restart = $false
            Reason = 'No release newer than both actual active and installed versions is available.'
        }
        @{
            Disposition = 'UpdateAvailable'
            Available = $true
            Restart = $false
            Reason = 'An exact newer release is available.'
        }
        @{
            Disposition = 'AlreadyInstalledRestartRequired'
            Available = $false
            Restart = $true
            Reason = 'A newer version is already installed in the selected scope.'
        }
    ) {
        $decision = ConvertTo-UpdateDecision $Disposition

        $decision.GetType() | Should -Be ([hashtable])
        ($decision.Keys | Sort-Object) -join ',' | Should -BeExactly 'Available,Disposition,Reason,Restart'
        $decision.Disposition | Should -BeExactly $Disposition
        $decision.Available | Should -Be $Available
        $decision.Restart | Should -Be $Restart
        $decision.Reason | Should -BeExactly $Reason
        $decision.Available | Should -BeOfType ([bool])
        $decision.Restart | Should -BeOfType ([bool])
    }

    It 'rejects a disposition outside the exact domain: <Disposition>' -ForEach @(
        @{
            Disposition = 'updateavailable'
        }
        @{
            Disposition = 'Unknown'
        }
        @{
            Disposition = ''
        }
    ) {
        { ConvertTo-UpdateDecision $Disposition } | Should -Throw
    }
}

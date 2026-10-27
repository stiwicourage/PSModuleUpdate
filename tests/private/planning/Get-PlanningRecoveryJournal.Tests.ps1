BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Get-PlanningRecoveryJournal' -Tag 'PMU' {
    BeforeEach {
        $script:moduleGuid = [guid]'a1111111-1111-1111-1111-111111111111'
        $script:destinationRoot = Join-Path $TestDrive 'Modules'
        $script:operation = [pscustomobject]@{
            JournalPath = Join-Path $TestDrive 'data/journal.json'
        }
        $script:journal = [pscustomobject]@{
            State = 'Preparation'
        }
        $script:capturedPlan = $null
        Mock Resolve-ModuleInstallationRoot {
            $script:destinationRoot
        }
        Mock ConvertTo-InstallationOperation {
            $script:capturedPlan = $Plan
            $script:operation
        }
        Mock Read-RecoveryJournal {
            $script:journal
        }
    }

    It 'reads through the scoped sentinel identity and retains the validated journal reference' {
        $result = Get-PlanningRecoveryJournal 'FixtureModule' 'AllUsers' $moduleGuid

        [object]::ReferenceEquals($result, $journal) | Should -BeTrue
        $capturedPlan.ModuleName | Should -BeExactly 'FixtureModule'
        $capturedPlan.ModuleGuid | Should -Be $moduleGuid
        $capturedPlan.Scope | Should -BeExactly 'AllUsers'
        $capturedPlan.DestinationRoot | Should -BeExactly $destinationRoot
        $capturedPlan.TargetNumericVersion | Should -BeExactly '0.0.0'
        @($capturedPlan.PSObject.Properties.Name) | Should -Be @(
            'ModuleName'
            'ModuleGuid'
            'Scope'
            'DestinationRoot'
            'TargetNumericVersion'
        )
        Should -Invoke Resolve-ModuleInstallationRoot -Times 1 -Exactly -ParameterFilter {
            $Scope -ceq 'AllUsers'
        }
        Should -Invoke ConvertTo-InstallationOperation -Times 1 -Exactly -ParameterFilter {
            $null -eq $Record -and $Consent.Count -eq 0 -and $null -eq $Credential
        }
        Should -Invoke Read-RecoveryJournal -Times 1 -Exactly -ParameterFilter {
            [object]::ReferenceEquals($Operation, $script:operation)
        }
    }

    It 'returns null when the journal reader has no journal' {
        Mock Read-RecoveryJournal {
            $null
        }

        Get-PlanningRecoveryJournal 'FixtureModule' 'CurrentUser' $moduleGuid |
            Should -BeNullOrEmpty
    }

    It 'propagates <Command> failures unchanged' -ForEach @(
        @{
            Command = 'Resolve-ModuleInstallationRoot'
        }
        @{
            Command = 'ConvertTo-InstallationOperation'
        }
        @{
            Command = 'Read-RecoveryJournal'
        }
    ) {
        Mock $Command {
            throw 'planning journal failure'
        }

        { Get-PlanningRecoveryJournal 'FixtureModule' 'CurrentUser' $moduleGuid } |
            Should -Throw '*planning journal failure*'
    }
}

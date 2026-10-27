BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Get-ExpectedRecoveryJournalIdentity' -Tag 'PMU' {
    It 'projects only the fixed identity fields with their original types and order' {
        $plan = [pscustomobject]@{
            ModuleName = 'Fixture'
            ModuleGuid = [guid]'12345678-1234-1234-1234-123456789abc'
            Scope = 'CurrentUser'
            DestinationRoot = $TestDrive
            TargetNumericVersion = 'ignored'
        }
        $version = [pscustomobject]@{
            NumericVersion = '2.0.0'
        }
        $identity = Get-ExpectedRecoveryJournalIdentity $plan $version
        @($identity.PSObject.Properties.Name) -join ',' | Should -BeExactly 'SchemaVersion,ModuleName,ModuleGuid,Scope,DestinationRoot,TargetNumericVersion'
        $identity.SchemaVersion | Should -BeOfType ([int])
        $identity.SchemaVersion | Should -Be 1
        $identity.ModuleName | Should -BeExactly 'Fixture'
        $identity.ModuleGuid | Should -BeOfType ([string])
        $identity.ModuleGuid | Should -BeExactly '12345678-1234-1234-1234-123456789abc'
        $identity.Scope | Should -BeExactly 'CurrentUser'
        $identity.DestinationRoot | Should -BeExactly $TestDrive
        $identity.TargetNumericVersion | Should -BeExactly '2.0.0'
    }
}

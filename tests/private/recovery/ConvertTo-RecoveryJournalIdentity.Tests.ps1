BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'ConvertTo-RecoveryJournalIdentity' -Tag 'PMU' {
    It 'projects only durable selected-target identity and stringifies its module GUID' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Plan | Add-Member Credential 'PMUPrivacySentinel-85d3b6d1-Credential'
        $operation.Plan | Add-Member Parent 'PMUPrivacySentinel-85d3b6d1-Parent'
        $operation.Plan | Add-Member Context 'PMUPrivacySentinel-85d3b6d1-Context'
        $identity = ConvertTo-RecoveryJournalIdentity $operation.Plan
        @($identity.Keys) | Should -Be 'SchemaVersion TransactionId ModuleName Scope DestinationRoot ModuleGuid PreviousVersion TargetVersion TargetNumericVersion TargetPath'.Split(' ')
        $identity.ModuleGuid | Should -BeExactly "$($operation.Plan.ModuleGuid)"
        $identity.ModuleGuid | Should -BeOfType ([string])
        $identity.TargetPath | Should -Be $operation.Plan.TargetInstalledPath
        $identity.PreviousVersion | Should -Be $operation.Plan.InstalledVersion
        ($identity | ConvertTo-Json) | Should -Not -Match 'PMUPrivacySentinel-85d3b6d1-'
        ($identity | ConvertTo-Json) | Should -Not -Match '"(?:Credential|Parent|Context)"\s*:'
    }
}

BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'ConvertTo-UpdateResult' -Tag 'PMU' {
    It 'keeps exact schema active, installed and target facts separate' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $result = ConvertTo-UpdateResult $operation.Plan 'WhatIf'
        $fields = 'SchemaVersion Outcome ModuleName ModuleGuid RepositoryName RepositoryUri Scope ActiveVersion InstalledVersion TargetVersion InstalledPath VerificationStatus RestartRequired DependencySummary RecoveryStatus RecoveryGuidance'.Split(' ')
        @($result.PSObject.Properties.Name | Sort-Object) | Should -Be @($fields | Sort-Object)
        $result.ActiveVersion | Should -BeNullOrEmpty
        $result.InstalledVersion | Should -Be '2.0.0-preview.1'
        $result.TargetVersion | Should -Be '2.0.0-preview.2'
    }
}

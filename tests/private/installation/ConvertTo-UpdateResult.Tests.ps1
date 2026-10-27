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
    It 'preserves ordered typed output without copying private plan context' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Plan | Add-Member Credential 'PMUPrivacySentinel-85d3b6d1-Credential'
        $operation.Plan | Add-Member Parent 'PMUPrivacySentinel-85d3b6d1-Parent'
        $operation.Plan | Add-Member Context 'PMUPrivacySentinel-85d3b6d1-Context'
        $result = ConvertTo-UpdateResult $operation.Plan 'WhatIf'
        $fields = 'SchemaVersion Outcome ModuleName ModuleGuid RepositoryName RepositoryUri Scope ActiveVersion InstalledVersion TargetVersion InstalledPath VerificationStatus RestartRequired DependencySummary RecoveryStatus RecoveryGuidance'.Split(' ')
        @($result.PSObject.Properties.Name) | Should -Be $fields
        $result.PSTypeNames[0] | Should -BeExactly 'PSModuleUpdate.UpdateResult'
        $result.ModuleGuid | Should -BeOfType ([guid])
        $result.RestartRequired | Should -BeOfType ([bool])
        ($result | ConvertTo-Json -Depth 8) | Should -Not -Match 'PMUPrivacySentinel-85d3b6d1-'
        ($result | ConvertTo-Json -Depth 8) | Should -Not -Match '"(?:Credential|Parent|Context)"\s*:'
    }
}

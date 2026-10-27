BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'ConvertTo-UpdateResultIdentity' -Tag 'PMU' {
    It 'allow-lists repository and installation identity while preserving GUID and null active version' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Plan | Add-Member Credential 'secret'
        $operation.Plan | Add-Member Parent 'private'
        $operation.Plan | Add-Member Context 'private'
        $identity = ConvertTo-UpdateResultIdentity $operation.Plan
        @($identity.Keys) | Should -Be 'ModuleName ModuleGuid RepositoryName RepositoryUri Scope ActiveVersion'.Split(' ')
        $identity.ModuleGuid | Should -BeOfType ([guid])
        $identity.RepositoryUri | Should -Be $operation.Plan.RepositoryUri
        $identity.ActiveVersion | Should -BeNullOrEmpty
        ($identity | ConvertTo-Json) | Should -Not -Match 'Credential|Parent|Context|secret|private'
    }
}

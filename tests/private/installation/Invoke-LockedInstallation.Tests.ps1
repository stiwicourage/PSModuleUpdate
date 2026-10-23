# The real public workflow owns full staging/rollback coverage; this test isolates lock-held revalidation.
BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Invoke-LockedInstallation' -Tag 'PMU' {
    It 'rechecks environment after lock acquisition before staging or recovery changes' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Mock Assert-PlanEnvironment { Write-PMUError 'PMU.RepositoryChanged' 'fixture changed' }
        Mock Initialize-StagedPackage {}
        { Invoke-LockedInstallation $operation } | Should -Throw -ErrorId 'PMU.RepositoryChanged'
        Should -Invoke Initialize-StagedPackage -Times 0
    }
}

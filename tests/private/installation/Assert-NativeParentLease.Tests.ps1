BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-NativeParentLease' -Tag 'PMU', 'PMUNativeHandoff' {
    It 'refuses a disposed or different-file lease rather than treating any lock handle as ownership' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $operation.Lock = Enter-InstallationLock (Join-Path $operation.WorkRoot 'different.lock')
        try {
            { Assert-NativeParentLease $operation } | Should -Throw -ErrorId 'PMU.PlanStale'
        } finally {
            $operation.Lock.Dispose()
        }
        { Assert-NativeParentLease $operation } | Should -Throw -ErrorId 'PMU.PlanStale'
    }
}

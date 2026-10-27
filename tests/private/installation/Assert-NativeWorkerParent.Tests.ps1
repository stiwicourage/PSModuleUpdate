BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-NativeWorkerParent' -Tag 'PMUNative' {
    It 'accepts only the same still-live process instance' {
        $context = @{
            ParentPid = $PID
            ParentStarted = Get-RepositoryProcessStart $PID
        }
        { Assert-NativeWorkerParent $context } | Should -Not -Throw
        $context.ParentStarted = '0'
        { Assert-NativeWorkerParent $context } | Should -Throw -ErrorId 'PMU.PlanStale'
        $context.ParentPid = [int]::MaxValue
        { Assert-NativeWorkerParent $context } | Should -Throw -ErrorId 'PMU.PlanStale'
    }
}

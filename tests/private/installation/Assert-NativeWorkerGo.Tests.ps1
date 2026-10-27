BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-NativeWorkerGo' -Tag 'PMUNative' {
    It 'rejects EOF or an invalid GO before acquiring a mutation lease' -ForEach @(
        @{ Value = '' }
        @{ Value = 'GO extra' }
        @{ Value = 'STOP' }
    ) {
        $reader = [IO.StringReader]::new($Value)
        try {
            { Assert-NativeWorkerGo $reader } | Should -Throw -ErrorId 'PMU.PlanStale'
        } finally {
            $reader.Dispose()
        }
    }
    It 'accepts only the explicit pipe GO token' {
        $reader = [IO.StringReader]::new("GO`n")
        try {
            { Assert-NativeWorkerGo $reader } | Should -Not -Throw
        } finally {
            $reader.Dispose()
        }
    }
}

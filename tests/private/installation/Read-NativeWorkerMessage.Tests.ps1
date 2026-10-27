BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Read-NativeWorkerMessage' -Tag 'PMU', 'PMUNativeHandoff' {
    It 'reads only the private protocol envelope without surfacing provider console diagnostics' {
        $reader = [IO.StringReader]::new("provider diagnostic`nPMU_NATIVE:{`"Phase`":`"READY`"}`n")
        (Read-NativeWorkerMessage $reader).Phase | Should -BeExactly 'READY'
    }
    It 'fails rather than inventing success after EOF' {
        { Read-NativeWorkerMessage ([IO.StringReader]::new('')) } | Should -Throw -ErrorId 'PMU.RecoveryRequired'
    }
}

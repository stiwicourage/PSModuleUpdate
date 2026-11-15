BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Assert-ManifestWorkerResult' -Tag 'PMU', 'PMUTargetManifest' {
    It 'accepts only a successful complete response from a successful child' {
        {
            Assert-ManifestWorkerResult ([pscustomobject]@{
                    Phase = 'RESULT'
                    Success = $true
                }) 0
        } | Should -Not -Throw
    }
    It 'rejects <Kind> with a safe structured error' -ForEach @(
        @{
            Kind = 'failed child'
            Phase = 'RESULT'
            Success = $true
            ExitCode = 1
        }
        @{
            Kind = 'unexpected phase'
            Phase = 'READY'
            Success = $true
            ExitCode = 0
        }
        @{
            Kind = 'failed operation'
            Phase = 'RESULT'
            Success = $false
            ExitCode = 0
        }
    ) {
        $result = [pscustomobject]@{
            Phase = $Phase
            Success = $Success
            ErrorId = 'unsafe fixture-secret'
        }
        {
            Assert-ManifestWorkerResult $result $ExitCode
        } | Should -Throw -ErrorId PMU.InstallationFailed -ExpectedMessage '*diagnostics were withheld*'
    }
}

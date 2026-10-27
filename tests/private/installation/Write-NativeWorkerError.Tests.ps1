BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Write-NativeWorkerError' -Tag 'PMU', 'PMUWorkerContracts' {
    It 'preserves an owned PMU error identifier without echoing native details' {
        $result = [pscustomobject]@{
            ErrorId = 'PMU.SourceMismatch'
            Message = 'untrusted-provider-detail'
        }
        $failure = { Write-NativeWorkerError $result } |
            Should -Throw -ErrorId 'PMU.SourceMismatch' -PassThru
        $failure.Exception.Message | Should -Not -Match 'untrusted-provider-detail'
        $failure.TargetObject.RecoveryGuidance | Should -Match 'Do not delete pending PMU transaction data'
    }

    It 'maps an unowned or malformed identifier to a safe installation failure: <ErrorId>' -ForEach @(
        @{ ErrorId = $null }
        @{ ErrorId = '' }
        @{ ErrorId = 'Provider.Failed' }
        @{ ErrorId = 'PMU.SourceMismatch,untrusted-detail' }
        @{ ErrorId = 'PMU.Source-Mismatch' }
    ) {
        { Write-NativeWorkerError ([pscustomobject]@{ ErrorId = $ErrorId }) } |
            Should -Throw -ErrorId 'PMU.InstallationFailed'
    }
}

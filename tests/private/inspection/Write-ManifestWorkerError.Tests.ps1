BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Write-ManifestWorkerError' -Tag 'PMU', 'PMUTargetManifest' {
    It 'preserves only a validated structured PMU identifier' {
        {
            Write-ManifestWorkerError ([pscustomobject]@{
                    ErrorId = 'PMU.GuidMismatch'
                })
        } |
            Should -Throw -ErrorId PMU.GuidMismatch -ExpectedMessage '*diagnostics were withheld*'
    }
}

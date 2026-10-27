BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-RecoveryTargetVersion' -Tag 'PMURecoverySafety' {
    Context 'Full prerelease identity within one numeric directory' {
        It 'accepts the approved previous or target identity but rejects a third prerelease' {
            $journal = [pscustomobject]@{
                PreviousVersion = '2.0.0-preview.1'
                TargetVersion = '2.0.0-preview.2'
            }
            $manifest = @{
                ModuleVersion = '2.0.0'
                PrivateData = @{ PSData = @{ Prerelease = 'preview.2' } }
            }
            { Assert-RecoveryTargetVersion $manifest $journal } | Should -Not -Throw
            $manifest.PrivateData.PSData.Prerelease = 'preview.3'
            { Assert-RecoveryTargetVersion $manifest $journal } | Should -Throw -ErrorId 'PMU.ModuleIdentityMismatch*'
        }
    }
}

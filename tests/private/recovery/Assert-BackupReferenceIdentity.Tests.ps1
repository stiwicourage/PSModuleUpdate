BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-BackupReferenceIdentity' -Tag 'PMUBackupReference' {
    Context 'Exact validated unfinished backup only' {
        It 'accepts an identity matching the verified backup without importing it' {
            $path = Initialize-PMUTestPackage $TestDrive '2.0.0-preview.1'
            $script:verifiedBackup = Get-ManifestIdentity "$path/FixtureModule.psd1"
            Mock Get-VerifiedRecoveryBackup { $script:verifiedBackup }
            { Assert-BackupReferenceIdentity $verifiedBackup ([pscustomobject]@{ State = 'ReplacementInProgress' }) } | Should -Not -Throw
            Should -Invoke Get-VerifiedRecoveryBackup -Times 1 -ParameterFilter { $ErrorId -eq 'PMU.RecoveryRequired' }
        }
        It 'does not accept an arbitrary matching-GUID source outside the exact backup path' {
            $path = Initialize-PMUTestPackage $TestDrive '2.0.0-preview.1'
            $reference = Get-ManifestIdentity "$path/FixtureModule.psd1"
            $script:verifiedBackup = [pscustomobject]@{ Name = $reference.Name; Guid = $reference.Guid; ManifestPath = 'different-backup.psd1'; Version = $reference.Version }
            Mock Get-VerifiedRecoveryBackup { $script:verifiedBackup }
            { Assert-BackupReferenceIdentity $reference ([pscustomobject]@{ State = 'ReplacementInProgress' }) } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation*'
        }
    }
    It 'rejects a reference when no unfinished-operation journal exists' {
        { Assert-BackupReferenceIdentity ([pscustomobject]@{}) $null } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation*'
    }
    It 'rejects a reference whose full version differs from the verified backup' {
        $path = Initialize-PMUTestPackage $TestDrive '2.0.0-preview.1'
        $reference = Get-ManifestIdentity "$path/FixtureModule.psd1"
        $script:verifiedBackup = [pscustomobject]@{ Name = $reference.Name; Guid = $reference.Guid; ManifestPath = $reference.ManifestPath; Version = [pscustomobject]@{ FullVersion = '2.0.0-preview.2' } }
        Mock Get-VerifiedRecoveryBackup { $script:verifiedBackup }
        { Assert-BackupReferenceIdentity $reference ([pscustomobject]@{ State = 'ReplacementInProgress' }) } | Should -Throw -ErrorId 'PMU.ModuleIdentityMismatch*'
    }
}

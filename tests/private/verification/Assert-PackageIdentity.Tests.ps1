BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-PackageIdentity' -Tag 'PMU' {
    It 'rejects stable identity when a distinct prerelease target was approved' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $identity = Get-ManifestIdentity $operation.Plan.InstalledManifestPath
        $identity.Version.FullVersion = '2.0.0'
        { Assert-PackageIdentity $identity $operation.Plan } | Should -Throw -ErrorId 'PMU.VerificationFailed'
    }
}

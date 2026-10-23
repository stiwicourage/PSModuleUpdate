BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-PackageSource' -Tag 'PMU' {
    It 'rejects available provider metadata pointing at another feed' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $directory = Split-Path -Parent $operation.Plan.InstalledManifestPath
        [pscustomobject]@{ RepositorySourceLocation = 'https://other.invalid/feed' } | Export-Clixml "$directory/PSGetModuleInfo.xml"
        { Assert-PackageSource $directory $operation.Plan } | Should -Throw -ErrorId 'PMU.VerificationFailed'
    }
}

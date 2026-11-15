BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Assert-InspectedManifest' -Tag 'PMU', 'PMUTargetManifest' {
    It 'leaves an uninspected plan and an unchanged binding valid' {
        {
            Assert-InspectedManifest ([pscustomobject]@{
                }) 'first'
        } | Should -Not -Throw
        {
            Assert-InspectedManifest ([pscustomobject]@{
                    InspectedManifestHash = 'first'
                }) 'first'
        } | Should -Not -Throw
    }
    It 'rejects differing manifest bytes without changing the existing binding' {
        $record = [pscustomobject]@{
            InspectedManifestHash = 'first'
        }
        {
            Assert-InspectedManifest $record 'second'
        } | Should -Throw -ErrorId PMU.TargetManifestChanged
        $record.InspectedManifestHash | Should -BeExactly first
    }
}

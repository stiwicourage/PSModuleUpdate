BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'ConvertTo-NativePlanRecord' -Tag 'PMU', 'PMUTargetManifest' {
    It 'copies the private manifest binding without exposing or sharing the original record' {
        $record = [pscustomobject]@{
            InstalledTree = @('fixture')
            InspectedManifestHash = 'first'
            Snapshot = 'private'
        }
        $copy = ConvertTo-NativePlanRecord $record
        $copy.InspectedManifestHash | Should -Be first
        $copy.InstalledTree | Should -Be @('fixture')
        $copy.PSObject.Properties.Name | Should -Not -Contain Snapshot
        $copy.InspectedManifestHash = 'second'
        $record.InspectedManifestHash | Should -Be first
    }
}

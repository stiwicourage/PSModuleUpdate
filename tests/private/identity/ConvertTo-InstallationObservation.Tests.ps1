BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'ConvertTo-InstallationObservation' -Tag 'PMU' {
    BeforeEach {
        $script:identity = [pscustomobject]@{
            Version = [pscustomobject]@{
                FullVersion = '2.0.0-preview.1'
                NumericVersion = '2.0.0'
                Prerelease = 'preview.1'
            }
            Guid = [guid]'cc2a0585-ae0a-49df-a47a-2e70de88428f'
            ManifestPath = 'private-backup-manifest'
            ActiveVersion = '1.0.0'
            Credential = 'private-test-value'
        }
    }

    It 'allow-lists the seven observation fields in contract order without leaking identity metadata' {
        $observation = ConvertTo-InstallationObservation $script:identity 'AllUsers' 'CanonicalRoot' 'TargetManifest'

        $observation.PSObject.Properties.Name | Should -Be @(
            'FullVersion', 'NumericVersion', 'Prerelease', 'Scope', 'Root', 'ManifestPath', 'Guid'
        )
        $observation.FullVersion | Should -BeExactly '2.0.0-preview.1'
        $observation.NumericVersion | Should -BeExactly '2.0.0'
        $observation.Prerelease | Should -BeExactly 'preview.1'
        $observation.Scope | Should -BeExactly 'AllUsers'
        $observation.Root | Should -BeExactly 'CanonicalRoot'
        $observation.ManifestPath | Should -BeExactly 'TargetManifest'
        $observation.Guid | Should -Be $script:identity.Guid
        $observation.Guid | Should -BeOfType ([guid])
    }

    It 'preserves null prerelease and location values without string coercion' {
        $script:identity.Version.Prerelease = $null

        $observation = ConvertTo-InstallationObservation $script:identity $null $null $null

        $observation.Prerelease | Should -BeNullOrEmpty
        ($null -eq $observation.Prerelease) | Should -BeTrue
        ($null -eq $observation.Scope) | Should -BeTrue
        ($null -eq $observation.Root) | Should -BeTrue
        ($null -eq $observation.ManifestPath) | Should -BeTrue
        $observation.FullVersion | Should -BeOfType ([string])
    }
}

BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Get-BoundTargetManifest' -Tag 'PMU', 'PMUTargetManifest' {
    It 'does not acquire an exact target without rechecked license consent' {
        Mock Assert-ExactTarget {
        }
        Mock Assert-InstallationConsent {
            Write-PMUError 'PMU.LicenseAcceptanceRequired' 'Acceptance required.'
        }
        Mock Invoke-ManifestAcquisition {
        }
        {
            Get-BoundTargetManifest ([pscustomobject]@{
                })
        } | Should -Throw -ErrorId PMU.LicenseAcceptanceRequired
        Should -Invoke Invoke-ManifestAcquisition -Times 0
    }
    It 'returns the inspected manifest only after exact target and consent checks precede acquisition' {
        $expectedOperation = [pscustomobject]@{ Id = 'inspection' }
        $manifest = [pscustomobject]@{ Version = '2.0.0'; Name = 'FixtureModule' }
        $events = [Collections.Generic.List[string]]::new()
        Mock Assert-ExactTarget { $events.Add('target') }
        Mock Assert-InstallationConsent { $events.Add('consent') }
        Mock Invoke-ManifestAcquisition { $events.Add('acquire') }
        Mock Get-InspectedTargetManifest { $events.Add('inspect'); $manifest }
        $result = Get-BoundTargetManifest $expectedOperation
        [object]::ReferenceEquals($result, $manifest) | Should -BeTrue
        @($events) | Should -Be @('target', 'consent', 'acquire', 'inspect')
        Should -Invoke Get-InspectedTargetManifest -Times 1 -Exactly -ParameterFilter {
            [object]::ReferenceEquals($Operation, $expectedOperation)
        }
    }
}

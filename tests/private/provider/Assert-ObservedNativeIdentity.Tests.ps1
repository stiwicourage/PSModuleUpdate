BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Assert-ObservedNativeIdentity' -Tag 'PMUNativeCandidate' {
    BeforeEach {
        $script:observedOperation = Initialize-PMUTestOperation $TestDrive
        $script:observedManifest = $observedOperation.Plan.InstalledManifestPath
    }

    It 'accepts the observed installation identity without requiring the update target version' {
        @(Assert-ObservedNativeIdentity $observedOperation $observedManifest).Count | Should -Be 0
    }

    It 'rejects a manifest absent from exact scope observations before inspecting its identity' {
        $observedOperation.Plan.ObservedInstalledVersions = @()
        Mock Get-ManifestIdentity { throw 'Identity must not be read.' }

        { Assert-ObservedNativeIdentity $observedOperation $observedManifest } |
            Should -Throw -ErrorId 'PMU.UnsupportedInstallation'

        Should -Invoke Get-ManifestIdentity -Times 0 -Exactly
    }

    It 'rejects an observed version that differs from the actual manifest identity' {
        $observation = $observedOperation.Plan.ObservedInstalledVersions |
            Where-Object ManifestPath -CEQ $observedManifest
        $observation.FullVersion = '9.9.9'

        { Assert-ObservedNativeIdentity $observedOperation $observedManifest } |
            Should -Throw -ErrorId 'PMU.VerificationFailed'
    }
}

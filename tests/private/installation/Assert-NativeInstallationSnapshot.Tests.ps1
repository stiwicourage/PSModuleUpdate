BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Assert-NativeInstallationSnapshot' -Tag 'PMUNativeHandoff' {
    BeforeEach {
        $operation = Initialize-PMUTestOperation $TestDrive
        $path = Split-Path -Parent $operation.Plan.InstalledManifestPath
        $script:snapshotSource = [pscustomobject]@{ Name = 'ApprovedFeed'; Uri = $operation.Plan.RepositoryUri }
        $script:snapshotContext = [pscustomobject]@{
            Operation = $operation
            Snapshot = [pscustomobject]@{
                Path = $path
                Version = $operation.Plan.InstalledVersion
                Tree = @(Get-FileTreeInventory $path)
                Source = $snapshotSource
            }
        }
        Mock Get-NativeInstalledSource { $script:snapshotSource }
    }

    It 'accepts the exact observed manifest, tree and source without output' {
        @(Assert-NativeInstallationSnapshot $snapshotContext).Count | Should -Be 0
    }

    It 'rejects a changed tree before reading its native source' {
        $manifest = $snapshotContext.Operation.Plan.InstalledManifestPath
        [IO.File]::AppendAllText($manifest, "`n# changed after observation")

        { Assert-NativeInstallationSnapshot $snapshotContext } |
            Should -Throw -ErrorId 'PMU.InstalledStateChanged'

        Should -Invoke Get-NativeInstalledSource -Times 0 -Exactly
    }

    It 'rejects a changed native source without accepting the snapshot' {
        Mock Get-NativeInstalledSource {
            [pscustomobject]@{ Name = 'OtherFeed'; Uri = 'https://other.example.invalid/feed' }
        }

        { Assert-NativeInstallationSnapshot $snapshotContext } |
            Should -Throw -ErrorId 'PMU.InstalledStateChanged'
    }
}

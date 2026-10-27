BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Get-NativeSelectedSnapshot' -Tag 'PMU', 'PMUWorkerContracts' {
    BeforeEach {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Plan.TargetInstalledPath = Initialize-PMUTestPackage $operation.Plan.DestinationRoot '3.0.0'
        $script:approvedSource = [pscustomobject]@{
            Name = 'ApprovedFeed'
            Uri = 'https://feed.invalid'
        }
        Mock Get-NativeInstalledSource { $script:approvedSource }
    }

    It 'snapshots the selected installation for AlreadyInstalled=<AlreadyInstalled>' -ForEach @(
        @{
            AlreadyInstalled = $false
            Version = '2.0.0-preview.1'
        }
        @{
            AlreadyInstalled = $true
            Version = '3.0.0'
        }
    ) {
        $expected = Split-Path -Parent $operation.Plan.InstalledManifestPath
        if ($AlreadyInstalled) {
            $expected = $operation.Plan.TargetInstalledPath
        }
        $snapshot = Get-NativeSelectedSnapshot $operation $AlreadyInstalled
        $snapshot.Path | Should -BeExactly $expected
        $snapshot.Version | Should -BeExactly $Version
        $snapshot.Source.Uri | Should -BeExactly 'https://feed.invalid'
        $snapshot.Tree.Count | Should -BeGreaterThan 0
        Should -Invoke Get-NativeInstalledSource -Times 1 -Exactly -ParameterFilter {
            $SelectedPath -ceq $expected
        }
    }

    It 'refuses to snapshot files after native source validation fails' {
        Mock Get-NativeInstalledSource {
            Write-PMUError 'PMU.SourceMismatch' 'The source changed.'
        }
        Mock Get-FileTreeInventory {}
        { Get-NativeSelectedSnapshot $operation $false } |
            Should -Throw -ErrorId 'PMU.SourceMismatch'
        Should -Invoke Get-FileTreeInventory -Times 0
    }
}

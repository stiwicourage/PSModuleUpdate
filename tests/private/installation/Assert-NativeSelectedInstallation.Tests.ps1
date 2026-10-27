BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module PowerShellGet -RequiredVersion 2.2.5
    function Assert-NativeProviderContext {
    }
}
Describe 'Assert-NativeSelectedInstallation' -Tag 'PMU', 'PMUNativeHandoff' {
    BeforeEach {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.RepositoryName = 'OriginalNativeName'
        $script:selectionRoot = $operation.Plan.DestinationRoot
        Mock Resolve-ModuleInstallationRoot { $script:selectionRoot }
        $path = Split-Path -Parent $operation.Plan.InstalledManifestPath
        [pscustomobject]@{
            Name = $operation.Plan.ModuleName
            Repository = $operation.RepositoryName
            RepositorySourceLocation = $operation.Plan.RepositoryUri
            InstalledLocation = $path
        } | Export-Clixml (Join-Path $path 'PSGetModuleInfo.xml')
        $script:selectionContext = [pscustomobject]@{
            Operation = $operation
            AlreadyInstalled = $false
            Snapshot = [pscustomobject]@{
                Path = $path
                Version = $operation.Plan.InstalledVersion
                Tree = @(Get-FileTreeInventory $path)
                Source = [pscustomobject]@{
                    Name = $operation.RepositoryName
                    Uri = $operation.Plan.RepositoryUri
                }
            }
        }
        $script:nativeCandidate = [pscustomobject]@{
            InstalledLocation = $path
            Repository = $operation.RepositoryName
        }
        Mock Get-InstalledModule { $script:nativeCandidate }
        Mock Assert-NativeProviderContext {}
    }
    It 'accepts an unchanged selected tree and approved native source in the same scope' {
        Assert-NativeSelectedInstallation $selectionContext
    }
    It 'rejects native selection of a path outside the observed selected-scope installations' {
        $nativeCandidate.InstalledLocation = Join-Path $TestDrive 'other-scope'
        { Assert-NativeSelectedInstallation $selectionContext } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
    }
    It 'rejects a selected tree changed during the ownership gap' {
        [IO.File]::AppendAllText((Join-Path $selectionContext.Snapshot.Path 'FixtureModule.psm1'), 'changed')
        { Assert-NativeSelectedInstallation $selectionContext } | Should -Throw -ErrorId 'PMU.InstalledStateChanged'
    }

    It 'rejects a snapshot manifest with another <Property> before native lookup' -ForEach @(
        @{ Property = 'Name'; Value = 'OtherModule'; ErrorId = 'PMU.VerificationFailed' }
        @{ Property = 'Guid'; Value = [guid]::Empty; ErrorId = 'PMU.GuidMismatch' }
        @{ Property = 'Version'; Value = [pscustomobject]@{ FullVersion = '9.9.9' }; ErrorId = 'PMU.VerificationFailed' }
    ) {
        $script:snapshotIdentity = Get-ManifestIdentity $selectionContext.Operation.Plan.InstalledManifestPath
        $snapshotIdentity.$Property = $Value
        Mock Test-InstalledPlanState { $false }
        Mock Get-ManifestIdentity { $script:snapshotIdentity }

        { Assert-NativeSelectedInstallation $selectionContext } | Should -Throw -ErrorId $ErrorId

        Should -Invoke Get-InstalledModule -Times 0 -Exactly
    }

    It 'rejects changed snapshot source <Property> before native lookup' -ForEach @(
        @{ Property = 'Name'; Value = 'OtherFeed' }
        @{ Property = 'Uri'; Value = 'https://other.example.invalid/feed' }
    ) {
        $selectionContext.Snapshot.Source.$Property = $Value

        { Assert-NativeSelectedInstallation $selectionContext } | Should -Throw -ErrorId 'PMU.InstalledStateChanged'

        Should -Invoke Get-InstalledModule -Times 0 -Exactly
    }

    It 'checks handoff state before reading the snapshot manifest' {
        Mock Test-InstalledPlanState { $true }
        Mock Get-ManifestIdentity { throw 'Snapshot must not be read.' }

        { Assert-NativeSelectedInstallation $selectionContext } | Should -Throw -ErrorId 'PMU.InstalledStateChanged'

        Should -Invoke Get-ManifestIdentity -Times 0 -Exactly
    }

    It 'skips native lookup for an already installed target after validating its snapshot' {
        $selectionContext.AlreadyInstalled = $true
        Mock Test-InstalledPlanState { $true }

        @(Assert-NativeSelectedInstallation $selectionContext).Count | Should -Be 0
        Should -Invoke Get-InstalledModule -Times 0 -Exactly

        $selectionContext.Snapshot.Source.Name = 'ChangedFeed'
        { Assert-NativeSelectedInstallation $selectionContext } | Should -Throw -ErrorId 'PMU.InstalledStateChanged'
        Should -Invoke Get-InstalledModule -Times 0 -Exactly
    }
}

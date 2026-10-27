BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-NativeInstalledSource' -Tag 'PMU', 'PMUNativeAdapter' {
    BeforeEach {
        $operation = Initialize-PMUTestOperation $TestDrive
        $script:selectedPath = Split-Path -Parent $operation.Plan.InstalledManifestPath
        $script:nativeMetadata = [pscustomobject]@{
            Name = $operation.Plan.ModuleName
            Repository = 'OriginalNativeName'
            RepositorySourceLocation = $operation.Plan.RepositoryUri
            InstalledLocation = $selectedPath
        }
    }
    It 'fails explicitly for an installation lacking native installed metadata' {
        { Get-NativeInstalledSource $operation $selectedPath } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
    }
    It 'uses raw metadata without repointing or rewriting the selected installation' {
        $path = Join-Path $selectedPath 'PSGetModuleInfo.xml'
        $nativeMetadata | Export-Clixml $path
        $before = (Get-FileHash $path).Hash
        $source = Get-NativeInstalledSource $operation $selectedPath
        $source.Name | Should -BeExactly 'OriginalNativeName'
        $source.Uri | Should -BeExactly $operation.Plan.RepositoryUri
        (Get-FileHash $path).Hash | Should -BeExactly $before
    }
    It 'rejects metadata from another source or destination before native mutation' -ForEach @(
        @{
            Field = 'RepositorySourceLocation'
            Value = 'https://other.invalid/feed'
            ErrorId = 'PMU.SourceMismatch'
        }
        @{
            Field = 'InstalledLocation'
            Value = 'other-installation'
            ErrorId = 'PMU.UnsupportedInstallation'
        }
    ) {
        $nativeMetadata.$Field = $Value
        $nativeMetadata | Export-Clixml (Join-Path $selectedPath 'PSGetModuleInfo.xml')
        { Get-NativeInstalledSource $operation $selectedPath } | Should -Throw -ErrorId $ErrorId
    }
}

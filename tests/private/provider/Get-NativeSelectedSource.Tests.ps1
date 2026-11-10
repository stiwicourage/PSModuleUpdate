BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-NativeSelectedSource' -Tag 'PMU', 'PMUUnmanaged' {
    BeforeEach {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.RepositoryName = 'ApprovedFeed'
        $script:selectedPath = Split-Path -Parent $operation.Plan.InstalledManifestPath
    }
    It 'preserves the unsupported installation error without consent' {
        { Get-NativeSelectedSource $operation $selectedPath $true } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
    }
    It 'uses only the approved target source for an opted-in unmanaged original' {
        $operation.Consent.ReplaceUnmanagedInstallation = $true
        $source = Get-NativeSelectedSource $operation $selectedPath $true
        $source.Name | Should -BeExactly 'ApprovedFeed'
        $source.Uri | Should -BeExactly $operation.Plan.RepositoryUri
        $source.Unmanaged | Should -BeTrue
    }
    It 'does not waive metadata for an already installed target' {
        $operation.Consent.ReplaceUnmanagedInstallation = $true
        { Get-NativeSelectedSource $operation $selectedPath $false } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
    }
    It 'rejects present unreadable metadata even with consent' {
        $operation.Consent.ReplaceUnmanagedInstallation = $true
        [IO.File]::WriteAllText((Join-Path $selectedPath 'PSGetModuleInfo.xml'), 'not XML')
        { Get-NativeSelectedSource $operation $selectedPath $true } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
    }
    It 'retains native metadata identity and repository checks with consent' -ForEach @(
        @{ Field = 'InstalledLocation'; Value = 'other'; ErrorId = 'PMU.UnsupportedInstallation' }
        @{ Field = 'RepositorySourceLocation'; Value = 'https://other.invalid'; ErrorId = 'PMU.SourceMismatch' }
    ) {
        $operation.Consent.ReplaceUnmanagedInstallation = $true
        $metadata = [pscustomobject]@{
            Name = $operation.Plan.ModuleName; InstalledLocation = $selectedPath
            Repository = 'ApprovedFeed'; RepositorySourceLocation = $operation.Plan.RepositoryUri
        }
        $metadata.$Field = $Value
        $metadata | Export-Clixml (Join-Path $selectedPath 'PSGetModuleInfo.xml')
        { Get-NativeSelectedSource $operation $selectedPath $true } | Should -Throw -ErrorId $ErrorId
    }
}

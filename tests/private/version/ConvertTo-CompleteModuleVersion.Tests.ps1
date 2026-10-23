BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/src/private/shared/Write-PMUError.ps1"
    . "$root/src/private/version/ConvertTo-CompleteModuleVersion.ps1"
}
Describe 'ConvertTo-CompleteModuleVersion' -Tag 'PMU' {
    It 'preserves four numeric components and distinct prerelease labels' {
        $version = ConvertTo-CompleteModuleVersion '2.3.4.5-preview.10'
        $version.NumericVersion | Should -Be '2.3.4.5'
        $version.Prerelease | Should -Be 'preview.10'
    }
    It 'rejects malformed or unsupported identities' -ForEach @('2.0.0+build', '2.0.0-preview.01', 'not-a-version') {
        { ConvertTo-CompleteModuleVersion $_ } | Should -Throw -ErrorId 'PMU.UnsupportedProviderBehavior'
    }
}

BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Assert-NativeNuGetProvider' -Tag 'PMU', 'PMUProviderContracts' {
    BeforeEach {
        $script:provider = [pscustomobject]@{
            Version = [version]'3.0.0.1'
            ProviderPath = Join-Path $PSHOME 'Modules/PackageManagement/NuGet.dll'
        }
        Mock Get-PackageProvider { $script:provider }
    }

    It 'accepts the qualified NuGet binary from the selected runtime' {
        { Assert-NativeNuGetProvider } | Should -Not -Throw
    }

    It 'rejects another provider version rather than bootstrapping a replacement' {
        $provider.Version = [version]'3.0.0.0'
        { Assert-NativeNuGetProvider } | Should -Throw -ErrorId 'PMU.UnsupportedProviderBehavior'
    }

    It 'rejects a matching provider outside the runtime-owned directory' {
        $provider.ProviderPath = Join-Path $PSHOME 'Modules/PackageManagement-other/NuGet.dll'
        { Assert-NativeNuGetProvider } | Should -Throw -ErrorId 'PMU.UnsupportedProviderBehavior'
    }

    It 'propagates an unavailable provider without attempting installation' {
        Mock Get-PackageProvider { throw 'qualified provider unavailable' }
        { Assert-NativeNuGetProvider } | Should -Throw '*qualified provider unavailable*'
    }
}

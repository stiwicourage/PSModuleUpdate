BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    . "$PSScriptRoot/../../TestHelpers/Initialize-PMUTestPackage.ps1"
}

Describe 'Read-ManifestDefinition' -Tag 'PMU' {
    It 'returns manifest data without executing the declared root module' {
        $path = Initialize-PMUTestPackage $TestDrive '1.2.3-preview.1'
        $data = @(Read-ManifestDefinition -ManifestPath (Join-Path $path 'FixtureModule.psd1'))

        $data.Count | Should -Be 1
        $data[0] | Should -BeOfType [hashtable]
        $data[0].ModuleVersion | Should -BeExactly '1.2.3'
        $data[0].PrivateData.PSData.Prerelease | Should -BeExactly 'preview.1'
    }

    It 'reports unsafe data expressions before required-field validation' {
        $manifest = Join-Path $TestDrive 'Unsafe.psd1'
        Set-Content -LiteralPath $manifest -Value '@{ ModuleVersion = (Get-Date) }'

        { Read-ManifestDefinition -ManifestPath $manifest } |
            Should -Throw -ErrorId 'PMU.ModuleIdentityMismatch' -ExpectedMessage 'The module manifest cannot be safely read.'
    }

    It 'reports missing identity fields before checking a declared root module' {
        $manifest = Join-Path $TestDrive 'MissingIdentity.psd1'
        Set-Content -LiteralPath $manifest -Value "@{ ModuleVersion = '1.2.3'; RootModule = '../outside.psm1' }"

        { Read-ManifestDefinition -ManifestPath $manifest } |
            Should -Throw -ErrorId 'PMU.ModuleIdentityMismatch' -ExpectedMessage 'The module manifest must declare version and GUID.'
    }

    It 'rejects a declared root module outside the package' {
        $path = Initialize-PMUTestPackage $TestDrive '1.2.3'
        $manifest = Join-Path $path 'FixtureModule.psd1'
        $text = (Get-Content -LiteralPath $manifest -Raw).Replace("RootModule = 'FixtureModule.psm1'", "RootModule = '../outside.psm1'")
        Set-Content -LiteralPath $manifest -Value $text

        { Read-ManifestDefinition -ManifestPath $manifest } |
            Should -Throw -ErrorId 'PMU.ModuleIdentityMismatch' -ExpectedMessage 'The declared root module must remain inside the package directory.'
    }
}

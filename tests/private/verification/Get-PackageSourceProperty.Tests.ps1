BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-PackageSourceProperty' -Tag 'PMU' {
    Context 'Optional independently available metadata' {
        BeforeEach {
            $packageRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            $null = New-Item -ItemType Directory -Path $packageRoot
        }
        It 'reports corrupt metadata rather than treating it as valid provenance' {
            [IO.File]::WriteAllText((Join-Path $packageRoot 'PSGetModuleInfo.xml'), 'corrupt')
            { Get-PackageSourceProperty $packageRoot } | Should -Throw -ErrorId 'PMU.VerificationFailed'
        }
        It 'returns no provenance when optional metadata is missing' {
            Get-PackageSourceProperty $packageRoot | Should -BeNullOrEmpty
            Test-Path -LiteralPath (Join-Path $packageRoot 'PSGetModuleInfo.xml') | Should -BeFalse
        }
        It 'returns the available provenance property without modifying provider metadata' {
            $path = Join-Path $packageRoot 'PSGetModuleInfo.xml'
            [pscustomobject]@{ RepositorySourceLocation = 'https://feed.invalid/v3/index.json' } | Export-Clixml $path
            $hash = (Get-FileHash -LiteralPath $path).Hash
            $property = Get-PackageSourceProperty $packageRoot
            $property.Name | Should -BeExactly 'RepositorySourceLocation'
            $property.Value | Should -BeExactly 'https://feed.invalid/v3/index.json'
            (Get-FileHash -LiteralPath $path).Hash | Should -BeExactly $hash
        }
        It 'returns no provenance when readable metadata has no source property' {
            [pscustomobject]@{ Name = 'Fixture' } | Export-Clixml (Join-Path $packageRoot 'PSGetModuleInfo.xml')
            Get-PackageSourceProperty $packageRoot | Should -BeNullOrEmpty
        }
    }
}

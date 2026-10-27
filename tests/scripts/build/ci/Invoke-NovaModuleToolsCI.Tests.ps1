BeforeAll {
    Import-Module NovaModuleTools
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    $script:runnerSource = Join-Path $root 'scripts/build/ci/Invoke-NovaModuleToolsCI.ps1'

    function Initialize-CiCoverageFixture {
        param(
            [string]$Source,
            [string]$Root
        )

        $scripts = Join-Path $Root 'scripts/build/ci'
        $artifacts = Join-Path $Root 'artifacts'
        New-Item -ItemType Directory -Path @($scripts, $artifacts) -Force | Out-Null
        $runner = Copy-Item -LiteralPath $Source -Destination $scripts -PassThru
        return @{
            ProjectRoot = $Root
            ProjectName = 'CoverageFixture'
            OutputModuleDir = 'unused'
            Runner = $runner.FullName
        }
    }
}

Describe 'CI unit coverage production' -Tag 'BuildTooling', 'CiCoverage' {
    BeforeEach {
        $script:fixture = Initialize-CiCoverageFixture -Source $script:runnerSource -Root (Join-Path $TestDrive 'project')
        $script:location = (Get-Location).Path
        Mock Import-Module { }
        Mock Invoke-NovaBuild { 'build' }
        Mock Invoke-NovaTest { 'unit' }
        Mock Test-NovaBuild {
            Set-Content -LiteralPath './artifacts/TestResults.xml' -Value '<test-results />'
            'integration'
        }
        Set-Location -LiteralPath $script:fixture.ProjectRoot
        Mock Get-NovaProjectInfo {
            [pscustomobject]@{
                ProjectRoot = (Get-Location).Path
                ProjectName = 'CoverageFixture'
                OutputModuleDir = 'unused'
            }
        }
    }

    AfterEach {
        Set-Location -LiteralPath $script:location
    }

    It 'runs unit coverage before integration and retains its report in the output directory' {
        Mock Invoke-NovaTest {
            Set-Content -LiteralPath './artifacts/coverage.xml' -Value '<report name="unit" />'
            'unit'
        }
        $outputDirectory = Join-Path $script:fixture.ProjectRoot 'published'
        $output = @(& $script:fixture.Runner -OutputDirectory $outputDirectory)

        $output -join ',' | Should -BeExactly 'build,unit,integration'
        (Get-Content -LiteralPath (Join-Path $outputDirectory 'coverage.xml') -Raw).Trim() | Should -BeExactly '<report name="unit" />'
        Test-Path -LiteralPath (Join-Path $outputDirectory 'coveragefixture-nunit.xml') | Should -BeTrue
    }

    It 'applies the requested exclusions to both test phases' {
        & $script:fixture.Runner -OutputDirectory (Join-Path $script:fixture.ProjectRoot 'published') -ExcludeTag RepositoryLive

        Should -Invoke Invoke-NovaTest -Times 1 -Exactly -ParameterFilter { $ExcludeTagFilter -contains 'RepositoryLive' }
        Should -Invoke Test-NovaBuild -Times 1 -Exactly -ParameterFilter { $ExcludeTagFilter -contains 'RepositoryLive' }
    }
}

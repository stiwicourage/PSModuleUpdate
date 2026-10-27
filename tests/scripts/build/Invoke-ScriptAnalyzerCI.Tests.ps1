BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    $wrapper = Join-Path $root 'scripts/build/Invoke-ScriptAnalyzerCI.ps1'
    if (Test-Path -LiteralPath $wrapper) {
        . $wrapper
    }
    Import-Module PSScriptAnalyzer
    $script:analyzer = Get-Command Invoke-ScriptAnalyzer -Module PSScriptAnalyzer
}

Describe 'Repository analyzer entrypoint' -Tag 'BuildTooling', 'AnalyzerPolicy' {
    BeforeEach {
        $fixture = Join-Path $TestDrive 'project'
        New-Item -ItemType Directory -Path $fixture -Force | Out-Null
        foreach ($directory in @('src', 'tests', 'scripts', 'dist', 'artifacts')) {
            New-Item -ItemType Directory -Path (Join-Path $fixture $directory) -Force | Out-Null
        }
        Set-Content -LiteralPath (Join-Path $fixture 'run.ps1') -Value '$null'
        Mock Invoke-ScriptAnalyzer { }
        Mock Out-Host { }
    }

    It 'analyzes authored sources, tests, helpers and root scripts but not generated output' {
        Invoke-RepositoryAnalysis -ProjectRoot $fixture
        Should -Invoke Invoke-ScriptAnalyzer -Times 4 -Exactly
        Should -Invoke Invoke-ScriptAnalyzer -Times 0 -ParameterFilter {
            $Path -match '(dist|artifacts)$'
        }
        Should -Invoke Invoke-ScriptAnalyzer -Times 4 -ParameterFilter {
            $Recurse -and $Settings -like '*PSScriptAnalyzerSettings.psd1'
        }
    }

    It 'fails the gate when the analyzer reports findings' {
        Mock Invoke-ScriptAnalyzer { [pscustomobject]@{
                RuleName = 'PSAvoidUsingInvokeExpression'
                Message = 'Unsafe operation'
                Severity = 'Warning'
            } }
        { Invoke-RepositoryAnalysis -ProjectRoot $fixture } | Should -Throw '*ScriptAnalyzer*'
    }

    It 'propagates tool failures instead of reporting a clean result' {
        Mock Invoke-ScriptAnalyzer { throw 'Analyzer unavailable' }
        { Invoke-RepositoryAnalysis -ProjectRoot $fixture } | Should -Throw '*Analyzer unavailable*'
    }

    It 'does not report intentional Write-Host usage with repository settings' {
        Set-Content -LiteralPath (Join-Path $fixture 'src/status.ps1') -Value 'Write-Host "Status"'
        Mock Invoke-ScriptAnalyzer { & $script:analyzer -Path $Path -Recurse:$Recurse -Settings $Settings -ErrorAction Stop }

        { Invoke-RepositoryAnalysis -ProjectRoot $fixture } | Should -Not -Throw
        Should -Invoke Out-Host -Times 0 -Exactly
    }

    It 'still fails for other analyzer findings alongside intentional host output' {
        Set-Content -LiteralPath (Join-Path $fixture 'src/unsafe.ps1') -Value @(
            'Write-Host "Status"'
            'Invoke-Expression "Get-Date"'
        )
        Mock Invoke-ScriptAnalyzer { & $script:analyzer -Path $Path -Recurse:$Recurse -Settings $Settings -ErrorAction Stop }

        { Invoke-RepositoryAnalysis -ProjectRoot $fixture } | Should -Throw '*ScriptAnalyzer reported 1 finding(s)*'
    }
}

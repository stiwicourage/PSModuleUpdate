BeforeAll {
    Import-Module NovaModuleTools
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    $script:runnerSource = Join-Path $root 'run.ps1'
}

Describe 'Local quality pipeline' -Tag 'BuildTooling' {
    BeforeEach {
        $script:fixture = Join-Path $TestDrive 'runner'
        $script:buildScripts = Join-Path $script:fixture 'scripts/build'
        New-Item -ItemType Directory -Path $script:buildScripts -Force | Out-Null
        Copy-Item -LiteralPath $script:runnerSource -Destination (Join-Path $script:fixture 'run.ps1')
        Set-Content -LiteralPath (Join-Path $script:buildScripts 'Invoke-ScriptAnalyzerCI.ps1') -Value "'analyzer'"
        Set-Content -LiteralPath (Join-Path $script:buildScripts 'Test-TextFileFormatting.ps1') -Value "'formatting'"
        Mock Import-Module { }
        Mock Invoke-NovaBuild { 'build' }
        Mock Invoke-NovaTest { 'unit' }
        Mock Test-NovaBuild { 'integration' }
    }

    It 'runs Nova checks in the documented order and restores the working directory' {
        $location = Get-Location
        $output = @(& (Join-Path $script:fixture 'run.ps1'))
        $output -join ',' | Should -BeExactly 'analyzer,build,unit,integration,formatting'
        (Get-Location).Path | Should -BeExactly $location.Path
    }

    It 'stops before build when analysis fails and still restores the working directory' {
        Set-Content -LiteralPath (Join-Path $script:buildScripts 'Invoke-ScriptAnalyzerCI.ps1') -Value "throw 'Analysis failed'"
        $location = Get-Location
        { & (Join-Path $script:fixture 'run.ps1') } | Should -Throw '*Analysis failed*'
        Should -Invoke Invoke-NovaBuild -Times 0
        (Get-Location).Path | Should -BeExactly $location.Path
    }

    It 'does not run integration or formatting after a unit-test failure' {
        Mock Invoke-NovaTest { throw 'Unit tests failed' }
        { & (Join-Path $script:fixture 'run.ps1') } | Should -Throw '*Unit tests failed*'
        Should -Invoke Test-NovaBuild -Times 0
    }

    It 'selects Nova-compatible Pester before analyzer tooling can autoload another major version' {
        Mock Import-Module {
            if ($Name -eq 'Pester') {
                Set-Content -LiteralPath './pester.ready' -Value 'ready'
            }
        }
        $probe = @'
if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot '../../pester.ready'))) {
    throw 'Compatible Pester was not selected before analysis'
}
'analyzer'
'@
        Set-Content -LiteralPath (Join-Path $script:buildScripts 'Invoke-ScriptAnalyzerCI.ps1') -Value $probe
        { & (Join-Path $script:fixture 'run.ps1') } | Should -Not -Throw
        Should -Invoke Import-Module -Times 1 -ParameterFilter {
            $Name -eq 'Pester' -and $MinimumVersion -eq '5.7.1' -and $MaximumVersion -eq '5.10.0'
        }
    }
}

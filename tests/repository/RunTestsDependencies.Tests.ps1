# Cross-cutting contract: Tests.yml hands one owned dependency root across fresh pwsh steps.
BeforeAll {
    $script:root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:workflow = Get-Content -LiteralPath (Join-Path $script:root '.github/workflows/Tests.yml') -Raw
    . (Join-Path $script:root 'scripts/build/ci/CiDependencyRoot.ps1')

    function Get-DependencyWorkflowStep {
        param([string]$Name)
        $pattern = '(?ms)^      - name: ' + [regex]::Escape($Name) + '\r?\n.*?(?=^      - name:|^  [a-z]|\z)'
        return [regex]::Match($script:workflow, $pattern).Value
    }

    function Get-DependencyWorkflowCommand {
        param([string]$Step)
        $block = [regex]::Match($Step, '(?ms)^        run: \|\r?\n(.*)').Groups[1].Value
        return ($block -replace '(?m)^          ', '').TrimEnd()
    }

    function Invoke-DependencyWorkflowChild {
        param([string]$Command, [string]$ModuleRoot)
        $location = $script:root.Replace("'", "''")
        $path = $ModuleRoot.Replace("'", "''")
        $preamble = "`$ErrorActionPreference = 'Stop'; Set-Location '$location'; `$env:CI_MODULE_ROOT = '$path';"
        $output = & (Get-Process -Id $PID).Path -NoLogo -NoProfile -Command ($preamble + $Command) 2>&1
        return @{ ExitCode = $LASTEXITCODE; Output = ($output -join "`n") }
    }
}

Describe 'Run Tests dependency lifecycle' -Tag 'BuildTooling', 'RunTestsDependencies' {
    It 'exposes the saved root through a named install step with <LineEnding> line endings' -ForEach @(
        @{ LineEnding = 'LF'; NewLine = "`n" }
        @{ LineEnding = 'CRLF'; NewLine = "`r`n" }
    ) {
        $step = (Get-DependencyWorkflowStep 'Install required CI PowerShell modules') -replace '\r?\n', $NewLine
        $step | Should -Match '(?m)^        id: modules\r?$'
        $step | Should -Match 'run: ./scripts/build/ci/Install-CiPowerShellModules.ps1'
    }

    It 'isolates dependencies before <Name> in a fresh process' -ForEach @(
        @{ Name = 'Run NovaModuleTools CI test and coverage workflow'; Boundary = './scripts/build/ci/Invoke-NovaModuleToolsCI.ps1' }
        @{ Name = 'Validate repository changelog with Test-KeepAChangelogFile'; Boundary = '$result = Test-KeepAChangelogFile' }
    ) {
        $step = Get-DependencyWorkflowStep $Name
        $step | Should -Match 'CI_MODULE_ROOT: \$\{\{ steps\.modules\.outputs\.moduleRoot \}\}'
        $command = Get-DependencyWorkflowCommand $step
        $setup = ($command -split [regex]::Escape($Boundary), 2)[0]
        $setup | Should -Match '\$env:PSModulePath = Get-CiIsolatedModulePath -ModuleRoot \$env:CI_MODULE_ROOT'
        $owner = New-CiDependencyRoot -Path (Join-Path $TestDrive "pmu-ci-modules-$([guid]::NewGuid().ToString('N'))")
        $module = New-Item -ItemType Directory -Path (Join-Path $owner.Path 'NovaModuleTools')
        Set-Content -LiteralPath (Join-Path $module.FullName 'NovaModuleTools.psm1') -Value '# disposable discovery fixture'
        $probe = 'Import-Module NovaModuleTools -ErrorAction Stop; (Get-Module NovaModuleTools).ModuleBase; $env:PSModulePath'
        $result = Invoke-DependencyWorkflowChild -Command ($setup + "`n" + $probe) -ModuleRoot $owner.Path
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -BeExactly ($module.FullName + "`n" + (Get-CiIsolatedModulePath -ModuleRoot $owner.Path))
    }

    It 'fails closed for an unowned dependency root before running CI' {
        $step = Get-DependencyWorkflowStep 'Run NovaModuleTools CI test and coverage workflow'
        $setup = (Get-DependencyWorkflowCommand $step) -split [regex]::Escape('./scripts/build/ci/Invoke-NovaModuleToolsCI.ps1'), 2
        $result = Invoke-DependencyWorkflowChild -Command ($setup[0] + "`n'consumer reached'") -ModuleRoot $TestDrive
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Not -Match 'consumer reached'
    }

    It 'imports Nova explicitly for changelog validation' {
        $command = Get-DependencyWorkflowCommand (Get-DependencyWorkflowStep 'Validate repository changelog with Test-KeepAChangelogFile')
        $command | Should -Match '(?s)Import-Module NovaModuleTools -ErrorAction Stop.*\$result = Test-KeepAChangelogFile'
    }

    It 'always schedules owned cleanup after both consumers when installation produced a root' {
        $step = Get-DependencyWorkflowStep 'Clean owned CI dependencies'
        $step | Should -Match 'if: \$\{\{ always\(\) && steps\.modules\.outputs\.moduleRoot != '''' \}\}'
        $step | Should -Match 'CI_MODULE_ROOT: \$\{\{ steps\.modules\.outputs\.moduleRoot \}\}'
        $script:workflow.IndexOf($step) | Should -BeGreaterThan $script:workflow.IndexOf('Validate repository changelog')
        $step | Should -Not -Match 'Remove-Item'
    }

    It 'executes validated cleanup in a fresh process and refuses <Kind> ownership' -ForEach @(
        @{ Kind = 'valid'; Tamper = $false; ExitCode = 0; Remains = $false }
        @{ Kind = 'invalid'; Tamper = $true; ExitCode = 1; Remains = $true }
    ) {
        $owner = New-CiDependencyRoot -Path (Join-Path $TestDrive "pmu-ci-modules-$([guid]::NewGuid().ToString('N'))")
        if ($Tamper) { Set-Content -LiteralPath (Join-Path $owner.Path '.pmu-dependencies.json') -Value '{}' }
        $command = Get-DependencyWorkflowCommand (Get-DependencyWorkflowStep 'Clean owned CI dependencies')
        $command | Should -Match 'Remove-CiDependencyRoot -Owner \(Get-CiDependencyOwner -Path \$env:CI_MODULE_ROOT\)'
        $result = Invoke-DependencyWorkflowChild -Command $command -ModuleRoot $owner.Path
        $result.ExitCode | Should -Be $ExitCode -Because $result.Output
        Test-Path -LiteralPath $owner.Path | Should -Be $Remains
    }
}

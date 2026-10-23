[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

function Get-RepositoryAnalysisTarget {
    param([string]$ProjectRoot)

    foreach ($relativePath in @('src', 'tests', 'scripts')) {
        $path = Join-Path $ProjectRoot $relativePath
        if (Test-Path -LiteralPath $path -PathType Container) {
            $path
        }
    }
    Get-ChildItem -LiteralPath $ProjectRoot -File -Filter '*.ps1' | Select-Object -ExpandProperty FullName
}

function Invoke-RepositoryAnalysis {
    param([string]$ProjectRoot)

    $settingsPath = Join-Path $PSScriptRoot 'PSScriptAnalyzerSettings.psd1'
    $findings = @(foreach ($path in @(Get-RepositoryAnalysisTarget -ProjectRoot $ProjectRoot)) {
        Invoke-ScriptAnalyzer -Path $path -Recurse -Settings $settingsPath -ErrorAction Stop
    })
    if ($findings.Count -gt 0) {
        $findings | Format-Table RuleName, ScriptName, Line, Message -Wrap | Out-Host
        throw "ScriptAnalyzer reported $($findings.Count) finding(s). Fix them before continuing."
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Import-Module PSScriptAnalyzer -ErrorAction Stop
    Invoke-RepositoryAnalysis -ProjectRoot $ProjectRoot
}

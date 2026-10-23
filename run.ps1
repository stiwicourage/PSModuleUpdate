[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    Import-Module Pester -MinimumVersion 5.7.1 -MaximumVersion 5.10.0 -ErrorAction Stop
    & ./scripts/build/Invoke-ScriptAnalyzerCI.ps1
    Import-Module NovaModuleTools -ErrorAction Stop
    Invoke-NovaBuild
    Invoke-NovaTest
    Test-NovaBuild
    & ./scripts/build/Test-TextFileFormatting.ps1
} finally {
    Pop-Location
}

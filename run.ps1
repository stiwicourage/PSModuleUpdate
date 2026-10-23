[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    & ./scripts/build/Invoke-ScriptAnalyzerCI.ps1
    Import-Module NovaModuleTools -ErrorAction Stop
    Invoke-NovaBuild
    Invoke-NovaTest
    Test-NovaBuild
    & ./scripts/build/Test-TextFileFormatting.ps1
} finally {
    Pop-Location
}

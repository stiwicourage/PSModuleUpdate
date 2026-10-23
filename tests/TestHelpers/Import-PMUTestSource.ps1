Set-StrictMode -Version Latest
. "$PSScriptRoot/Get-PMUTestCommandReference.ps1"
. "$PSScriptRoot/Get-PMUTestSourcePath.ps1"
foreach ($sourceFile in Get-PMUTestSourcePath $MyInvocation.ScriptName) { . $sourceFile }

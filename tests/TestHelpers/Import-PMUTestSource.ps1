Set-StrictMode -Version Latest
. "$PSScriptRoot/Get-PMUTestCommandReference.ps1"
. "$PSScriptRoot/Get-PMUTestSourcePath.ps1"

function Import-PMUTestSource {
    param([string]$PmuTestSourceCaller)

    foreach ($pmuTestSourceFile in Get-PMUTestSourcePath $PmuTestSourceCaller) {
        $pmuTestSourceName = [IO.Path]::GetFileNameWithoutExtension($pmuTestSourceFile)
        $pmuTestSourceCommand = Microsoft.PowerShell.Core\Get-Command -Name $pmuTestSourceName -CommandType Function -ErrorAction SilentlyContinue
        if ($pmuTestSourceCommand -and $pmuTestSourceCommand.ScriptBlock.File -eq $pmuTestSourceFile) {
            continue
        }
        . $pmuTestSourceFile
    }
}

. Import-PMUTestSource -PmuTestSourceCaller $MyInvocation.ScriptName

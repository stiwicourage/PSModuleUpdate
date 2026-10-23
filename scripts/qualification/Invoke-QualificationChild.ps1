[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
. "$PSScriptRoot/QualificationSafety.ps1"
. "$PSScriptRoot/QualificationSession.ps1"
. "$PSScriptRoot/QualificationRepository.ps1"
. "$PSScriptRoot/QualificationScenario.ps1"
function Invoke-QualificationChild {
    $options = ConvertFrom-Json $env:PMU_QUALIFICATION_OPTIONS -AsHashtable
    Initialize-QualificationOption $options
    $session = Initialize-QualificationSession $options
    Invoke-QualificationSession $session
    $session.Evidence | ConvertTo-Json -Depth 30 -Compress
}

function Invoke-QualificationSession {
    param([object]$Session)
    try {
        Initialize-QualificationRegistration $Session
        Invoke-QualificationScenario $Session
    } catch {
        Write-QualificationFailureEvidence $Session $_
    } finally { Complete-QualificationSession $Session }
}

function Write-QualificationFailureEvidence {
    param([object]$Session, [System.Management.Automation.ErrorRecord]$Failure)
    $Session.Evidence.Failure = 'Operation failed; raw authenticated diagnostics withheld.'
    $Session.Evidence.ErrorType = $Failure.Exception.GetType().Name
    $Session.Evidence.FailureLocation = "$([IO.Path]::GetFileName($Failure.InvocationInfo.ScriptName)):$($Failure.InvocationInfo.ScriptLineNumber)"
    $parameter = $Failure.Exception.PSObject.Properties['ParameterName']
    if ($parameter) { $Session.Evidence.FailureParameter = $parameter.Value }
    if ($Failure.FullyQualifiedErrorId -match 'PMU\.[A-Za-z]+') { $Session.Evidence.ErrorId = $Matches[0] }
}

Invoke-QualificationChild

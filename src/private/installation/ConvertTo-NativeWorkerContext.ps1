function ConvertTo-NativeWorkerContext {
    param(
        [object]$Operation,
        [object]$Snapshot,
        [bool]$AlreadyInstalled
    )

    $modules = @(Get-Module -Name PSModuleUpdate)
    if ($modules.Count -ne 1) {
        Write-PMUError 'PMU.UnsupportedProviderBehavior' 'The native worker requires the current built PMU module instance.'
    }
    $copy = ConvertTo-NativeWorkerOperation $Operation $Snapshot
    [pscustomobject]@{
        Operation = $copy
        Snapshot = $Snapshot
        AlreadyInstalled = $AlreadyInstalled
        ModulePath = $modules[0].Path
        Token = Get-NativeJournalToken $Operation
        ParentPid = $PID
        ParentStarted = Get-RepositoryProcessStart $PID
    }
}

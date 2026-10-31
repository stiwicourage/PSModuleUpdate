function Invoke-NativeWorkerAction {
    param([object]$Context)
    if ($Context.PSObject.Properties['InspectManifest']) {
        $null = @(Initialize-StagedPackage $Context.Operation)
        Write-NativeWorkerMessage (ConvertTo-NativeWorkerResult $null $null)
        return
    }
    Write-NativeWorkerMessage ([pscustomobject]@{
            Phase = 'READY'
        })
    Assert-NativeWorkerGo ([Console]::In)
    Invoke-NativeWorkerLease $Context
}

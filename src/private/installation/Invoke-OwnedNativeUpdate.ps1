function Invoke-OwnedNativeUpdate {
    param([object]$Context)
    $operation = $Context.Operation
    try {
        $tree = @(Initialize-StagedPackage $operation)
        Assert-NativeSelectedInstallation $Context
        $operation.Journal.StagedTree = $tree
        if ($Context.AlreadyInstalled) {
            Confirm-NativeExistingTarget $operation $tree
        } else {
            Invoke-ProviderInstallation $operation $tree
        }
        ConvertTo-NativeWorkerResult $operation $null
    } catch {
        ConvertTo-NativeWorkerResult $operation $_
    }
}

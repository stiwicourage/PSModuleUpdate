function Invoke-PMUNativeHandoffMock {
    param(
        [object]$Operation,
        [bool]$AlreadyInstalled
    )

    # Source-level public characterizations keep their original provider doubles.
    # Native lock transfer, worker isolation and public built acceptance have separate process fixtures.
    $tree = @(Initialize-StagedPackage $Operation)
    if (-not $AlreadyInstalled) {
        Initialize-Replacement $Operation $tree
        Invoke-ProviderInstallation $Operation $tree
    }
    $tree
}

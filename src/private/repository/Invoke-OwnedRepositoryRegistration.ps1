function Invoke-OwnedRepositoryRegistration {
    param(
        [object]$Source,
        [string]$Root
    )

    $lease = Initialize-OwnedRepositoryLease $Source $Root
    try {
        Register-OwnedRepository $lease
    } catch {
        $failure = $_
        Undo-OwnedRepositoryRegistration $lease $failure
        throw $failure
    }
    $lease
}

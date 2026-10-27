function Initialize-NativeRepositoryStore {
    param([object]$Operation)
    Assert-NativeProviderPath $Operation (Get-NativeProviderPath)
    $repositories = @(PowerShellGet\Get-PSRepository -ErrorAction Stop -WarningAction SilentlyContinue)
    $registered = $false
    foreach ($repository in $repositories) {
        if ($repository.Name -ieq $Operation.RepositoryName) {
            $registered = $true
        } else {
            $null = PowerShellGet\Unregister-PSRepository -Name $repository.Name -ErrorAction Stop
        }
    }
    $registered
}

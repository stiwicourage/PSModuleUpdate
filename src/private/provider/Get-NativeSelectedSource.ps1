function Get-NativeSelectedSource {
    param([object]$Operation, [string]$SelectedPath, [bool]$AllowUnmanaged)
    if ($AllowUnmanaged -and (Test-UnmanagedInstallation $Operation $SelectedPath)) {
        return [pscustomobject]@{
            Name = Get-OperationRepositoryName $Operation
            Uri = $Operation.Plan.RepositoryUri
            Unmanaged = $true
        }
    }
    $source = Get-NativeInstalledSource $Operation $SelectedPath
    $source | Select-Object Name, Uri, @{ Name = 'Unmanaged'; Expression = { $false } }
}

function Get-NativeInstalledSource {
    param(
        [object]$Operation,
        [string]$SelectedPath
    )

    $metadata = Read-NativeInstallationRecord $SelectedPath
    Assert-NativeInstallationRecord $metadata $Operation $SelectedPath
    $uri = ConvertTo-ProviderSourceUri $metadata.RepositorySourceLocation
    if ($uri -cne $Operation.Plan.RepositoryUri) {
        Write-PMUError 'PMU.SourceMismatch' 'The selected native installation came from another repository.'
    }
    [pscustomobject]@{
        Name = [string]$metadata.Repository
        Uri = $uri
    }
}

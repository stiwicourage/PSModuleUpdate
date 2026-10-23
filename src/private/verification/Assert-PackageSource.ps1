function Assert-PackageSource {
    param([string]$Path, [object]$Plan)
    $property = Get-PackageSourceProperty $Path
    if (-not $property) { return }
    if (-not $property.Value) { return }
    if ((Assert-RepositoryUri ([uri]$property.Value)) -cne $Plan.RepositoryUri) {
        Write-PMUError 'PMU.VerificationFailed' 'Package source metadata does not match the planned repository.'
    }
}

function Assert-NativeCandidate {
    param(
        [object]$Operation,
        [object]$Candidate
    )

    if (-not $Candidate) {
        Write-PMUError 'PMU.UnsupportedInstallation' 'Native update cannot recognize an existing installation.'
    }
    $path = Assert-SafePath $Candidate.InstalledLocation
    $manifest = Join-Path $path "$($Operation.Plan.ModuleName).psd1"
    Assert-ObservedNativeIdentity $Operation $manifest
    $null = Get-NativeInstalledSource $Operation $path
    if ($Candidate.Repository -ine $Operation.RepositoryName) {
        Write-PMUError 'PMU.SourceMismatch' 'Native update selected another source name.'
    }
}

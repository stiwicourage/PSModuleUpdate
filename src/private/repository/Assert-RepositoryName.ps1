function Assert-RepositoryName {
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name) -or [System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Name)) {
        Write-PMUError 'PMU.InvalidRequest' 'Repository must be one literal registered name.'
    }
}

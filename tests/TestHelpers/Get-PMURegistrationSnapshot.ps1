function Get-PMURegistrationSnapshot {
    $records = @(Get-PSResourceRepository | Sort-Object Name | Select-Object Name, Uri, Trusted, Priority, ApiVersion) | ConvertTo-Json -Depth 5 -Compress
    $store = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PSResourceGet/PSResourceRepository.xml'
    [pscustomobject]@{
        Records = $records
        Hash = (Get-FileHash -LiteralPath $store -Algorithm SHA256).Hash
    }
}

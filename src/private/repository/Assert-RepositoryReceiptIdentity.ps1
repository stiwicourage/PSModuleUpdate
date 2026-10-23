function Assert-RepositoryReceiptIdentity {
    param([object]$Receipt)
    $values = @(
        "$($Receipt.SchemaVersion)" -ceq '1'
        "$($Receipt.OperationId)" -cmatch '^[a-f0-9]{32}$'
        "$($Receipt.RegistrationName)" -ceq "pmu-uri-$($Receipt.OperationId)"
        "$($Receipt.OwnerPid)" -match '^[1-9][0-9]{0,9}$'
        "$($Receipt.OwnerStartedUtcTicks)" -match '^[0-9]{18}$'
        "$($Receipt.UriHash)" -cmatch '^[A-F0-9]{64}$'
        "$($Receipt.ApiVersion)" -cin @('Unknown', 'V2', 'V3', 'Local', 'NugetServer', 'ContainerRegistry')
    )
    if ($false -in $values) { Write-PMUError 'PMU.RepositoryRecoveryRequired' 'Repository receipt identity is invalid.' }
}

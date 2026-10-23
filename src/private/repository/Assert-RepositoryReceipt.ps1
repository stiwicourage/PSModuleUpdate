function Assert-RepositoryReceipt {
    param([object]$Receipt)
    $expected = @('ApiVersion', 'OperationId', 'OwnerPid', 'OwnerStartedUtcTicks', 'Priority', 'RegistrationName', 'SchemaVersion', 'Trusted', 'UriHash')
    if ((@($Receipt.PSObject.Properties.Name | Sort-Object) -join ',') -cne ($expected -join ',')) {
        Write-PMUError 'PMU.RepositoryRecoveryRequired' 'Repository receipt schema is invalid.'
    }
    Assert-RepositoryReceiptIdentity $Receipt
    Assert-MatchingProperty $Receipt ([pscustomobject]@{ Trusted = $false; Priority = 50 }) @('Trusted', 'Priority') 'PMU.RepositoryRecoveryRequired'
}

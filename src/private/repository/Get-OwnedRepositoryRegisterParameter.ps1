function Get-OwnedRepositoryRegisterParameter {
    param([object]$Lease)
    $parameters = @{
        Name = $Lease.Name
        Uri = $Lease.Source.Uri
        Priority = 50
        ErrorAction = 'Stop'
    }
    if ($Lease.Receipt.ApiVersion -ne 'Unknown') {
        $parameters.ApiVersion = $Lease.Receipt.ApiVersion
    }
    $parameters
}

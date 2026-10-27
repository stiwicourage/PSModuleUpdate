function Assert-PolicyValue {
    param(
        [string]$Name,
        [object]$Value,
        [type]$Type,
        [string[]]$Allowed = @()
    )

    if ($null -eq $Value) {
        return
    }
    if ($Value -isnot $Type) {
        Write-PMUError 'PMU.InvalidRequest' "Policy field $Name has the wrong type."
    }
    if ($Allowed.Count -and $Value -cnotin $Allowed) {
        Write-PMUError 'PMU.InvalidRequest' "Policy field $Name has an unsupported value."
    }
}

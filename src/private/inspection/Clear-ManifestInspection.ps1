function Clear-ManifestInspection {
    param([object]$Operation)
    $Operation.Credential = $null
    $expected = Join-Path $Operation.DataRoot "inspection-$($Operation.Journal.TransactionId)"
    if ($Operation.WorkRoot -cne $expected) {
        Write-PMUError 'PMU.RecoveryRequired' 'Refusing to remove an unexpected inspection workspace.'
    }
    $null = Assert-SafePath $expected
    if (Test-Path -LiteralPath $expected) {
        $null = @(Get-FileTreeInventory $expected)
        Remove-Item -LiteralPath $expected -Recurse -Force -ErrorAction Stop
    }
}

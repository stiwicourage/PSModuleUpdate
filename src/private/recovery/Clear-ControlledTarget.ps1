function Clear-ControlledTarget {
    param([object]$Journal)
    $expected = Join-Path $Journal.DestinationRoot "$($Journal.ModuleName)/$($Journal.TargetNumericVersion)"
    if ($expected -cne $Journal.TargetPath) { Write-PMUError 'PMU.RecoveryRequired' 'Refusing an unexpected removal path.' }
    $null = Assert-SafePath $expected
    if (Test-Path -LiteralPath $expected) {
        $null = @(Get-FileTreeInventory $expected)
        Assert-RecoveryTargetIdentity $Journal
        Remove-Item -LiteralPath $expected -Recurse -Force -ErrorAction Stop
    }
}

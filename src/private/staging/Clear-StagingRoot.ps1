function Clear-StagingRoot {
    param([object]$Operation)
    $expected = Join-Path $Operation.WorkRoot 'stage'
    if ($Operation.StageRoot -cne $expected) { Write-PMUError 'PMU.RecoveryRequired' 'Refusing to clear an unexpected staging path.' }
    $null = Assert-SafePath $expected
    if (-not (Test-Path -LiteralPath $expected)) { return }
    $null = @(Get-FileTreeInventory $expected)
    Remove-Item -LiteralPath $expected -Recurse -Force -ErrorAction Stop
}

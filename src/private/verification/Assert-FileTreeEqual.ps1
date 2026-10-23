function Assert-FileTreeEqual {
    param([object[]]$Expected, [object[]]$Actual, [string]$ErrorId = 'PMU.VerificationFailed')
    $left = ConvertTo-Json @($Expected) -Depth 4 -Compress
    $right = ConvertTo-Json @($Actual) -Depth 4 -Compress
    if ($left -cne $right) { Write-PMUError $ErrorId 'The complete file tree does not match the verified reference.' }
}

function Assert-MatchingProperty {
    param([object]$Actual, [object]$Expected, [string[]]$Property, [string]$ErrorId)
    foreach ($name in $Property) {
        if ($Actual.$name -cne $Expected.$name) {
            Write-PMUError $ErrorId 'A required identity or environment precondition changed.'
        }
    }
}

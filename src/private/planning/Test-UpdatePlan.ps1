function Test-UpdatePlan {
    param([object]$Plan)
    $record = $null
    if (-not (Get-LivePlanRegistry).TryGetValue($Plan, [ref]$record)) {
        Write-PMUError 'PMU.InvalidPlan' 'A live plan returned by Get-PSModuleUpdate in this module instance is required.'
    }
    if ($Plan.PSObject.TypeNames[0] -cne 'PSModuleUpdate.UpdatePlan' -or $record.Snapshot -cne (ConvertTo-Json $Plan -Depth 12 -Compress)) {
        Write-PMUError 'PMU.InvalidPlan' 'The plan was modified or is not a live schema-1 plan.'
    }
    $record
}

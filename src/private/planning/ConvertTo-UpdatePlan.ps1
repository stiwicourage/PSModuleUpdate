function ConvertTo-UpdatePlan {
    param([object]$Context)
    $fields = [ordered]@{ PSTypeName = 'PSModuleUpdate.UpdatePlan' }
    $groups = @((Get-PlanRuntimeField $Context), (Get-PlanInstallationField $Context), (Get-PlanTargetField $Context), (Get-PlanDecisionField $Context))
    foreach ($group in $groups) {
        foreach ($entry in $group.GetEnumerator()) { $fields[$entry.Key] = $entry.Value }
    }
    [pscustomobject]$fields
}

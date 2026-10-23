function Get-LivePlanRegistry {
    param()
    if (-not (Get-Variable -Name PmuLivePlans -Scope Script -ErrorAction SilentlyContinue)) {
        $script:PmuLivePlans = [System.Runtime.CompilerServices.ConditionalWeakTable[object, object]]::new()
    }
    ,$script:PmuLivePlans
}

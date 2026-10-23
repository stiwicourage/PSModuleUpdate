function ConvertTo-DeclinedUpdateResult {
    param([object]$Plan)
    $outcome = 'Cancelled'
    if ($WhatIfPreference) { $outcome = 'WhatIf' }
    ConvertTo-UpdateResult $Plan $outcome
}

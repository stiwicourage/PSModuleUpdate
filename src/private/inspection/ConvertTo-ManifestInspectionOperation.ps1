function ConvertTo-ManifestInspectionOperation {
    param([object]$Operation)
    $nonce = [guid]::NewGuid().ToString('N')
    $Operation.DataRoot = Resolve-PMUDataRoot 'CurrentUser'
    $root = Join-Path $Operation.DataRoot "inspection-$nonce"
    $workspace = ConvertTo-InstallationWorkspace $Operation.Plan $Operation.DataRoot $root
    $Operation | Add-Member -NotePropertyMembers $workspace -Force
    $Operation.Journal = [pscustomobject]@{
        TransactionId = $nonce
    }
    $Operation
}

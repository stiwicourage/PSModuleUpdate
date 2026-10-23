function Get-PMUBackupModuleReference {
    param([string]$Root)
    $journals = @(Get-ChildItem "$Root/data" -Filter 'journal.json' -Recurse)
    if ($journals.Count -ne 1) { throw 'Expected exactly one isolated fixture journal.' }
    $journal = Get-Content $journals[0].FullName -Raw | ConvertFrom-Json
    Get-Module -ListAvailable (Join-Path $journal.BackupPath "$($journal.ModuleName).psd1")
}

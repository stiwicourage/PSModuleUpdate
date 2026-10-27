function Clear-PMUOwnedRegistration {
    param(
        [object]$Fixture,
        [object]$Before
    )

    if (Get-PSResourceRepository -Name $Fixture.Repository -ErrorAction SilentlyContinue) {
        Unregister-PSResourceRepository -Name $Fixture.Repository -Confirm:$false
    }
    $after = Get-PMURegistrationSnapshot
    if ($Before.Records -cne $after.Records) {
        throw 'Existing provider registrations were not preserved.'
    }
    if ($Before.Hash -cne $after.Hash) {
        throw 'Provider registration store bytes changed after cleanup.'
    }
}

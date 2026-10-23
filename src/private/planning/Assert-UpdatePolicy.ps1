function Assert-UpdatePolicy {
    param([hashtable]$Policy)
    if ($null -eq $Policy.Channel) { Write-PMUError 'PMU.InvalidRequest' 'Channel cannot be null.' }
    if ($null -eq $Policy.Scope) { Write-PMUError 'PMU.InvalidRequest' 'Scope cannot be null.' }
    Assert-PolicyValue 'Channel' $Policy.Channel ([string]) @('Stable', 'IncludePrerelease')
    Assert-PolicyValue 'Scope' $Policy.Scope ([string]) @('CurrentUser', 'AllUsers')
    Assert-PolicyValue 'ExpectedRepositoryUri' $Policy.ExpectedRepositoryUri ([uri])
    Assert-PolicyValue 'VersionRange' $Policy.VersionRange ([string])
}

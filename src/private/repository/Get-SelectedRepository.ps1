function Get-SelectedRepository {
    param(
        [object]$Selection,
        [uri]$ExpectedUri
    )

    if ($Selection -is [string]) {
        return Get-RepositorySnapshot $Selection $ExpectedUri
    }
    if ($Selection.Uri) {
        return Get-RepositorySnapshotByUri $Selection.Uri $ExpectedUri
    }
    Get-RepositorySnapshot $Selection.Name $ExpectedUri
}

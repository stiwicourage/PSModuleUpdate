function Get-PMULocalSelection {
    param([object]$Fixture, [string]$Version)
    if ($Version -eq '2.0.0-preview.2') { return @{ Repository = $Fixture.Repository } }
    @{ RepositoryUri = [uri]::new([IO.Path]::GetFullPath($Fixture.Feed), [UriKind]::Absolute) }
}

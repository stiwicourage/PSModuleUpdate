function Initialize-PMURepositoryFixture {
    param([string]$Root)
    $root = Join-Path $Root ([guid]::NewGuid().ToString('N'))
    $fixture = [pscustomobject]@{
        Root = $root
        Modules = Join-Path $root 'Modules'
        Data = Join-Path $root 'data'
        Name = "PmuTarget$([guid]::NewGuid().ToString('N'))"
        Guid = [guid]::NewGuid()
        Module = $null
        Calls = [Collections.Generic.List[object]]::new()
        Repositories = Get-PMURepositoryEntry
    }
    $path = Initialize-PMUTestPackage $fixture.Modules '2.0.0-preview.1' $fixture.Guid $fixture.Name
    $fixture.Module = Get-Module -ListAvailable "$path/$($fixture.Name).psd1"
    $fixture
}

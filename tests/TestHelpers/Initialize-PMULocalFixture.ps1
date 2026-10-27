function Initialize-PMULocalFixture {
    param([string]$Root)
    $expectedRoot = [IO.Path]::GetFullPath((Join-Path $Root 'home/.local/share/powershell/Modules'))
    $actualRoot = [IO.Path]::GetFullPath((Get-PMUFixtureProviderRoot))
    if ($actualRoot -cne $expectedRoot) {
        throw 'Provider destination is not the isolated child HOME. No installation is permitted.'
    }
    $fixture = [pscustomobject]@{
        Root = $Root
        Feed = Join-Path $Root 'feed'
        Name = "PmuOffline$([guid]::NewGuid().ToString('N'))"
        Guid = [guid]::NewGuid()
        Repository = "PmuOwned$([guid]::NewGuid().ToString('N'))"
        Module = $null
    }
    $null = New-Item $fixture.Feed -ItemType Directory
    Initialize-PMUNativeLocalInstallation $fixture $actualRoot
    $fixture
}

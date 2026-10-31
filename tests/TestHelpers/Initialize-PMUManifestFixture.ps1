function Initialize-PMUManifestFixture {
    param(
        [object]$Fixture,
        [string]$MinimumVersion,
        [string]$Version = '2.0.0-preview2'
    )
    $path = Join-Path $Fixture.Feed "$($Fixture.Name).$Version.nupkg"
    $archive = [IO.Compression.ZipFile]::Open($path, [IO.Compression.ZipArchiveMode]::Update)
    try {
        Initialize-PMUArchiveManifest $archive "$($Fixture.Name).psd1" $MinimumVersion
    } finally {
        $archive.Dispose()
    }
}

function Initialize-PMUArchiveManifest {
    param(
        [object]$Archive,
        [string]$Name,
        [string]$MinimumVersion
    )
    $text = Read-PMUFixtureArchiveManifest $Archive $Name
    $text = $text -replace "Gerber = @\{ MinimumGerberVersion = '[^']+' \}; ", ''
    Write-PMUFixtureArchiveManifest $Archive $Name ($text.Replace('PrivateData = @{', "PrivateData = @{ Gerber = @{ MinimumGerberVersion = '$MinimumVersion' };"))
}

function Read-PMUFixtureArchiveManifest {
    param(
        [object]$Archive,
        [string]$Name
    )
    $reader = [IO.StreamReader]::new($Archive.GetEntry($Name).Open())
    try {
        $reader.ReadToEnd()
    } finally {
        $reader.Dispose()
    }
}

function Write-PMUFixtureArchiveManifest {
    param(
        [object]$Archive,
        [string]$Name,
        [string]$Text
    )
    $Archive.GetEntry($Name).Delete()
    $writer = [IO.StreamWriter]::new($Archive.CreateEntry($Name).Open())
    try {
        $writer.Write($Text)
    } finally {
        $writer.Dispose()
    }
}

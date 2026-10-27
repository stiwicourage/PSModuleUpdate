function Initialize-PMUTestPackage {
    param(
        [string]$Root,
        [string]$Version,
        [guid]$Guid = 'a1111111-1111-1111-1111-111111111111',
        [string]$Name = 'FixtureModule'
    )

    $parts = @($Version -split '-', 2) + @('')
    $directory = Join-Path $Root "$Name/$($parts[0])"
    $null = New-Item $directory -ItemType Directory -Force
    $manifest = "@{ ModuleVersion = '$($parts[0])'; GUID = '$Guid'; RootModule = '$Name.psm1'; PrivateData = @{ PSData = @{ Prerelease = '$($parts[1])' } } }"
    [IO.File]::WriteAllText("$directory/$Name.psd1", $manifest)
    [IO.File]::WriteAllText("$directory/$Name.psm1", "throw 'Fixture must never be imported: $Version'")
    $directory
}

function Initialize-PMULocalPackage {
    param(
        [object]$Fixture,
        [string]$Version
    )

    $root = Join-Path $Fixture.Root "package-$Version"
    $modulePath = Initialize-PMUTestPackage $root $Version $Fixture.Guid $Fixture.Name
    $spec = '<?xml version="1.0"?><package><metadata><id>{0}</id><version>{1}</version><authors>PMU fixture</authors><description>Disposable offline fixture</description><tags>PSModule PowerShellGetFormatVersion_2.0</tags><requireLicenseAcceptance>true</requireLicenseAcceptance><licenseUrl>https://example.invalid/fixture-license</licenseUrl></metadata></package>' -f $Fixture.Name, $Version
    [IO.File]::WriteAllText((Join-Path $modulePath "$($Fixture.Name).nuspec"), $spec)
    $package = Join-Path $Fixture.Feed "$($Fixture.Name).$Version.nupkg"
    [IO.Compression.ZipFile]::CreateFromDirectory($modulePath, $package)
}

function Initialize-PMUNativeLocalInstallation {
    param(
        [object]$Fixture,
        [string]$Destination
    )

    Assert-PMUNativeFixtureStore $Fixture.Root $Destination
    Initialize-PMULocalPackage $Fixture '2.0.0-preview1'
    PowerShellGet\Register-PSRepository -Name $Fixture.Repository -SourceLocation $Fixture.Feed -InstallationPolicy Trusted -ErrorAction Stop
    # Bootstrap only, inside the verified disposable home; production never uses this command.
    PowerShellGet\Install-Module -Name $Fixture.Name -RequiredVersion '2.0.0-preview1' -AllowPrerelease -Repository $Fixture.Repository -Scope CurrentUser -AcceptLicense -ErrorAction Stop
    $manifest = Join-Path $Destination "$($Fixture.Name)/2.0.0/$($Fixture.Name).psd1"
    $Fixture.Module = Get-Module -ListAvailable $manifest
}

function ConvertTo-PMUTestContext {
    param([object]$Module, [object]$Identity, [object]$Observation)
    [pscustomobject]@{
        Module = $Module; Reference = $Identity; Active = Get-ActiveModuleIdentity $Module
        Policy = @{ Scope = 'CurrentUser'; Channel = 'IncludePrerelease'; VersionRange = $null }
        Provider = [pscustomobject]@{ Name = 'Microsoft.PowerShell.PSResourceGet'; Version = [version]'1.2.0' }
        Source = [pscustomobject]@{ Name = 'OwnedFeed'; Uri = 'https://example.invalid/feed'; ApiVersion = 'V3'; Trusted = $true }
        Observed = @($Observation); Installed = $Observation; InstalledTree = @(Get-FileTreeInventory (Split-Path -Parent $Identity.ManifestPath))
        Target = [pscustomobject]@{ Version = (ConvertTo-CompleteModuleVersion '2.0.0-preview.2'); RequiresLicenseAcceptance = $false; Dependencies = @() }
    }
}

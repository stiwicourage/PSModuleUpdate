function Initialize-PMUTestOperation {
    param([string]$Root)
    $Root = Join-Path $Root ([guid]::NewGuid().ToString('N'))
    Mock Resolve-PMUDataRoot { Join-Path $TestDrive 'data' }
    $installed = Initialize-PMUTestPackage (Join-Path $Root 'Modules') '2.0.0-preview.1'
    $module = Get-Module -ListAvailable "$installed/FixtureModule.psd1"
    $identity = Get-ManifestIdentity "$installed/FixtureModule.psd1"
    $observation = [pscustomobject]@{
        FullVersion = $identity.Version.FullVersion
        NumericVersion = '2.0.0'
        Prerelease = 'preview.1'
        Scope = 'CurrentUser'
        Root = Join-Path $Root 'Modules'
        ManifestPath = $identity.ManifestPath
        Guid = $identity.Guid
    }
    $context = ConvertTo-PMUTestContext $module $identity $observation
    $plan = Register-UpdatePlan (ConvertTo-UpdatePlan $context) $context $false
    $operation = ConvertTo-InstallationOperation $plan (Test-UpdatePlan $plan) @{
        AcceptLicense = $true
        TrustRepository = $true
    } $null
    $operation | Add-Member TestContext $context
    $operation
}

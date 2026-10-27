# Only the unique entry owned by this session may be removed. No Force, Set or Reset.
function Initialize-QualificationOption {
    param([hashtable]$Options)
    if (-not $IsMacOS) {
        throw 'This bounded qualification harness currently requires macOS.'
    }
    $initializers = @{
        Gallery = ${function:Initialize-QualificationGalleryOption}
        NuGet = ${function:Initialize-QualificationNuGetOption}
        Private = ${function:Assert-QualificationPrivateOption}
    }
    if (-not $initializers.ContainsKey($Options.Scenario)) {
        throw 'Unknown qualification scenario.'
    }
    & $initializers[$Options.Scenario] $Options
    Assert-QualificationEndpoint $Options.RepositoryUri
}

function Initialize-QualificationGalleryOption {
    param([hashtable]$Options)
    $Options.RepositoryUri = 'https://www.powershellgallery.com/api/v2'
    $Options.SeedName = 'ThreadJob'
    $Options.SeedVersion = '2.0.3'
    $Options.TargetVersion = '2.1.0'
    $Options.DiscoveryName = 'Pester'
}

function Initialize-QualificationNuGetOption {
    param([hashtable]$Options)
    $Options.RepositoryUri = 'https://api.nuget.org/v3/index.json'
    $Options.SeedName = 'NuGet.Versioning'
    $Options.SeedVersion = '6.12.0'
    $Options.TargetVersion = '6.12.1'
    $Options.DiscoveryName = 'Newtonsoft.Json'
}

function Assert-QualificationPrivateOption {
    param([hashtable]$Options)
    foreach ($key in @('RepositoryUri', 'SeedName', 'SeedVersion', 'TargetVersion')) {
        if (-not $Options[$key]) {
            throw 'Private qualification requires caller-supplied endpoint and pinned module versions.'
        }
    }
    if ($Options.SeedName -notmatch '^[A-Za-z0-9_.-]+$') {
        throw 'Unsafe qualification fixture name.'
    }
    Assert-QualificationFixtureVersion $Options.SeedVersion
    Assert-QualificationFixtureVersion $Options.TargetVersion
    $Options.DiscoveryName = $Options.SeedName
}

function Assert-QualificationFixtureVersion {
    param([string]$Version)
    if ($Version -notmatch '^\d+\.\d+\.\d+([.-][A-Za-z0-9.-]+)?$') {
        throw 'Unsafe qualification fixture version.'
    }
}

function Initialize-QualificationRegistration {
    param([object]$Session)
    $Session.Evidence.Phase = 'Registration'
    $Session.RepositoryName = "PMUQualification-$([guid]::NewGuid().ToString('N'))"
    $Session.Evidence.OwnedRegistrationName = $Session.RepositoryName
    $apiVersion = 'V3'
    if ($Session.Options.Scenario -eq 'Gallery') {
        $apiVersion = 'V2'
    }
    $Session.RegistrationOwned = $true
    Microsoft.PowerShell.PSResourceGet\Register-PSResourceRepository -Name $Session.RepositoryName -Uri $Session.Options.RepositoryUri -ApiVersion $apiVersion -ErrorAction Stop
    $Session.Evidence.RepositorySelection = 'Unique harness-owned consumer registration; URI must resolve to this registration.'
}

function Invoke-QualificationRegistrationCleanup {
    param([object]$Session)
    if (-not $Session.RegistrationOwned) {
        return
    }
    $repository = Microsoft.PowerShell.PSResourceGet\Get-PSResourceRepository -Name $Session.RepositoryName -ErrorAction Stop
    if ("$($repository.Uri)" -cne $Session.Options.RepositoryUri) {
        throw 'Owned registration endpoint changed; manual cleanup required.'
    }
    Microsoft.PowerShell.PSResourceGet\Unregister-PSResourceRepository -Name $Session.RepositoryName -ErrorAction Stop
    $Session.RegistrationOwned = $false
}

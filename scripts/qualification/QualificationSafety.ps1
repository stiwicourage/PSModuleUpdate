# Harness-only safety boundary. No provider or installation operations belong here.
function Assert-QualificationAuthorization {
    param([bool]$EnableLive, [bool]$ProviderStoreApproved)
    if (-not $EnableLive) { throw 'Live qualification requires explicit opt-in.' }
    if (-not $ProviderStoreApproved) { throw 'Shared provider store access requires coordinator approval.' }
}

function Assert-QualificationEndpoint {
    param([uri]$Uri)
    if (-not $Uri.IsAbsoluteUri) { throw 'Unsafe qualification endpoint.' }
    if ($Uri.Scheme -ne 'https') { throw 'Unsafe qualification endpoint.' }
    foreach ($unsafePart in @($Uri.UserInfo, $Uri.Query, $Uri.Fragment)) {
        if ($unsafePart) { throw 'Unsafe qualification endpoint.' }
    }
}

function Assert-QualificationDestination {
    param([string]$Destination, [string]$HomeRoot)
    $homePath = [IO.Path]::GetFullPath($HomeRoot).TrimEnd([IO.Path]::DirectorySeparatorChar)
    $targetPath = [IO.Path]::GetFullPath($Destination)
    if (-not $targetPath.StartsWith("$homePath/", [StringComparison]::Ordinal)) {
        throw 'Provider destination is outside the disposable home.'
    }
    Assert-QualificationUnlinkedPath $targetPath
}

function Assert-QualificationUnlinkedPath {
    param([string]$Path)
    $current = $Path
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Qualification path contains a link.' }
        }
        $current = Split-Path -Parent $current
    }
}

function Assert-QualificationRepositoryState {
    param([string[]]$Before, [string[]]$After)
    $beforeText = ($Before | Sort-Object) -join "`n"
    $afterText = ($After | Sort-Object) -join "`n"
    if ($beforeText -cne $afterText) {
        throw 'Existing provider registration state changed or cleanup failed.'
    }
}

function Assert-QualificationPublicObject {
    param([object]$Value)
    if ($null -eq $Value) { return }
    Assert-QualificationValueType $Value
    if ($Value -is [uri]) { Assert-QualificationEndpoint $Value; return }
    if ($Value -is [string]) { return }
    if ($Value.GetType().IsValueType) { return }
    Assert-QualificationComposite $Value
}

function Assert-QualificationValueType {
    param([object]$Value)
    if ($Value -is [pscredential]) { throw 'Public result contains a credential.' }
    if ($Value -is [securestring]) { throw 'Public result contains a credential.' }
}

function Assert-QualificationComposite {
    param([object]$Value)
    if ($Value -is [System.Collections.IDictionary]) { Assert-QualificationDictionary $Value; return }
    if ($Value -is [System.Collections.IEnumerable]) { Assert-QualificationSequence $Value; return }
    foreach ($property in $Value.PSObject.Properties) { Assert-QualificationPublicField $property.Name $property.Value }
}

function Assert-QualificationDictionary {
    param([System.Collections.IDictionary]$Value)
    foreach ($key in $Value.Keys) { Assert-QualificationPublicField $key $Value[$key] }
}

function Assert-QualificationSequence {
    param([System.Collections.IEnumerable]$Value)
    foreach ($entry in $Value) { Assert-QualificationPublicObject $entry }
}

function Assert-QualificationPublicField {
    param([string]$Name, [object]$Value)
    if ($Name -match '(?i)credential|password|token|secret|authorization') { throw 'Public result contains a credential field.' }
    if ($Name -match 'Uri$' -and $Value) { Assert-QualificationEndpoint ([uri]$Value) }
    Assert-QualificationPublicObject $Value
}

function Assert-QualificationBuild {
    param([string]$ModuleScript, [string]$SourceRoot)
    $builtContent = [IO.File]::ReadAllText($ModuleScript).Replace("`r`n", "`n")
    foreach ($sourceFile in Get-ChildItem $SourceRoot -Filter '*.ps1' -File -Recurse) {
        $sourceContent = [IO.File]::ReadAllText($sourceFile.FullName).Replace("`r`n", "`n").Trim()
        if (-not $builtContent.Contains($sourceContent, [StringComparison]::Ordinal)) {
            throw 'Built module is stale relative to current source.'
        }

    }
}

function Assert-QualificationModuleHash {
    param([string]$ModuleScript, [string]$ApprovedHash)
    if ($ApprovedHash -notmatch '^[A-Fa-f0-9]{64}$') { throw 'Invalid approved build identity.' }
    if ((Get-FileHash -LiteralPath $ModuleScript -Algorithm SHA256).Hash -ine $ApprovedHash) {
        throw 'The module does not match the explicitly approved build.'
    }
}

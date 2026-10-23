function New-CiDependencyRoot {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$Path)

    if (Test-Path -LiteralPath $Path) { throw "Dependency root already exists: '$Path'." }
    if ((Split-Path -Leaf $Path) -notlike 'pmu-ci-modules-*') { throw 'Dependency roots must use the pmu-ci-modules- prefix.' }
    if (-not $PSCmdlet.ShouldProcess($Path, 'Create disposable CI dependency root')) { return }
    $directory = New-Item -ItemType Directory -Path $Path -ErrorAction Stop
    $owner = @{ Path = $directory.FullName; Token = [guid]::NewGuid().ToString('N') }
    $owner | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $owner.Path '.pmu-dependencies.json')
    return $owner
}

function Get-CiDependencyOwner {
    param([Parameter(Mandatory)][string]$Path)

    $directory = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($directory.LinkType) { throw 'A dependency root cannot be a filesystem link.' }
    $owner = Get-Content -LiteralPath (Join-Path $Path '.pmu-dependencies.json') -Raw -ErrorAction Stop | ConvertFrom-Json -AsHashtable
    if ($owner.Path -ne $directory.FullName -or $owner.Token -notmatch '^[a-f0-9]{32}$') { throw 'Invalid dependency ownership record.' }
    if ($directory.Name -notlike 'pmu-ci-modules-*') { throw 'Invalid dependency root name.' }
    return $owner
}

function Remove-CiDependencyRoot {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][hashtable]$Owner)

    $actual = Get-CiDependencyOwner -Path $Owner.Path
    if ($actual.Token -cne $Owner.Token) { throw 'Dependency ownership changed; refusing cleanup.' }
    if (-not $PSCmdlet.ShouldProcess($Owner.Path, 'Remove owned disposable CI dependencies')) { return }
    Remove-Item -LiteralPath $Owner.Path -Recurse -Force -ErrorAction Stop
}

function Get-CiIsolatedModulePath {
    param([Parameter(Mandatory)][string]$ModuleRoot)

    $null = Get-CiDependencyOwner -Path $ModuleRoot
    return $ModuleRoot + [IO.Path]::PathSeparator + (Join-Path $PSHOME 'Modules')
}

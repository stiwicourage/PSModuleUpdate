[CmdletBinding()]
param(
    [string]$LanePath = (Join-Path $PSScriptRoot 'CiLanes.json')
)

function Assert-CiLaneDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Lane
    )

    $seen = @{}
    foreach ($entry in $Lane) {
        foreach ($field in @('id', 'name', 'runner', 'os', 'architecture', 'runtimeIdentifier', 'powershell')) {
            if (-not $entry.$field) {
                throw "Lane '$( $entry.id )' is missing required field '$field'."
            }
        }
        if ($entry.runner -match 'latest') {
            throw "Lane '$( $entry.id )' uses the moving runner label '$( $entry.runner )'. Pin an explicit image label."
        }
        if ($seen.ContainsKey($entry.id)) {
            throw "Lane definition contains a duplicate lane id '$( $entry.id )'."
        }
        $seen[$entry.id] = $true
    }
}

function Get-CiPlatformMatrix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$LanePath
    )

    $lane = @((Get-Content -LiteralPath $LanePath -Raw | ConvertFrom-Json).lanes)
    Assert-CiLaneDefinition -Lane $lane

    return @{include = $lane } | ConvertTo-Json -Depth 4 -Compress
}

if ($MyInvocation.InvocationName -ne '.') {
    $matrix = Get-CiPlatformMatrix -LanePath $LanePath
    if ($env:GITHUB_OUTPUT) {
        Add-Content -LiteralPath $env:GITHUB_OUTPUT -Value "matrix=$matrix"
    } else {
        Write-Output $matrix
    }
}

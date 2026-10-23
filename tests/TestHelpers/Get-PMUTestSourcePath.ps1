function Get-PMUTestSourcePath {
    param([string]$Caller)
    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $catalog = @{}
    Get-ChildItem "$root/src", $PSScriptRoot -Filter '*.ps1' -Recurse | ForEach-Object { $catalog[$_.BaseName] = $_.FullName }
    $pending = [Collections.Generic.Queue[string]]::new([string[]]@(Get-PMUTestCommandReference $Caller $catalog))
    $visited = [Collections.Generic.HashSet[string]]::new()
    while ($pending.Count) {
        $path = $pending.Dequeue()
        if (-not $visited.Add($path)) { continue }
        foreach ($dependency in Get-PMUTestCommandReference $path $catalog) { $pending.Enqueue($dependency) }
        $path
    }
}

function Get-PMUTestCommandReference {
    param(
        [string]$Path,
        [hashtable]$Catalog
    )

    $ast = [Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
    $references = $ast.FindAll({
            param($node)
            $node -is [Management.Automation.Language.CommandAst] -or $node -is [Management.Automation.Language.StringConstantExpressionAst]
        }, $true)
    foreach ($reference in $references) {
        if ($reference -is [Management.Automation.Language.CommandAst]) {
            $name = $reference.GetCommandName()
        } else {
            $name = $reference.Value
        }
        if ($Catalog.ContainsKey([string]$name)) {
            $Catalog[$name]
        }
    }
}

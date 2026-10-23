function Get-PlanTargetField {
    param([object]$Context)
    $target = $Context.Target.Version
    [ordered]@{
        Channel = $Context.Policy.Channel
        VersionRange = $Context.Policy.VersionRange
        TargetVersion = $target.FullVersion
        TargetNumericVersion = $target.NumericVersion
        TargetPrerelease = $target.Prerelease
        TargetIsPrerelease = $target.IsPrerelease
        TargetInstalledPath = Join-Path $Context.Installed.Root "$($Context.Reference.Name)/$($target.NumericVersion)"
    }
}

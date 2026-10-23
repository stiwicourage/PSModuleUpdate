function Assert-ExactTarget {
    param([object]$Operation)
    $plan = $Operation.Plan
    Assert-RepositoryBinding $plan $Operation.RepositoryName
    $request = @{ Name = $plan.ModuleName; Repository = Get-OperationRepositoryName $Operation; Version = "[$($plan.TargetVersion)]"; Prerelease = $plan.TargetIsPrerelease }
    $resources = @(Find-ProviderResource $request $Operation.Credential | ForEach-Object { ConvertTo-ProviderRelease $_ })
    $exact = @($resources | Where-Object { $_.Name -ceq $plan.ModuleName -and $_.Version.FullVersion -ceq $plan.TargetVersion })
    if ($exact.Count -ne 1) { Write-PMUError 'PMU.PackageNotFound' 'The exact approved target is no longer uniquely available.' }
    $Operation.RequiresLicenseAcceptance = $exact[0].RequiresLicenseAcceptance
}

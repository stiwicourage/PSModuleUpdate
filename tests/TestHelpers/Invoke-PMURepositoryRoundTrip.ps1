function Invoke-PMURepositoryRoundTrip {
    param(
        [object]$Fixture,
        [string]$RepositoryChoice,
        [string]$Selector,
        [pscredential]$Credential
    )

    $repository = $Fixture.Repositories[$RepositoryChoice]
    $parameters = @{
        Module = $Fixture.Module
        Policy = @{ Channel = 'IncludePrerelease' }
    }
    if ($Selector -eq 'Uri') {
        $parameters.RepositoryUri = $repository.Uri
    } else {
        $parameters.Repository = $repository.Name
    }
    $authentication = @{}
    if ($Credential) {
        $authentication.Credential = $Credential
    }
    $plan = Get-PSModuleUpdate @parameters @authentication
    $result = $plan | Install-PSModuleUpdate @authentication -TrustRepository -Confirm:$false
    [pscustomobject]@{
        Plan = $plan
        Result = $result
    }
}

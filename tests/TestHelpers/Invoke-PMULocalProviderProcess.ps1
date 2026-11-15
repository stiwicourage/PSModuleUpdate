. "$PSScriptRoot/Initialize-PMULocalProviderStart.ps1"
function Invoke-PMULocalProviderProcess {
    param(
        [string]$Root,
        [string]$ModulePath,
        [string]$FixtureScript = "$PSScriptRoot/Invoke-PMULocalProviderFixture.ps1"
    )

    $start = Initialize-PMULocalProviderStart $Root $ModulePath $FixtureScript
    # This fixture performs five sequential native updates, not one process probe.
    Receive-PMUChildProcess ([Diagnostics.Process]::Start($start)) -TimeoutMilliseconds 150000
}

function Get-InstallationProgressHost {
    [pscustomobject]@{
        OutputRedirected = [Console]::IsOutputRedirected
        NonInteractive = [Environment]::GetCommandLineArgs() -contains '-NonInteractive'
    }
}

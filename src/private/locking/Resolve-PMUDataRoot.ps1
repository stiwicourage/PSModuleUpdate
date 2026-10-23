function Resolve-PMUDataRoot {
    param([string]$Scope)
    if ($IsWindows) {
        $folder = 'LocalApplicationData'
        if ($Scope -eq 'AllUsers') { $folder = 'CommonApplicationData' }
        return Assert-SafePath (Join-Path ([Environment]::GetFolderPath($folder)) 'PSModuleUpdate')
    }
    if ($Scope -eq 'CurrentUser') { return Assert-SafePath (Join-Path $HOME '.local/state/PSModuleUpdate') }
    if ($IsMacOS) { return Assert-SafePath '/Library/Application Support/PSModuleUpdate' }
    Assert-SafePath '/var/lib/PSModuleUpdate'
}

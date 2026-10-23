function Resolve-RepositoryTransportRoot {
    $folder = [Environment]::GetFolderPath('LocalApplicationData')
    Assert-SafePath (Join-Path $folder 'PSModuleUpdate/RepositoryTransport')
}

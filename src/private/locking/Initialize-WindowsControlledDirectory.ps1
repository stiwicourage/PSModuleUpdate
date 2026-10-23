function Initialize-WindowsControlledDirectory {
    param([string]$Path)
    $null = [IO.Directory]::CreateDirectory($Path)
    Assert-WindowsDirectoryDescriptor (Get-WindowsDirectoryDescriptor $Path)
}

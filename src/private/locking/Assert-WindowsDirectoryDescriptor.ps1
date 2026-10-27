function Assert-WindowsDirectoryDescriptor {
    param([object]$Descriptor)
    if ($Descriptor.Owner -notin $Descriptor.Trusted) {
        Write-PMUError 'PMU.PermissionDenied' 'The PMU data-directory owner is not trusted.'
    }
    foreach ($rule in $Descriptor.Access) {
        Assert-WindowsAccessRule $rule $Descriptor.Trusted
    }
}

function Get-ManifestModuleVersion {
    param([hashtable]$Data)
    $label = ''
    if ($Data['PrivateData'] -and $Data['PrivateData']['PSData']) { $label = "$($Data['PrivateData']['PSData']['Prerelease'])" }
    $full = "$($Data['ModuleVersion'])"
    if ($label) { $full += "-$label" }
    ConvertTo-CompleteModuleVersion $full
}

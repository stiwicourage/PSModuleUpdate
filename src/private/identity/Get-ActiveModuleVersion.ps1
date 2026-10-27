function Get-ActiveModuleVersion {
    param([System.Management.Automation.PSModuleInfo]$Module)
    $full = "$($Module.Version)"
    $label = ''
    if ($Module.PrivateData -is [System.Collections.IDictionary]) {
        $privateData = $Module.PrivateData
        if ($privateData['PSData']) {
            $label = "$($privateData['PSData']['Prerelease'])"
        }
    }
    if ($label) {
        $full += "-$label"
    }
    ConvertTo-CompleteModuleVersion $full
}

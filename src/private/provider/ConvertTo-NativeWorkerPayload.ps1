function ConvertTo-NativeWorkerPayload {
    param([object]$Context)

    $serialized = [Management.Automation.PSSerializer]::Serialize($Context, 20)
    [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($serialized))
}

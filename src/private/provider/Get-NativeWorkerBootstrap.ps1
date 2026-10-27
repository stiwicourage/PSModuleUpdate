function Get-NativeWorkerBootstrap {
    @'
$ErrorActionPreference = 'Stop'
$encodedContext = [Console]::In.ReadLine()
$contextBytes = [Convert]::FromBase64String($encodedContext)
$serializedContext = [Text.Encoding]::UTF8.GetString($contextBytes)
$context = [Management.Automation.PSSerializer]::Deserialize($serializedContext)
$module = Import-Module -Name $context.ModulePath -PassThru

& $module {
    param($workerContext)

    Invoke-NativeWorker -Context $workerContext
} $context
'@
}

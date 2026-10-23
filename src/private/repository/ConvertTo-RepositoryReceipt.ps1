function ConvertTo-RepositoryReceipt {
    param([object]$Source)
    $operationId = [guid]::NewGuid().ToString('N')
    [pscustomobject]@{
        SchemaVersion = 1; OperationId = $operationId; RegistrationName = "pmu-uri-$operationId"
        OwnerPid = $PID; OwnerStartedUtcTicks = Get-RepositoryProcessStart $PID
        UriHash = Get-RepositoryUriHash ([uri]$Source.Uri)
        ApiVersion = "$($Source.ApiVersion)"; Trusted = $false; Priority = 50
    }
}

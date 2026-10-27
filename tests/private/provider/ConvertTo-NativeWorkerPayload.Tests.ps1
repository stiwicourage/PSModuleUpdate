BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'ConvertTo-NativeWorkerPayload' -Tag 'PMUProviderContracts' {
    It 'preserves nested values and Unicode through the worker wire protocol' {
        $marker = "quoted ' `" and`nnewline $([char]0x00e6)"
        $context = [pscustomobject]@{
            Operation = [pscustomobject]@{
                Plan = [pscustomobject]@{ Marker = $marker; Optional = $null }
            }
            Values = @(1, 2, 3)
        }

        $payload = ConvertTo-NativeWorkerPayload $context
        $serialized = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload))
        $restored = [Management.Automation.PSSerializer]::Deserialize($serialized)

        $restored.Operation.Plan.Marker | Should -BeExactly $marker
        $restored.Operation.Plan.Optional | Should -BeNullOrEmpty
        $restored.Values | Should -Be @(1, 2, 3)
        $payload | Should -Not -Match '[\r\n]'
    }
}

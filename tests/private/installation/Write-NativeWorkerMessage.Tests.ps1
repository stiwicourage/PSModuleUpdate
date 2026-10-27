BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Write-NativeWorkerMessage' -Tag 'PMU', 'PMUWorkerContracts' {
    It 'emits one framed JSON line while preserving nested values and special characters' {
        $message = [pscustomobject]@{
            Status = 'Ready'
            Token = [pscustomobject]@{ TransactionId = "quotes ' `" and`nnewline" }
        }
        $writer = [IO.StringWriter]::new()
        $original = [Console]::Out
        try {
            [Console]::SetOut($writer)
            Write-NativeWorkerMessage $message
        } finally {
            [Console]::SetOut($original)
            $writer.Dispose()
        }

        $line = $writer.ToString()
        $line | Should -Match '^PMU_NATIVE:'
        @($line.TrimEnd([char[]]"`r`n") -split '\r?\n').Count | Should -Be 1
        $decoded = $line.Substring('PMU_NATIVE:'.Length) | ConvertFrom-Json
        $decoded.Status | Should -BeExactly 'Ready'
        $decoded.Token.TransactionId | Should -BeExactly $message.Token.TransactionId
    }
}

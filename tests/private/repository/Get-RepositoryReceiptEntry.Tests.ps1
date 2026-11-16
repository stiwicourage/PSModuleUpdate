BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-RepositoryReceiptEntry' -Tag 'PMUUriBridge' {
    Context 'Read-only receipt catalog' {
        It 'does not create a missing registry coordination directory' {
            $root = Join-Path $TestDrive 'absent'
            @(Get-RepositoryReceiptEntry $root).Count | Should -Be 0
            Test-Path $root | Should -BeFalse
        }
        It 'reads durable JSON receipts but leaves unrelated files and directories alone' {
            $receipt = ConvertTo-RepositoryReceipt (Initialize-PMUUriFixture $TestDrive).Source
            Initialize-ControlledDirectory $TestDrive
            $path = Write-RepositoryReceipt $receipt $TestDrive
            $unrelated = Join-Path $TestDrive 'notes.txt'
            [IO.File]::WriteAllText($unrelated, 'retain')
            $directory = Join-Path $TestDrive 'directory.json'
            $null = New-Item -ItemType Directory -Path $directory
            $entries = @(Get-RepositoryReceiptEntry $TestDrive)
            $entries.Count | Should -Be 1
            $entries[0].Path | Should -BeExactly $path
            $entries[0].Receipt.OperationId | Should -BeExactly $receipt.OperationId
            Get-Content -LiteralPath $unrelated -Raw | Should -BeExactly 'retain'
            Test-Path -LiteralPath $directory -PathType Container | Should -BeTrue
        }
        It 'fails closed when an existing receipt catalog contains corrupt JSON' {
            Initialize-ControlledDirectory $TestDrive
            $path = Join-Path $TestDrive "$([guid]::NewGuid().ToString('N')).json"
            [IO.File]::WriteAllText($path, '{"SchemaVersion":')
            { Get-RepositoryReceiptEntry $TestDrive } | Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired'
            Test-Path -LiteralPath $path | Should -BeTrue
        }
    }
}

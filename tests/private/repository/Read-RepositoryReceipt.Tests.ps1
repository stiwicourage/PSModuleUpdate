BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Read-RepositoryReceipt' -Tag 'PMUUriBridge' {
    Context 'Untrusted receipt files' {
        It 'rejects truncated JSON without returning unsafe provider diagnostics' {
            $path = Join-Path $TestDrive "$([guid]::NewGuid().ToString('N')).json"
            [IO.File]::WriteAllText($path, '{"SchemaVersion":')
            { Read-RepositoryReceipt $path $TestDrive } | Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired*'
        }
        It 'rejects a symlink receipt before reading its external contents' -Skip:$IsWindows {
            $external = Join-Path $TestDrive 'external'
            [IO.File]::WriteAllText($external, 'untrusted external contents')
            $path = Join-Path $TestDrive "$([guid]::NewGuid().ToString('N')).json"
            $null = New-Item -ItemType SymbolicLink -Path $path -Target $external
            { Read-RepositoryReceipt $path $TestDrive } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation*'
            Get-Content $external -Raw | Should -Be 'untrusted external contents'
        }
    }
    It 'rejects a receipt outside the receipt root' {
        $other = Join-Path $TestDrive 'other'
        $null = New-Item -ItemType Directory -Path $other
        $path = Join-Path $other "$([guid]::NewGuid().ToString('N')).json"
        [IO.File]::WriteAllText($path, '{}')
        { Read-RepositoryReceipt $path $TestDrive } | Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired*'
    }
    It 'rejects an oversized receipt before parsing it' {
        $path = Join-Path $TestDrive "$([guid]::NewGuid().ToString('N')).json"
        [IO.File]::WriteAllText($path, ('x' * 9000))
        { Read-RepositoryReceipt $path $TestDrive } | Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired*'
    }
    It 'rejects a valid receipt stored under another operation nonce without rewriting either identity' {
        $receipt = ConvertTo-RepositoryReceipt (Initialize-PMUUriFixture $TestDrive).Source
        $path = Write-RepositoryReceipt $receipt $TestDrive
        $renamed = Join-Path $TestDrive "$([guid]::NewGuid().ToString('N')).json"
        Move-Item -LiteralPath $path -Destination $renamed
        $hash = (Get-FileHash -LiteralPath $renamed).Hash
        { Read-RepositoryReceipt $renamed $TestDrive } |
        Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired' -ExpectedMessage 'Repository receipt name does not match its operation.'
        (Get-FileHash -LiteralPath $renamed).Hash | Should -BeExactly $hash
        Test-Path -LiteralPath $path | Should -BeFalse
    }
}

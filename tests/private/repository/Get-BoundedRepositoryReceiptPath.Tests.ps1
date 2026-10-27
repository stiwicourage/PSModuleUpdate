BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Get-BoundedRepositoryReceiptPath' -Tag 'PMUUriBridge' {
    BeforeEach {
        Mock Assert-SafePath { $Path }
    }

    It 'accepts a receipt at the size boundary and returns the validated path' {
        $path = Join-Path $TestDrive 'receipt.json'
        [IO.File]::WriteAllText($path, ('x' * 8192))

        Get-BoundedRepositoryReceiptPath $path $TestDrive | Should -BeExactly $path
    }

    It 'rejects a receipt exceeding the size boundary' {
        $path = Join-Path $TestDrive 'oversized.json'
        [IO.File]::WriteAllText($path, ('x' * 8193))

        { Get-BoundedRepositoryReceiptPath $path $TestDrive } |
            Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired'
    }

    It 'rejects an out-of-root path before accessing its file metadata' {
        $path = Join-Path (Join-Path $TestDrive 'other') 'receipt.json'
        Mock Get-Item { throw 'metadata must not be read' }

        { Get-BoundedRepositoryReceiptPath $path $TestDrive } |
            Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired'

        Should -Invoke Get-Item -Times 0 -Exactly
    }
}

BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Get-RepositoryReceiptStreamOption' -Tag 'PMUUriBridge' {
    It 'selects exclusive create-only writing with platform-appropriate creation permissions' {
        $options = Get-RepositoryReceiptStreamOption

        $options.Mode | Should -Be ([IO.FileMode]::CreateNew)
        $options.Access | Should -Be ([IO.FileAccess]::Write)
        $options.Share | Should -Be ([IO.FileShare]::None)
        if ($IsWindows) {
            $options.UnixCreateMode | Should -BeNullOrEmpty
        } else {
            $options.UnixCreateMode |
                Should -Be ([IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite)
        }
    }
}

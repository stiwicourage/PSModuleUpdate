BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-RepositoryReceiptEntry' -Tag 'PMUUriBridge' {
    Context 'Read-only receipt catalog' {
        It 'does not create a missing registry coordination directory' {
            $root = Join-Path $TestDrive 'absent'
            @(Get-RepositoryReceiptEntry $root).Count | Should -Be 0
            Test-Path $root | Should -BeFalse
        }
    }
}

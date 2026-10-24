BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Test-RepositoryReceiptOwnerAlive' -Tag 'PMUUriBridge' {
    Context 'Living and recycled process identities' {
        It 'requires both PID and original process start time' {
            $receipt = ConvertTo-RepositoryReceipt (Initialize-PMUUriFixture $TestDrive).Source
            Test-RepositoryReceiptOwnerAlive $receipt | Should -BeTrue
            $receipt.OwnerStartedUtcTicks = "$([long]$receipt.OwnerStartedUtcTicks - 1)"
            Test-RepositoryReceiptOwnerAlive $receipt | Should -BeFalse
        }
    }
    It 'rejects a receipt process id outside the operating-system range' {
        $receipt = [pscustomobject]@{ OwnerPid = '99999999999'; OwnerStartedUtcTicks = '1' }
        { Test-RepositoryReceiptOwnerAlive $receipt } | Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired'
    }
}

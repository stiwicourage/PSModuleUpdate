BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Invoke-ScopedInstallation' -Tag 'PMU' {
    Context 'Scope lock lifetime' {
        It 'releases an acquired handle even when the locked workflow fails' {
            $script:lease = [IO.MemoryStream]::new()
            Mock Initialize-ControlledDirectory {}
            Mock Enter-InstallationLock { $script:lease }
            Mock Invoke-LockedInstallation { throw [InvalidOperationException]::new('fixture failure') }
            $operation = @{ DataRoot = $TestDrive; WorkRoot = $TestDrive; LockPath = "$TestDrive/lock" }
            { Invoke-ScopedInstallation $operation } | Should -Throw '*fixture failure*'
            $lease.CanRead | Should -BeFalse
        }
    }
}

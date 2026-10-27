BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/tests/TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Enter-InstallationLock' -Tag 'PMU' {
    It 'uses an exclusive handle with a bounded timeout, not file existence' {
        $path = Join-Path $TestDrive 'owned.lock'
        $first = Enter-InstallationLock $path 100
        try {
            { Enter-InstallationLock $path 100 } | Should -Throw -ErrorId 'PMU.LockTimeout'
        } finally {
            $first.Dispose()
        }
        $second = Enter-InstallationLock $path 100
        $second.Dispose()
        Test-Path $path | Should -BeTrue
    }
}

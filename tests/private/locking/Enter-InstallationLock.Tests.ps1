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
    It 'reports permission denial for a directory lock path without deleting its existing contents' {
        $path = Join-Path $TestDrive 'directory-lock'
        $null = New-Item -ItemType Directory -Path $path
        $sentinel = Join-Path $path 'retain.txt'
        [IO.File]::WriteAllText($sentinel, 'preserved lock-path contents')
        { Enter-InstallationLock $path 100 } |
            Should -Throw -ErrorId 'PMU.PermissionDenied' -ExpectedMessage 'Cannot open the scope-specific PMU lock.'
        Get-Content -LiteralPath $sentinel -Raw | Should -BeExactly 'preserved lock-path contents'
    }
}

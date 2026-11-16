BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Initialize-ControlledDirectory' -Tag 'PMU' {
    It 'creates private owned data directories and rejects unsafe writable modes' {
        $path = Join-Path $TestDrive 'private'
        Initialize-ControlledDirectory $path
        Test-Path $path -PathType Container | Should -BeTrue
        if (-not $IsWindows) {
            [IO.File]::SetUnixFileMode($path, [IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite -bor [IO.UnixFileMode]::UserExecute -bor [IO.UnixFileMode]::OtherWrite)
            { Initialize-ControlledDirectory $path } | Should -Throw -ErrorId 'PMU.PermissionDenied'
        }
    }
    It 'routes a validated Windows directory request to its native adapter without Unix creation' {
        # The adapter is isolated; this proves dispatch, not native Windows permissions.
        $originalWindows = $IsWindows
        $expectedPath = Join-Path $TestDrive 'windows-dispatch'
        Mock Initialize-WindowsControlledDirectory {}
        try {
            Set-Variable IsWindows $true -Force
            Initialize-ControlledDirectory $expectedPath
            Should -Invoke Initialize-WindowsControlledDirectory -Times 1 -Exactly -ParameterFilter {
                $Path -ceq $expectedPath
            }
            Test-Path -LiteralPath $expectedPath | Should -BeFalse
        } finally {
            Set-Variable IsWindows $originalWindows -Force
        }
    }
}

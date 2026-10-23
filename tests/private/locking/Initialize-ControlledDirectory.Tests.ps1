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
}

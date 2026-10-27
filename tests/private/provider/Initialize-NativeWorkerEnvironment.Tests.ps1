BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Initialize-NativeWorkerEnvironment' -Tag 'PMU', 'PMUProviderContracts' {
    It 'redirects child temporary storage without changing its installation environment' {
        $root = Join-Path $TestDrive 'owned-environment'
        $start = [Diagnostics.ProcessStartInfo]::new()
        $start.Environment['PMU_TEST_MARKER'] = 'retained'
        $originalHome = $start.Environment['HOME']
        $originalModulePath = $start.Environment['PSModulePath']

        $result = Initialize-NativeWorkerEnvironment $start $root

        $result | Should -BeNullOrEmpty
        $start.WorkingDirectory | Should -BeExactly $root
        $start.Environment['TMPDIR'] | Should -BeExactly (Join-Path $root 'tmp')
        Test-Path -LiteralPath $start.Environment['TMPDIR'] -PathType Container | Should -BeTrue
        $start.Environment['PMU_TEST_MARKER'] | Should -BeExactly 'retained'
        $start.Environment['HOME'] | Should -BeExactly $originalHome
        $start.Environment['PSModulePath'] | Should -BeExactly $originalModulePath
    }

    It 'leaves child environment and working directory untouched when the owned root cannot be created' {
        $start = [Diagnostics.ProcessStartInfo]::new()
        $originalTemp = $start.Environment['TMPDIR']
        $originalDirectory = $start.WorkingDirectory
        Mock Initialize-ControlledDirectory {
            throw [UnauthorizedAccessException]::new('Owned directory unavailable.')
        }
        { Initialize-NativeWorkerEnvironment $start (Join-Path $TestDrive 'denied') } |
            Should -Throw '*Owned directory unavailable*'
        $start.Environment['TMPDIR'] | Should -BeExactly $originalTemp
        $start.WorkingDirectory | Should -BeExactly $originalDirectory
    }
}

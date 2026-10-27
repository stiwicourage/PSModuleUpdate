BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Get-NativeWorkerDirectoryMap' -Tag 'PMU', 'PMUProviderContracts' {
    It 'maps only owned storage variables, leaving HOME and module discovery inherited' {
        $paths = Get-NativeWorkerDirectoryMap

        $paths.Count | Should -Be 7
        $paths.XDG_CONFIG_HOME | Should -BeExactly 'config'
        $paths.XDG_CACHE_HOME | Should -BeExactly 'cache'
        $paths.LOCALAPPDATA | Should -BeExactly 'local'
        $paths.ProgramData | Should -BeExactly 'program'
        $paths.TMPDIR | Should -BeExactly 'tmp'
        $paths.TEMP | Should -BeExactly 'tmp'
        $paths.TMP | Should -BeExactly 'tmp'
        $paths.ContainsKey('HOME') | Should -BeFalse
        $paths.ContainsKey('PSModulePath') | Should -BeFalse
    }

    It 'returns an independent mapping for each worker' {
        $paths = Get-NativeWorkerDirectoryMap
        $paths['TMP'] = 'changed-by-caller'

        (Get-NativeWorkerDirectoryMap).TMP | Should -BeExactly 'tmp'
    }
}

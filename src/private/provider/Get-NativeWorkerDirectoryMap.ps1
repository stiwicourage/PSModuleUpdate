function Get-NativeWorkerDirectoryMap {
    @{
        XDG_CONFIG_HOME = 'config'
        XDG_CACHE_HOME = 'cache'
        LOCALAPPDATA = 'local'
        ProgramData = 'program'
        TMPDIR = 'tmp'
        TEMP = 'tmp'
        TMP = 'tmp'
    }
}

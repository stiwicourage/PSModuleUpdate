BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$projectRoot/src/private/provider/Initialize-NativeWorkerStartInfo.ps1"
    . "$projectRoot/src/private/provider/Initialize-NativeWorkerEnvironment.ps1"
    . "$projectRoot/src/private/provider/Get-NativeWorkerBootstrap.ps1"
    . "$projectRoot/src/private/provider/Get-NativeWorkerDirectoryMap.ps1"
    . "$projectRoot/src/private/locking/Initialize-ControlledDirectory.ps1"
    . "$PSScriptRoot/../../TestHelpers/Receive-PMUChildProcess.ps1"
    . "$PSScriptRoot/../../TestHelpers/Close-PMUChildProcess.ps1"

    $fixtureModule = Join-Path $TestDrive "private worker's fixture.psm1"
    @'
function Invoke-NativeWorker {
    param([object]$Context)

    [Console]::Out.Write($Context.Marker)
}

Export-ModuleMember -Function @()
'@ | Set-Content -LiteralPath $fixtureModule -Encoding utf8
}

Describe 'Initialize-NativeWorkerStartInfo' -Tag 'PMU', 'PMUWorkerBootstrap' {
    BeforeEach {
        Mock Initialize-ControlledDirectory {
            param($Path)

            $null = [IO.Directory]::CreateDirectory($Path)
        }
        $ownedRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $script:context = [pscustomobject]@{
            ModulePath = $fixtureModule
            Marker = 'secret marker: '' " $(); & | < > `' + [char]0x00e5
            Operation = [pscustomobject]@{
                NativeContext = [pscustomobject]@{
                    Root = $ownedRoot
                }
            }
        }
    }

    It 'launches the current runtime noninteractively with redirected streams and no request values in arguments' {
        $start = Initialize-NativeWorkerStartInfo $context

        $start.FileName | Should -BeExactly (Get-Process -Id $PID).Path
        $start.UseShellExecute | Should -BeFalse
        $start.RedirectStandardInput | Should -BeTrue
        $start.RedirectStandardOutput | Should -BeTrue
        $start.RedirectStandardError | Should -BeTrue
        $start.ArgumentList.Count | Should -Be 5
        @($start.ArgumentList)[0..3] | Should -Be @('-NoLogo', '-NoProfile', '-NonInteractive', '-Command')
        $arguments = $start.ArgumentList -join ' '
        $arguments.Contains($context.Marker) | Should -BeFalse
        $arguments.Contains($context.ModulePath) | Should -BeFalse
        $arguments.Contains($ownedRoot) | Should -BeFalse
    }

    It 'assigns owned child environment roots without mutating the parent environment' {
        $relativePaths = @{
            XDG_CONFIG_HOME = 'config'
            XDG_CACHE_HOME = 'cache'
            LOCALAPPDATA = 'local'
            ProgramData = 'program'
            TMPDIR = 'tmp'
            TEMP = 'tmp'
            TMP = 'tmp'
        }
        $parentBefore = [Environment]::GetEnvironmentVariables('Process')

        $start = Initialize-NativeWorkerStartInfo $context

        $start.WorkingDirectory | Should -BeExactly $ownedRoot
        foreach ($key in $relativePaths.Keys) {
            $expectedPath = Join-Path $ownedRoot $relativePaths[$key]
            $start.Environment[$key] | Should -BeExactly $expectedPath
            Test-Path -LiteralPath $expectedPath -PathType Container | Should -BeTrue
            [Environment]::GetEnvironmentVariable($key, 'Process') | Should -BeExactly $parentBefore[$key]
        }
    }

    It 'runs the private fixture worker with the exact special-character marker supplied only through stdin' {
        $start = Initialize-NativeWorkerStartInfo $context
        $serialized = [Management.Automation.PSSerializer]::Serialize($context)
        $payload = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($serialized))
        $child = [Diagnostics.Process]::Start($start)
        try {
            $child.StandardInput.WriteLine($payload)
            $child.StandardInput.Close()
            $result = Receive-PMUChildProcess $child

            $result.ExitCode | Should -Be 0 -Because $result.Error
            $result.Error | Should -BeNullOrEmpty
            $result.Output | Should -BeExactly $context.Marker
        } finally {
            Close-PMUChildProcess $child
        }
    }
}

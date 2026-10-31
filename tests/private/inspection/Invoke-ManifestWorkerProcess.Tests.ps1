BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Invoke-ManifestWorkerProcess' -Tag 'PMU', 'PMUTargetManifest' {
    It 'waits for the child and disposes it on a <Kind> response' -ForEach @(
        @{
            Kind = 'complete'
            Text = 'PMU_NATIVE:{"Phase":"RESULT","Success":true}'
            ErrorId = $null
        }
        @{
            Kind = 'missing'
            Text = ''
            ErrorId = 'PMU.RecoveryRequired'
        }
    ) {
        $script:disposed = $false
        $process = [pscustomobject]@{
            StandardOutput = [IO.StringReader]::new($Text)
        }
        $process | Add-Member ScriptMethod Dispose {
            $script:disposed = $true
        }
        $script:worker = [pscustomobject]@{
            Process = $process
            ExitCode = 0
        }
        Mock Invoke-NativeWorkerStart {
            $script:worker
        }
        Mock Wait-NativeWorkerStop {
        }
        if ($ErrorId) {
            {
                Invoke-ManifestWorkerProcess ([pscustomobject]@{
                    }) ([pscustomobject]@{
                    })
            } | Should -Throw -ErrorId $ErrorId
        } else {
            {
                Invoke-ManifestWorkerProcess ([pscustomobject]@{
                    }) ([pscustomobject]@{
                    })
            } | Should -Not -Throw
        }
        $disposed | Should -BeTrue
        Should -Invoke Wait-NativeWorkerStop -Times 1 -Exactly
    }
}

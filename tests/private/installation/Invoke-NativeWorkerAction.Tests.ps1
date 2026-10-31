# Invoke-NativeWorker.Tests.ps1 also preserves the complete native READY/GO protocol.
BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Invoke-NativeWorkerAction' -Tag 'PMU', 'PMUTargetManifest' {
    It 'stages inspection without requesting installation permission or entering its lease' {
        $script:result = $null
        Mock Initialize-StagedPackage {
            'inventory'
        }
        Mock Write-NativeWorkerMessage {
            $script:result = $Message
        }
        Mock Assert-NativeWorkerGo {
        }
        Mock Invoke-NativeWorkerLease {
        }
        Invoke-NativeWorkerAction ([pscustomobject]@{
                InspectManifest = $true
                Operation = [pscustomobject]@{
                }
            })
        $result.Phase | Should -Be RESULT
        $result.Success | Should -BeTrue
        Should -Invoke Assert-NativeWorkerGo -Times 0
        Should -Invoke Invoke-NativeWorkerLease -Times 0
    }
}

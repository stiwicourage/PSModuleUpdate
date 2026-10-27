BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    . "$PSScriptRoot/../../TestHelpers/Close-PMUChildProcess.ps1"
    $script:originalStartInfo = ${function:Initialize-NativeWorkerStartInfo}

    $fixtureModule = Join-Path $TestDrive "worker's private fixture.psm1"
    @'
function Invoke-NativeWorker {
    param([object]$Context)

    [Console]::Out.Write($Context.Marker)
    [Console]::Error.Write('owned-child-diagnostic')
}

Export-ModuleMember -Function @()
'@ | Set-Content -LiteralPath $fixtureModule -Encoding utf8
}

Describe 'Invoke-NativeWorkerStart' -Tag 'PMU', 'PMUProviderContracts' {
    It 'sends the exact serialized request over stdin and captures the owned child error stream' {
        $context = [pscustomobject]@{
            ModulePath = $fixtureModule
            Marker = "quoted ' `" and`nnewline"
            Operation = [pscustomobject]@{
                NativeContext = [pscustomobject]@{ Root = Join-Path $TestDrive 'owned-worker' }
            }
        }
        $worker = Invoke-NativeWorkerStart $context.Operation $context
        try {
            $worker.Process.StandardInput.Close()
            $worker.Process.WaitForExit(15000) | Should -BeTrue
            $worker.Process.ExitCode | Should -Be 0
            $worker.Process.StandardOutput.ReadToEnd() | Should -BeExactly $context.Marker
            $worker.Errors.GetAwaiter().GetResult() | Should -BeExactly 'owned-child-diagnostic'
        } finally {
            Close-PMUChildProcess $worker.Process
        }
    }

    It 'cleans up the started worker before translating an input-stream failure' {
        $context = [pscustomobject]@{
            ModulePath = $fixtureModule
            Operation = [pscustomobject]@{
                NativeContext = [pscustomobject]@{ Root = Join-Path $TestDrive 'failed-worker' }
            }
        }
        $script:events = [Collections.Generic.List[string]]::new()
        $script:failedWorker = $null
        $script:inputFailure = $null
        Mock Initialize-NativeWorkerStartInfo {
            $info = & $script:originalStartInfo $Context
            $info.RedirectStandardInput = $false
            $info
        }
        Mock Complete-NativeWorkerLease {
            $script:events.Add('cleanup')
            $script:failedWorker = $Worker
        }
        Mock Write-ProviderError {
            $script:events.Add('translate')
            $script:inputFailure = $Failure
        }

        try {
            @(Invoke-NativeWorkerStart $context.Operation $context).Count | Should -Be 0
            $events | Should -Be @('cleanup', 'translate')
            $inputFailure | Should -BeOfType ([Management.Automation.ErrorRecord])
            $inputFailure.FullyQualifiedErrorId | Should -BeExactly 'PropertyNotFound'
            Should -Invoke Complete-NativeWorkerLease -Times 1 -Exactly -ParameterFilter {
                [object]::ReferenceEquals($Operation, $context.Operation)
            }
            Should -Invoke Write-ProviderError -Times 1 -Exactly -ParameterFilter {
                [object]::ReferenceEquals($Failure, $script:inputFailure) -and
                $DefaultId -ceq 'PMU.InstallationFailed'
            }
        } finally {
            if ($null -ne $failedWorker) {
                Close-PMUChildProcess $failedWorker.Process
            }
        }
    }
}

BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $root 'scripts/build/ci/Assert-CiGate.ps1')
    . (Join-Path $PSScriptRoot 'CiGate.TestSupport.ps1')

    $lane = @('lane-a', 'lane-b')
    $sha = 'f00dfeed'

    function Write-LaneManifest {
        param(
            [string]$Directory,
            [string]$LaneId,
            [string]$Status = 'passed',
            [string]$CommitSha = $sha
        )

        Write-CiGateTestManifest -Directory $Directory -LaneId $LaneId -Status $Status -CommitSha $CommitSha
    }

    function Build-ManifestDirectory {
        param(
            [string]$Name,
            [hashtable]$Status = @{}
        )

        $directory = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        foreach ($id in $lane) {
            $laneStatus = Get-LaneManifestStatus -LaneId $id -Status $Status
            Write-LaneManifest -Directory $directory -LaneId $id -Status $laneStatus
        }
        $directory
    }

    function Get-LaneManifestStatus {
        param([string]$LaneId, [hashtable]$Status)

        if ($Status.ContainsKey($LaneId)) {
            return $Status[$LaneId]
        }
        return 'passed'
    }

    $script:allSuccess = @{
        plan = 'success'
        quality = 'success'
        platform = 'success'
    }
    $script:gateContext = @{
        runId = 'test-run'
        runAttempt = '1'
        lanes = @($lane | ForEach-Object { Get-CiGateTestConfiguration $_ })
    }

    function Invoke-TestGate {
        param(
            [hashtable]$JobResult,
            [string[]]$ExpectedLaneId,
            [string]$ManifestDirectory,
            [string]$CommitSha
        )

        $context = $script:gateContext.Clone()
        $context.commitSha = $CommitSha
        Test-CiGateResult -JobResult $JobResult -ExpectedLaneId $ExpectedLaneId -ManifestDirectory $ManifestDirectory -RunContext $context
    }
}

Describe 'Test-CiGateResult' -Tag 'BuildTooling' {
    Context 'Foreign Windows native provenance' -Tag 'CiNativePortability' {
        BeforeAll {
            function Write-WindowsLaneManifest {
                param([string]$Directory)

                $folder = Join-Path $Directory 'pmu-ci-lane-test-run-1-lane-a'
                $path = Join-Path $folder 'lane-manifest.json'
                $manifest = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -AsHashtable
                Initialize-WindowsLaneConfiguration -Manifest $manifest
                $runtime = Get-CiGateTestRuntime -Identity $manifest.identity
                Initialize-WindowsLaneRuntime -Record $runtime
                $manifest.environment = $runtime.Environment
                $manifest.provisioning.runtime = $runtime
                $manifest.phases = @('build', 'unit', 'integration' | ForEach-Object { Write-CiGateTestPhase -Directory $folder -Name $_ -Record $runtime })
                $manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $path
                return $manifest.configuration
            }

            function Initialize-WindowsLaneConfiguration {
                param([hashtable]$Manifest)

                $Manifest.configuration.runner = 'windows-2025'
                $Manifest.configuration.os = 'Windows'
                $Manifest.configuration.runtimeIdentifier = 'win-x64'
                $Manifest.selectedRuntime.OperatingSystem = 'Windows'
                $Manifest.selectedRuntime.Executable = 'C:\owned-runtime\pwsh.exe'
                $Manifest.provisioning.runtimeIdentifier = 'win-x64'
                $Manifest.provisioning.executable = $Manifest.selectedRuntime.Executable
                $Manifest.provisioning.directory = 'C:\owned-runtime'
                $Manifest.provisioning.nativeProvider.manifestPath = 'C:\owned-runtime\Modules\PowerShellGet\PowerShellGet.psd1'
            }

            function Initialize-WindowsLaneRuntime {
                param([hashtable]$Record)

                $Record.Executable = 'C:\owned-runtime\pwsh.exe'
                $Record.Environment.OperatingSystem = 'Windows'
                $Record.Environment.RunnerOs = 'Windows'
                $Record.Environment.ImageOs = 'win25'
            }

            function Invoke-WindowsTestGate {
                param([string]$Directory, [hashtable]$Configuration)

                $context = $script:gateContext.Clone()
                $context.commitSha = $sha
                $context.lanes = @($Configuration, (Get-CiGateTestConfiguration lane-b))
                Test-CiGateResult -JobResult $script:allSuccess -ExpectedLaneId $lane -ManifestDirectory $Directory -RunContext $context
            }
        }

        It 'accepts a Windows lane flat native manifest from a non-Windows aggregate host' {
            $directory = Build-ManifestDirectory -Name 'windows-flat'
            $configuration = Write-WindowsLaneManifest -Directory $directory
            @(Invoke-WindowsTestGate -Directory $directory -Configuration $configuration).Count | Should -Be 0
        }

        It 'rejects a Windows lane native manifest with <Name> from a non-Windows aggregate host' -ForEach @(
            @{ Name = 'outside-root path'; ManifestPath = 'C:\shared\PowerShellGet.psd1' }
            @{ Name = 'versioned path'; ManifestPath = 'C:\owned-runtime\Modules\PowerShellGet\2.2.5\PowerShellGet.psd1' }
        ) {
            $directory = Build-ManifestDirectory -Name $Name
            $configuration = Write-WindowsLaneManifest -Directory $directory
            $path = Join-Path $directory 'pmu-ci-lane-test-run-1-lane-a/lane-manifest.json'
            $manifest = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -AsHashtable
            $manifest.provisioning.nativeProvider.manifestPath = $ManifestPath
            $manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $path
            @(Invoke-WindowsTestGate -Directory $directory -Configuration $configuration).Count | Should -BeGreaterThan 0
        }
    }

    It 'passes only when every required job succeeded and every expected lane manifest passed for the commit' {
        $directory = Build-ManifestDirectory -Name 'ok'
        @(Invoke-TestGate -JobResult $script:allSuccess `
                -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha).Count | Should -Be 0
    }

    It 'fails when a required job failed' {
        $directory = Build-ManifestDirectory -Name 'failed-job'
        $result = $script:allSuccess.Clone()
        $result.quality = 'failure'
        Invoke-TestGate -JobResult         $result -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha |
            Should -Contain "Required job 'quality' finished with result 'failure'."
    }

    It 'fails when a required job was cancelled' {
        $directory = Build-ManifestDirectory -Name 'cancelled'
        $result = $script:allSuccess.Clone()
        $result.platform = 'cancelled'
        Invoke-TestGate -JobResult         $result -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha |
            Should -Contain "Required job 'platform' finished with result 'cancelled'."
    }

    It 'fails when a required job was skipped' {
        $directory = Build-ManifestDirectory -Name 'skipped'
        $result = $script:allSuccess.Clone()
        $result.platform = 'skipped'
        Invoke-TestGate -JobResult         $result -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha |
            Should -Contain "Required job 'platform' finished with result 'skipped'."
    }

    It 'fails when a required job has no result at all' {
        $directory = Build-ManifestDirectory -Name 'absent'
        $result = @{
            plan = 'success'
            quality = 'success'
        }
        Invoke-TestGate -JobResult         $result -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha |
            Should -Contain "Required job 'platform' reported no result."
    }

    It 'fails when an expected lane manifest is missing even though the platform job reported success' {
        $directory = Build-ManifestDirectory -Name 'missing'
        Remove-Item -LiteralPath (Join-Path $directory 'pmu-ci-lane-test-run-1-lane-b') -Recurse
        Invoke-TestGate -JobResult         $script:allSuccess -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha |
            Should -Contain "Lane 'lane-b' produced no manifest."
    }

    It 'fails when a lane manifest records a failed status' {
        $directory = Build-ManifestDirectory -Name 'lane-failed' -Status @{ 'lane-a' = 'failed' }
        Invoke-TestGate -JobResult         $script:allSuccess -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha |
            Should -Contain "Lane 'lane-a' manifest status is 'failed'."
    }

    It 'fails when a lane manifest belongs to a different commit' {
        $directory = Build-ManifestDirectory -Name 'stale'
        Invoke-TestGate -JobResult $script:allSuccess -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha 'other' |
            Should -Contain "Lane 'lane-a' manifest belongs to commit 'f00dfeed', not 'other'."
    }

    It 'fails when a lane manifest is not an expected lane' {
        $directory = Build-ManifestDirectory -Name 'extra'
        Write-LaneManifest -Directory $directory -LaneId 'surprise'
        Invoke-TestGate -JobResult         $script:allSuccess -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha |
            Should -Contain "Unexpected lane manifest 'surprise'."
    }

    It 'fails when the manifest directory does not exist' {
        Invoke-TestGate -JobResult $script:allSuccess -ExpectedLaneId $lane -ManifestDirectory (Join-Path $TestDrive 'nowhere') -CommitSha $sha |
            Should -Contain "Lane 'lane-a' produced no manifest."
    }

    It 'rejects a status-only manifest with no runtime, phase or test evidence' {
        $directory = Build-ManifestDirectory -Name 'incomplete'
        @{
            laneId = 'lane-a'
            commitSha = $sha
            status = 'passed'
        } | ConvertTo-Json |
            Set-Content -LiteralPath (Join-Path $directory 'pmu-ci-lane-test-run-1-lane-a/lane-manifest.json')
        @(Invoke-TestGate -JobResult $script:allSuccess -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha).Count |
            Should -BeGreaterThan 0
    }

    It 'rejects invalid lane evidence: <Name>' -ForEach @(
        @{
            Name = 'missing native provider'
            Field = 'provisioning.nativeProvider'
            Value = $null
        }
        @{
            Name = 'wrong native name'
            Field = 'provisioning.nativeProvider.name'
            Value = 'Other'
        }
        @{
            Name = 'wrong requested native version'
            Field = 'provisioning.nativeProvider.requestedVersion'
            Value = '2.2.6'
        }
        @{
            Name = 'wrong actual native version'
            Field = 'provisioning.nativeProvider.actualVersion'
            Value = '2.2.6'
        }
        @{
            Name = 'untrusted native repository'
            Field = 'provisioning.nativeProvider.sourceRepository'
            Value = 'Other'
        }
        @{
            Name = 'untrusted native endpoint'
            Field = 'provisioning.nativeProvider.sourceUri'
            Value = 'https://unexpected.invalid/api/v2'
        }
        @{
            Name = 'native manifest outside runtime'
            Field = 'provisioning.nativeProvider.manifestPath'
            Value = '/shared/PowerShellGet.psd1'
        }
        @{
            Name = 'versioned native layout'
            Field = 'provisioning.nativeProvider.manifestPath'
            Value = '/owned-runtime/Modules/PowerShellGet/2.2.5/PowerShellGet.psd1'
        }
        @{
            Name = 'wrong run'
            Field = 'identity.runId'
            Value = 'old-run'
        }
        @{
            Name = 'wrong attempt'
            Field = 'identity.runAttempt'
            Value = '9'
        }
        @{
            Name = 'missing schema'
            Field = 'schemaVersion'
            Value = $null
        }
        @{
            Name = 'empty manifest commit'
            Field = 'commitSha'
            Value = ''
        }
        @{
            Name = 'missing execution identity'
            Field = 'identity.executionId'
            Value = ''
        }
        @{
            Name = 'wrong OS'
            Field = 'environment.OperatingSystem'
            Value = 'Windows'
        }
        @{
            Name = 'wrong edition'
            Field = 'environment.PowerShellEdition'
            Value = 'Desktop'
        }
        @{
            Name = 'wrong architecture'
            Field = 'environment.ProcessArchitecture'
            Value = 'Arm64'
        }
        @{
            Name = 'wrong lane image'
            Field = 'configuration.runner'
            Value = 'surprise'
        }
        @{
            Name = 'missing runner metadata'
            Field = 'environment.RunnerArch'
            Value = $null
        }
        @{
            Name = 'missing phase'
            Field = 'phases'
            Value = @()
        }
        @{
            Name = 'missing tests'
            Field = 'tests'
            Value = @{}
        }
        @{
            Name = 'zero executed'
            Field = 'tests.integration.Passed'
            Value = 0
        }
        @{
            Name = 'test failures'
            Field = 'tests.unit.Failed'
            Value = 1
        }
        @{
            Name = 'unexpected skips'
            Field = 'tests.unit.Skipped'
            Value = 1
        }
        @{
            Name = 'missing module metadata'
            Field = 'modules'
            Value = @{}
        }
        @{
            Name = 'invalid manifest count type'
            Field = 'tests.unit.Total'
            Value = '2'
        }
    ) {
        $directory = Build-ManifestDirectory -Name $Name
        $path = Join-Path $directory 'pmu-ci-lane-test-run-1-lane-a/lane-manifest.json'
        $manifest = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -AsHashtable
        $target = $manifest
        $parts = $Field.Split('.')
        foreach ($part in $parts[0..($parts.Count - 2)] | Where-Object { $parts.Count -gt 1 }) {
            $target = $target[$part]
        }
        $target[$parts[-1]] = $Value
        $manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $path
        @(Invoke-TestGate -JobResult $script:allSuccess -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha).Count |
            Should -BeGreaterThan 0
    }

    It 'rejects invalid JSON instead of silently dropping it' {
        $directory = Build-ManifestDirectory -Name 'invalid-json'
        Set-Content -LiteralPath (Join-Path $directory 'pmu-ci-lane-test-run-1-lane-a/lane-manifest.json') -Value '{'
        @(Invoke-TestGate -JobResult $script:allSuccess -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha).Count |
            Should -BeGreaterThan 0
    }

    It 'rejects duplicate lane manifests' {
        $directory = Build-ManifestDirectory -Name 'duplicate'
        Copy-Item -LiteralPath (Join-Path $directory 'pmu-ci-lane-test-run-1-lane-a') -Destination (Join-Path $directory 'duplicate') -Recurse
        Invoke-TestGate -JobResult $script:allSuccess -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha |
            Should -Contain "Lane 'lane-a' produced 2 manifests."
    }

    It 'rejects missing detailed evidence even when every manifest says passed' {
        $directory = Build-ManifestDirectory -Name 'missing-detail'
        Remove-Item -LiteralPath (Join-Path $directory 'pmu-ci-lane-test-run-1-lane-a/unit-details.json')
        @(Invoke-TestGate -JobResult $script:allSuccess -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha).Count |
            Should -BeGreaterThan 0
    }

    It 'rejects missing retained evidence: <File>' -ForEach @(
        @{ File = 'unit-nunit.xml' }
        @{ File = 'integration-nunit.xml' }
        @{ File = 'logs/unit.log' }
        @{ File = 'logs/integration.log.runtime.json' }
        @{ File = 'logs/unit.log.test-runtime.json' }
    ) {
        $directory = Build-ManifestDirectory -Name ($File.Replace('/', '-'))
        Remove-Item -LiteralPath (Join-Path $directory "pmu-ci-lane-test-run-1-lane-a/$File")
        @(Invoke-TestGate -JobResult $script:allSuccess -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha).Count |
            Should -BeGreaterThan 0
    }

    It 'rejects a phase that reports boolean false instead of an actual zero exit code' {
        $directory = Build-ManifestDirectory -Name 'invalid-exit-type'
        $path = Join-Path $directory 'pmu-ci-lane-test-run-1-lane-a/lane-manifest.json'
        $manifest = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -AsHashtable
        $manifest.phases[0].ExitCode = $false
        $manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $path
        @(Invoke-TestGate -JobResult $script:allSuccess -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha).Count |
            Should -BeGreaterThan 0
    }

    It 'rejects an empty current commit' {
        $directory = Build-ManifestDirectory -Name 'empty-commit'
        @(Invoke-TestGate -JobResult $script:allSuccess -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha '').Count |
            Should -BeGreaterThan 0
    }
}

Describe 'ConvertTo-CiGateJobResult' -Tag 'BuildTooling' {
    It 'maps the needs context JSON to a job-to-result table' {
        $json = '{"plan":{"result":"success","outputs":{}},"platform":{"result":"failure","outputs":{}}}'
        $table = ConvertTo-CiGateJobResult -NeedsJson $json
        $table['plan'] | Should -Be 'success'
        $table['platform'] | Should -Be 'failure'
    }
}

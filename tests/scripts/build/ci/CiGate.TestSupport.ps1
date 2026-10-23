function Get-CiGateTestConfiguration {
    param([string]$LaneId)

    return @{ id = $LaneId; name = $LaneId; runner = 'ubuntu-24.04'; os = 'Linux'; architecture = 'X64'; runtimeIdentifier = 'linux-x64'; powershell = '7.4' }
}

function Write-CiGateTestPhase {
    param([string]$Directory, [string]$Name, [hashtable]$Record)

    $log = Join-Path $Directory "logs/$Name.log"
    $Record.Context.phase = $Name
    $Record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath "$log.runtime.json"
    if ($Name -ne 'build') { $Record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath "$log.test-runtime.json" }
    @("Running tests from '/fixture/tests/example.Tests.ps1'", 'Describing fixture', '  [+] one 1ms (1ms|0ms)', '  [+] two 1ms (1ms|0ms)') | Set-Content -LiteralPath $log
    return @{ Name = $Name; ExitCode = 0; Environment = $Record.Environment; Executable = $Record.Executable; ProcessId = $Record.ProcessId; DurationSeconds = 1; LogFile = "$Name.log"; RuntimeFile = "$Name.log.runtime.json"; TestRuntimeFile = "$Name.log.test-runtime.json" }
}

function Write-CiGateTestReport {
    param([string]$Directory, [string]$Name)

    '<test-results total="2" errors="0" failures="0" inconclusive="0" skipped="0"><test-suite total="2" passed="2" failed="0" skipped="0" /></test-results>' |
            Set-Content -LiteralPath (Join-Path $Directory "$Name-nunit.xml")
    $detail = @('one', 'two' | ForEach-Object { @{ File = 'tests/example.Tests.ps1'; Name = $_; Result = 'Passed' } })
    $detail | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Directory "$Name-details.json")
    return @{ Total = 2; Passed = 2; Failed = 0; Skipped = 0; SkippedName = @() }
}

function Write-CiGateTestManifest {
    param([string]$Directory, [string]$LaneId, [string]$Status, [string]$CommitSha)

    $folder = Join-Path $Directory "pmu-ci-lane-test-run-1-$LaneId"
    New-Item -ItemType Directory -Path (Join-Path $folder 'logs') -Force | Out-Null
    $identity = @{ laneId = $LaneId; commitSha = $CommitSha; runId = 'test-run'; runAttempt = '1'; executionId = 'a' * 32 }
    $environment = @{ OperatingSystem = 'Linux'; OsArchitecture = 'X64'; ProcessArchitecture = 'X64'; PowerShellVersion = '7.4.21'; PowerShellEdition = 'Core'; RunnerOs = 'Linux'; RunnerArch = 'X64'; RunnerEnvironment = 'github-hosted'; ImageOs = 'ubuntu24'; ImageVersion = '20261023.1' }
    $runtime = @{ Executable = '/pwsh'; ProcessId = 123; Environment = $environment; Context = $identity.Clone(); PesterVersion = '5.7.1' }
    $expected = @{ OperatingSystem = 'Linux'; Architecture = 'X64'; PowerShellVersion = '7.4.21'; PowerShellChannel = '7.4'; Executable = '/pwsh' }
    $phases = @('build', 'unit', 'integration' | ForEach-Object { Write-CiGateTestPhase -Directory $folder -Name $_ -Record $runtime })
    $summary = @{ unit = (Write-CiGateTestReport -Directory $folder -Name unit); integration = (Write-CiGateTestReport -Directory $folder -Name integration) }
    $manifest = @{ schemaVersion = 1; laneId = $LaneId; commitSha = $CommitSha; status = $Status; identity = $identity; environment = $environment; configuration = (Get-CiGateTestConfiguration $LaneId); selectedRuntime = $expected; phases = $phases; tests = $summary; mismatches = @(); modules = @{} }
    $manifest.provisioning = @{ sha256 = 'a' * 64; fileName = 'archive'; hashSource = 'pinned'; channel = '7.4'; version = '7.4.21'; runtimeIdentifier = 'linux-x64'; executable = '/pwsh'; runtime = $runtime }
    $manifest.modules = @{ Pester = @('5.9.1'); NovaModuleTools = @('3.4.2'); PSScriptAnalyzer = @('1.25.0'); 'Microsoft.PowerShell.PSResourceGet' = @('1.2.0'); 'Microsoft.PowerShell.PlatyPS' = @('1.0.3') }
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $folder 'lane-manifest.json')
}

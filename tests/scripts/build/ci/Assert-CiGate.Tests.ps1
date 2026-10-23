BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $root 'scripts/build/ci/Assert-CiGate.ps1')

    $lane = @('lane-a', 'lane-b')
    $sha = 'f00dfeed'

    function Write-LaneManifest {
        param([string]$Directory, [string]$LaneId, [string]$Status = 'passed', [string]$CommitSha = $sha)
        $folder = Join-Path $Directory "pmu-ci-lane-$LaneId"
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        @{ laneId = $LaneId; status = $Status; commitSha = $CommitSha } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $folder 'lane-manifest.json')
    }

    function Build-ManifestDirectory {
        param([string]$Name, [hashtable]$Status = @{})
        $directory = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        foreach ($id in $lane) {
            $laneStatus = if ($Status.ContainsKey($id)) { $Status[$id] } else { 'passed' }
            Write-LaneManifest -Directory $directory -LaneId $id -Status $laneStatus
        }
        $directory
    }

    $script:allSuccess = @{ plan = 'success'; quality = 'success'; platform = 'success' }
}

Describe 'Test-CiGateResult' -Tag 'BuildTooling' {
    It 'passes only when every required job succeeded and every expected lane manifest passed for the commit' {
        $directory = Build-ManifestDirectory -Name 'ok'
        @(Test-CiGateResult -JobResult $script:allSuccess `
            -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha).Count | Should -Be 0
    }

    It 'fails when a required job failed' {
        $directory = Build-ManifestDirectory -Name 'failed-job'
        $result = $script:allSuccess.Clone(); $result.quality = 'failure'
        Test-CiGateResult -JobResult         $result -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha |
                Should -Contain "Required job 'quality' finished with result 'failure'."
    }

    It 'fails when a required job was cancelled' {
        $directory = Build-ManifestDirectory -Name 'cancelled'
        $result = $script:allSuccess.Clone(); $result.platform = 'cancelled'
        Test-CiGateResult -JobResult         $result -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha |
                Should -Contain "Required job 'platform' finished with result 'cancelled'."
    }

    It 'fails when a required job was skipped' {
        $directory = Build-ManifestDirectory -Name 'skipped'
        $result = $script:allSuccess.Clone(); $result.platform = 'skipped'
        Test-CiGateResult -JobResult         $result -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha |
                Should -Contain "Required job 'platform' finished with result 'skipped'."
    }

    It 'fails when a required job has no result at all' {
        $directory = Build-ManifestDirectory -Name 'absent'
        $result = @{ plan = 'success'; quality = 'success' }
        Test-CiGateResult -JobResult         $result -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha |
                Should -Contain "Required job 'platform' reported no result."
    }

    It 'fails when an expected lane manifest is missing even though the platform job reported success' {
        $directory = Build-ManifestDirectory -Name 'missing'
        Remove-Item -LiteralPath (Join-Path $directory 'pmu-ci-lane-lane-b') -Recurse
        Test-CiGateResult -JobResult         $script:allSuccess -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha |
                Should -Contain "Lane 'lane-b' produced no manifest."
    }

    It 'fails when a lane manifest records a failed status' {
        $directory = Build-ManifestDirectory -Name 'lane-failed' -Status @{ 'lane-a' = 'failed' }
        Test-CiGateResult -JobResult         $script:allSuccess -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha |
                Should -Contain "Lane 'lane-a' manifest status is 'failed'."
    }

    It 'fails when a lane manifest belongs to a different commit' {
        $directory = Build-ManifestDirectory -Name 'stale'
        Test-CiGateResult -JobResult $script:allSuccess -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha 'other' |
                Should -Contain "Lane 'lane-a' manifest belongs to commit 'f00dfeed', not 'other'."
    }

    It 'fails when a lane manifest is not an expected lane' {
        $directory = Build-ManifestDirectory -Name 'extra'
        Write-LaneManifest -Directory $directory -LaneId 'surprise'
        Test-CiGateResult -JobResult         $script:allSuccess -ExpectedLaneId $lane -ManifestDirectory $directory -CommitSha $sha |
                Should -Contain "Unexpected lane manifest 'surprise'."
    }

    It 'fails when the manifest directory does not exist' {
        Test-CiGateResult -JobResult $script:allSuccess -ExpectedLaneId $lane -ManifestDirectory (Join-Path $TestDrive 'nowhere') -CommitSha $sha |
                Should -Contain "Lane 'lane-a' produced no manifest."
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

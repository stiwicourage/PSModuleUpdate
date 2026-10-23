BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $root 'scripts/build/ci/CiLaneEnvironment.ps1')

    function Build-TestEnvironment {
        param([hashtable]$Override = @{})
        $environment = [ordered]@{
            OperatingSystem = 'Linux'
            OsArchitecture = 'X64'
            ProcessArchitecture = 'X64'
            PowerShellVersion = '7.4.21'
            PowerShellEdition = 'Core'
            RunnerOs = 'Linux'
            RunnerArch = 'X64'
            RunnerEnvironment = 'github-hosted'
        }
        foreach ($key in $Override.Keys) {
            $environment[$key] = $Override[$key]
        }
        [pscustomobject]$environment
    }

    $script:expected = [pscustomobject]@{
        OperatingSystem = 'Linux'
        Architecture = 'X64'
        PowerShellChannel = '7.4'
        PowerShellVersion = '7.4.21'
    }
}

Describe 'Test-CiLaneEnvironment' -Tag 'BuildTooling' {
    It 'reports no mismatch when the environment matches the lane' {
        $actual = Build-TestEnvironment
        @(Test-CiLaneEnvironment -Expected $script:expected -Actual $actual -RequireGitHubHosted).Count | Should -Be 0
    }

    It 'reports an operating system mismatch' {
        $actual = Build-TestEnvironment @{ OperatingSystem = 'Windows'; RunnerOs = 'Windows' }
        Test-CiLaneEnvironment -Expected $script:expected -Actual $actual | Should -Contain "Operating system is 'Windows' but the lane expects 'Linux'."
    }

    It 'reports a runner architecture mismatch such as an Intel macOS runner' {
        $actual = Build-TestEnvironment @{ OsArchitecture = 'Arm64'; ProcessArchitecture = 'Arm64'; RunnerArch = 'ARM64' }
        @(Test-CiLaneEnvironment -Expected $script:expected -Actual $actual) | Should -Contain "OS architecture is 'Arm64' but the lane expects 'X64'."
    }

    It 'reports a translated process architecture' {
        $actual = Build-TestEnvironment @{ ProcessArchitecture = 'Arm64' }
        @(Test-CiLaneEnvironment -Expected $script:expected -Actual $actual) | Should -Contain "Process architecture is 'Arm64' but the lane expects 'X64'."
    }

    It 'reports a PowerShell version that differs from the provisioned version' {
        $actual = Build-TestEnvironment @{ PowerShellVersion = '7.6.8' }
        @(Test-CiLaneEnvironment -Expected $script:expected -Actual $actual) | Should -Contain "PowerShell version is '7.6.8' but the lane expects '7.4.21'."
    }

    It 'reports a PowerShell version outside the requested numeric channel' {
        $actual = Build-TestEnvironment @{ PowerShellVersion = '7.6.8' }
        $channelExpected = [pscustomobject]@{ OperatingSystem = 'Linux'; Architecture = 'X64'; PowerShellChannel = '7.4'; PowerShellVersion = '7.6.8' }
        @(Test-CiLaneEnvironment -Expected $channelExpected -Actual $actual) | Should -Contain "PowerShell version '7.6.8' is not in the requested '7.4' channel."
    }

    It 'accepts any version for the stable channel when it equals the provisioned version' {
        $actual = Build-TestEnvironment @{ PowerShellVersion = '7.6.8' }
        $stableExpected = [pscustomobject]@{ OperatingSystem = 'Linux'; Architecture = 'X64'; PowerShellChannel = 'stable'; PowerShellVersion = '7.6.8' }
        @(Test-CiLaneEnvironment -Expected $stableExpected -Actual $actual).Count | Should -Be 0
    }

    It 'rejects Windows PowerShell editions' {
        $actual = Build-TestEnvironment @{ PowerShellEdition = 'Desktop' }
        @(Test-CiLaneEnvironment -Expected $script:expected -Actual $actual) | Should -Contain "PowerShell edition is 'Desktop' but 'Core' is required."
    }

    It 'rejects a runner that is not GitHub-hosted when hosting is required' {
        $actual = Build-TestEnvironment @{ RunnerEnvironment = 'self-hosted' }
        @(Test-CiLaneEnvironment -Expected $script:expected -Actual $actual -RequireGitHubHosted) | Should -Contain "Runner environment is 'self-hosted' but 'github-hosted' is required."
    }

    It 'does not require a runner environment outside GitHub Actions' {
        $actual = Build-TestEnvironment @{ RunnerEnvironment = $null; RunnerOs = $null; RunnerArch = $null }
        @(Test-CiLaneEnvironment -Expected $script:expected -Actual $actual).Count | Should -Be 0
    }

    It 'reports a RUNNER_OS or RUNNER_ARCH value that contradicts the detected platform' {
        $actual = Build-TestEnvironment @{ RunnerOs = 'macOS'; RunnerArch = 'ARM64' }
        $messages = @(Test-CiLaneEnvironment -Expected $script:expected -Actual $actual)
        $messages | Should -Contain "RUNNER_OS is 'macOS' but the lane expects 'Linux'."
        $messages | Should -Contain "RUNNER_ARCH is 'ARM64' but the lane expects 'X64'."
    }
}

Describe 'Get-CiLaneEnvironment' -Tag 'BuildTooling' {
    It 'describes the running PowerShell without exposing arbitrary environment variables' {
        $actual = Get-CiLaneEnvironment

        $actual.PowerShellVersion | Should -Be $PSVersionTable.PSVersion.ToString()
        $actual.PowerShellEdition | Should -Be 'Core'
        $actual.OperatingSystem | Should -BeIn @('Windows', 'Linux', 'macOS')
        $actual.ProcessArchitecture | Should -BeIn @('X64', 'Arm64', 'X86', 'Arm')
        $actual.PSObject.Properties.Name | Should -Not -Contain 'Path'
    }
}

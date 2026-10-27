BeforeAll {
    . "$PSScriptRoot/../TestHelpers/Import-PMUTestSource.ps1"
    . "$PSScriptRoot/../TestHelpers/Invoke-PMUChildProcess.ps1"
    . "$PSScriptRoot/../TestHelpers/Receive-PMUChildProcess.ps1"
    . "$PSScriptRoot/../TestHelpers/Wait-PMUFixtureSignal.ps1"
    . "$PSScriptRoot/../TestHelpers/Close-PMUChildProcess.ps1"
}
Describe 'PMU backup-only public recovery' -Tag 'PMUBackupReference' {
    It 'recovers in a fresh process using only a validated backup PSModuleInfo after the sole installation vanished' {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = Initialize-PMUTestPackage "$root/Modules" '1.0.0'
        $null = Initialize-PMUTestPackage "$root/Modules" '2.0.0-preview.1'
        $null = Initialize-PMUTestPackage "$root/package" '2.0.0-preview.2'
        $crashed = Receive-PMUChildProcess (Invoke-PMUChildProcess $root 'Crash')
        $crashed.ExitCode | Should -Be 73 -Because $crashed.Error
        Remove-Item "$root/Modules/FixtureModule/1.0.0" -Recurse -Force
        $recovered = Receive-PMUChildProcess (Invoke-PMUChildProcess $root 'RecoverBackup')
        $recovered.ExitCode | Should -Be 0 -Because $recovered.Error
        ($recovered.Output | ConvertFrom-Json).Outcome | Should -Be Recovered
        (Get-ManifestIdentity "$root/Modules/FixtureModule/2.0.0/FixtureModule.psd1").Version.FullVersion | Should -Be '2.0.0-preview.1'
        Test-Path "$root/installs.txt" | Should -BeFalse
    }
}
Describe 'PMU process recovery and concurrency' -Tag 'PMU', 'PMUProcessRecovery' {
    BeforeEach {
        $script:processRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = Initialize-PMUTestPackage "$processRoot/Modules" '1.0.0'
        $null = Initialize-PMUTestPackage "$processRoot/Modules" '2.0.0-preview.1'
        $null = Initialize-PMUTestPackage "$processRoot/package" '2.0.0-preview.2'
    }
    It 'recovers through new-process public planning after process exit during replacement' {
        $crashed = Receive-PMUChildProcess (Invoke-PMUChildProcess $processRoot 'Crash')
        $crashed.ExitCode | Should -Be 73 -Because $crashed.Error
        Test-Path "$processRoot/Modules/FixtureModule/2.0.0" | Should -BeFalse
        $recovered = Receive-PMUChildProcess (Invoke-PMUChildProcess $processRoot 'Recover')
        $recovered.ExitCode | Should -Be 0 -Because $recovered.Error
        ($recovered.Output | ConvertFrom-Json).Outcome | Should -Be 'Recovered'
        (Get-ManifestIdentity "$processRoot/Modules/FixtureModule/2.0.0/FixtureModule.psd1").Version.FullVersion | Should -Be '2.0.0-preview.1'
        Test-Path "$processRoot/installs.txt" | Should -BeFalse
    }
    It 'serializes two processes from <SecondRepository> and makes the second verified target a no-op' -ForEach @(
        @{ SecondRepository = 'OwnedFeed' }
        @{ SecondRepository = 'AlternateFeed' }
    ) {
        $first = Invoke-PMUChildProcess $processRoot 'Update'
        $second = Invoke-PMUChildProcess $processRoot 'Update' $SecondRepository
        try {
            Wait-PMUFixtureSignal $processRoot 'ready-*' 2
            [IO.File]::WriteAllText("$processRoot/start", '')
            $a, $b = (Receive-PMUChildProcess $first), (Receive-PMUChildProcess $second)
            $a.ExitCode | Should -Be 0 -Because $a.Error
            $b.ExitCode | Should -Be 0 -Because $b.Error
            ($a.Output | ConvertFrom-Json).RepositoryName | Should -Be OwnedFeed
            ($b.Output | ConvertFrom-Json).RepositoryName | Should -Be $SecondRepository
            @((($a.Output | ConvertFrom-Json).Outcome), (($b.Output | ConvertFrom-Json).Outcome)) | Sort-Object | Should -Be @('AlreadyInstalled', 'Installed')
            @(Get-Content "$processRoot/installs.txt").Count | Should -Be 1
        } finally {
            Close-PMUChildProcess @($first, $second)
        }
    }
    It 'times out a real competing process, releases the OS lock after hard kill, and publicly recovers' {
        $holder = Invoke-PMUChildProcess $processRoot 'Hold'
        try {
            Wait-PMUFixtureSignal $processRoot 'mutation-started'
            $blocked = Receive-PMUChildProcess (Invoke-PMUChildProcess $processRoot 'Attempt')
            $blocked.ExitCode | Should -Be 2 -Because $blocked.Error
            ($blocked.Output | ConvertFrom-Json).ErrorId | Should -BeLike 'PMU.LockTimeout*'
            $holder.Kill($true)
            $null = Receive-PMUChildProcess $holder
            $recovered = Receive-PMUChildProcess (Invoke-PMUChildProcess $processRoot 'Recover')
            $recovered.ExitCode | Should -Be 0 -Because $recovered.Error
            ($recovered.Output | ConvertFrom-Json).Outcome | Should -Be 'Recovered'
        } finally {
            Close-PMUChildProcess @($holder)
        }
    }
    It 'keeps the actual loaded module active while reporting replaced files require restart' {
        [IO.File]::WriteAllText("$processRoot/Modules/FixtureModule/2.0.0/FixtureModule.psm1", '$script:FixtureValue = 1')
        $loaded = Receive-PMUChildProcess (Invoke-PMUChildProcess $processRoot 'Loaded')
        $loaded.ExitCode | Should -Be 0 -Because $loaded.Error
        $result = $loaded.Output | ConvertFrom-Json
        $result.ActiveVersion | Should -Be '2.0.0-preview.1'
        $result.InstalledVersion | Should -Be '2.0.0-preview.2'
        $result.RestartRequired | Should -BeTrue
    }
}

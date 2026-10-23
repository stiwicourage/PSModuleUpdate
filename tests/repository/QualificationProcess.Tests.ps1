BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:launcherPath = "$root/scripts/qualification/Invoke-RepositoryQualification.ps1"
    . "$root/scripts/qualification/QualificationSafety.ps1"
    . "$root/scripts/qualification/QualificationProcess.ps1"
    . "$root/scripts/qualification/QualificationSession.ps1"
    . "$root/scripts/qualification/QualificationRepository.ps1"
    . "$root/scripts/qualification/QualificationScenario.ps1"
    . "$root/src/public/Get-PSModuleUpdate.ps1"
}

Describe 'Qualification child process and cleanup' -Tag 'RepositoryQualification' {
    It 'refuses both normal default invocation and missing shared-store approval before resolving paths' {
        { & $launcherPath -Options @{} } | Should -Throw '*opt-in*'
        { & $launcherPath -Options @{} -EnableLive } | Should -Throw '*store*'
    }

    It 'keeps credentials out of arguments and isolates child install destinations' {
        $credential = [pscredential]::new('test-user', (ConvertTo-QualificationSecret 'fixture-only'))
        $info = Initialize-QualificationProcessInfo @{ Scenario = 'Private' } "$TestDrive/child" $credential
        ($info.ArgumentList -join ' ') | Should -Not -Match 'fixture-only|test-user'
        $info.Environment['HOME'] | Should -Be "$TestDrive/child/home"
        $info.Environment['XDG_DATA_HOME'] | Should -Be "$TestDrive/child/home/.local/share"
        $info.RedirectStandardError | Should -BeTrue
        $info.UseShellExecute | Should -BeFalse
    }

    It 'reports cleanup failure explicitly rather than returning a passing live result' {
        Mock Invoke-QualificationRegistrationCleanup { throw 'cleanup fixture failure' }
        $session = [pscustomobject]@{ Evidence = [ordered]@{ Outcome = 'Passed' }; Before = @() }
        Complete-QualificationSession $session
        $session.Evidence.Cleanup | Should -Be 'Failed'
        $session.Evidence.Outcome | Should -Be 'Failed'
    }

    It 'compares existing repository state after successful owned-entry cleanup' {
        Mock Invoke-QualificationRegistrationCleanup {}
        Mock Get-QualificationRepositoryState { 'existing-registration' }
        $session = [pscustomobject]@{ Evidence = [ordered]@{ Outcome = 'Passed' }; Before = @('existing-registration') }
        Complete-QualificationSession $session
        $session.Evidence.Cleanup | Should -Be 'Passed'
        Should -Invoke Invoke-QualificationRegistrationCleanup -Times 1 -Exactly
        Should -Invoke Get-QualificationRepositoryState -Times 1 -Exactly
    }

    It 'canonicalizes the macOS temporary base before applying no-symlink installation guards' -Skip:(-not $IsMacOS) {
        $temporary = Get-QualificationTemporaryRoot
        { Assert-QualificationUnlinkedPath $temporary } | Should -Not -Throw
        $temporary | Should -Match 'pmu-qualification-[a-f0-9]{32}$'
    }

    It 'plans a public update without splatting an absent PSCredential' {
        Mock Get-PSModuleUpdate { [pscustomobject]@{ TargetVersion = '2.1.0'; RepositoryUri = 'https://example.test/' } }
        Mock Assert-QualificationPlanIdentity {}
        $session = [pscustomobject]@{
            Credential = $null; RepositoryName = 'QualificationFixture'; Evidence = @{}
            Options = @{ Scenario = 'Gallery'; TargetVersion = '2.1.0'; RepositoryUri = 'https://example.test/' }
        }
        $module = New-Module -Name QualificationFixture -ScriptBlock {}
        (Get-QualificationPlan $session $module).TargetVersion | Should -Be '2.1.0'
        Should -Invoke Get-PSModuleUpdate -Times 1 -Exactly -ParameterFilter { $null -eq $Credential }
    }
}

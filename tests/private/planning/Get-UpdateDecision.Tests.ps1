BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-UpdateDecision' -Tag 'PMU' {
    It 'distinguishes installed restart from update and never downgrades an active version' {
        $context = [pscustomobject]@{
            Target = @{ Version = @{ FullVersion = '2.0.0' } }
            Active = @{ Version = @{ FullVersion = '1.0.0' } }
            Installed = @{ FullVersion = '2.0.0' }
        }
        (Get-UpdateDecision $context).Disposition | Should -Be 'AlreadyInstalledRestartRequired'
        $context.Active.Version.FullVersion = '3.0.0'
        (Get-UpdateDecision $context).Disposition | Should -Be 'UpToDate'
    }
}

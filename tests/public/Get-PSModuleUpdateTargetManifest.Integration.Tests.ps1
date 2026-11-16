# The offline native provider fixture owns its HOME, package feed and install destination.
BeforeAll {
    . "$PSScriptRoot/../TestHelpers/Receive-PMUChildProcess.ps1"
    . "$PSScriptRoot/../TestHelpers/Invoke-PMULocalProviderProcess.ps1"
    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:modulePath = Join-Path $root 'dist/PSModuleUpdate/PSModuleUpdate.psd1'
    Import-Module $modulePath -Force
}
Describe 'Get-PSModuleUpdateTargetManifest built surface' -Tag 'Integration', 'PMUTargetManifestIntegration' {
    It 'exports the exact four inputs and safely rejects serialized authorization' {
        $command = Get-Command Get-PSModuleUpdateTargetManifest -Module PSModuleUpdate
        @($command.Parameters.Keys | Where-Object {
                $_ -in @('Plan', 'Credential', 'TrustRepository', 'AcceptLicense')
            }).Count | Should -Be 4
        {
            Get-PSModuleUpdateTargetManifest -Plan ([pscustomobject]@{
                    SchemaVersion = 1
                })
        } | Should -Throw -ErrorId PMU.InvalidPlan
        ((Get-Help Get-PSModuleUpdateTargetManifest -Full).Description.Text -join "`n") | Should -Match 'exact planned candidate'
    }
    It 'inspects an offline exact package, rejects changed MinimumGerberVersion, then installs unchanged content' -Skip:(-not $IsMacOS) {
        $fixtureScript = Join-Path $PSScriptRoot '../TestHelpers/Invoke-PMUManifestFixture.ps1'
        $result = Invoke-PMULocalProviderProcess (Join-Path $TestDrive 'inspection-provider') $modulePath $fixtureScript
        $result.ExitCode | Should -Be 0 -Because $result.Error
        $result.Output | Should -Match '"Version":"2.0.0-preview2","Outcome":"Installed"'
    }
}

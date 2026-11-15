BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module "$root/dist/PSModuleUpdate/PSModuleUpdate.psd1" -Force
}
Describe 'Install-PSModuleUpdate built surface' -Tag 'Integration', 'PMUHelp' {
    It 'preserves native ShouldProcess and rejects manufactured plans even with WhatIf' {
        $command = Get-Command Install-PSModuleUpdate -Module PSModuleUpdate
        $binding = $command.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
        $binding.ConfirmImpact | Should -Be 'High'
        $binding.SupportsShouldProcess | Should -BeTrue
        { [pscustomobject]@{ SchemaVersion = 1 } | Install-PSModuleUpdate -WhatIf } | Should -Throw -ErrorId 'PMU.InvalidPlan*'
    }
    It 'loads the generated external AcceptLicense reference' {
        $parameter = (Get-Help Install-PSModuleUpdate -Full).Parameters.Parameter | Where-Object Name -eq AcceptLicense
        ($parameter.Description.Text -join "`n") | Should -Match 'does not disclose'
    }
    It 'exports the unmanaged opt-in and loads its generated external help' {
        $command = Get-Command Install-PSModuleUpdate -Module PSModuleUpdate
        $command.Parameters['ReplaceUnmanagedInstallation'].ParameterType | Should -Be ([switch])
        $parameter = (Get-Help Install-PSModuleUpdate -Full).Parameters.Parameter | Where-Object Name -eq ReplaceUnmanagedInstallation
        ($parameter.Description.Text -join "`n") | Should -Match 'absent'
        ($parameter.Description.Text -join "`n") | Should -Match 'unreadable'
    }
}

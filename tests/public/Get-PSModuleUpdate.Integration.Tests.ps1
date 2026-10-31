BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module "$root/dist/PSModuleUpdate/PSModuleUpdate.psd1" -Force
}
Describe 'Get-PSModuleUpdate built surface' -Tag 'Integration', 'PMUHelp' {
    It 'exports only the approved commands and preserves the planning parameter set' {
        @(Get-Command -Module PSModuleUpdate).Name | Sort-Object | Should -Be @('Get-PSModuleUpdate', 'Get-PSModuleUpdateTargetManifest', 'Install-PSModuleUpdate')
        $command = Get-Command Get-PSModuleUpdate -Module PSModuleUpdate
        $command.ParameterSets.Name | Sort-Object | Should -Be @('ByModule', 'ByRepositoryUri')
        $command.Parameters['Module'].ParameterType | Should -Be ([System.Management.Automation.PSModuleInfo])
    }
    It 'loads generated external help including conservative license prerequisites' {
        $description = (Get-Help Get-PSModuleUpdate -Full).Description.Text -join "`n"
        $description | Should -Match 'conservatively sets'
    }
}

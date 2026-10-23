BeforeAll { . "$PSScriptRoot/../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-PSModuleUpdate' -Tag 'PMU' {
    It 'supports mutually exclusive name and URI parameter sets with shared policy and credential inputs' {
        $command = Get-Command Get-PSModuleUpdate
        $command.ParameterSets.Name | Sort-Object | Should -Be @('ByModule', 'ByRepositoryUri')
        $uriSet = $command.ParameterSets | Where-Object Name -eq ByRepositoryUri
        $uriSet.Parameters.Name | Should -Contain RepositoryUri
        $uriSet.Parameters.Name | Should -Not -Contain Repository
        $command.Parameters['RepositoryUri'].ParameterType | Should -Be ([uri])
        $command.Parameters.Keys | Should -Not -Contain Authentication
    }
    It 'has exactly the public planning parameters and mandatory scalar module binding' {
        $command = Get-Command Get-PSModuleUpdate
        @($command.ParameterSets | Where-Object Name -eq ByModule).Count | Should -Be 1
        $command.Parameters['Module'].ParameterType | Should -Be ([System.Management.Automation.PSModuleInfo])
        $command.Parameters['Policy'].ParameterType | Should -Be ([hashtable])
        $command.Parameters.Keys | Should -Not -Contain 'Name'
        $command.Parameters.Keys | Should -Not -Contain 'Scope'
        $command.Parameters.Keys | Should -Not -Contain 'WhatIf'
    }
}

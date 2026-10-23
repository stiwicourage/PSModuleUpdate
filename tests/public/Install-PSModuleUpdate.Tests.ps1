BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . "$root/tests/TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Install-PSModuleUpdate' -Tag 'PMU' {
    It 'rejects manufactured plans before mutation' {
        $plan = [pscustomobject]@{ PSTypeName = 'PSModuleUpdate.UpdatePlan'; SchemaVersion = 1 }
        { Install-PSModuleUpdate -Update $plan -Confirm:$false } | Should -Throw -ErrorId 'PMU.InvalidPlan*'
    }
    It 'exposes only the exact mutation API and native ShouldProcess' {
        $command = Get-Command Install-PSModuleUpdate
        $command.Parameters.Keys | Should -Contain 'WhatIf'
        $command.Parameters.Keys | Should -Not -Contain 'Force'
        $command.Parameters.Keys | Should -Not -Contain 'Reinstall'
        $binding = $command.Parameters['Update'].Attributes | Where-Object { $_ -is [Management.Automation.ParameterAttribute] }
        $binding.ValueFromPipeline | Should -BeTrue
        $binding.ValueFromPipelineByPropertyName | Should -BeFalse
    }
}

BeforeAll {
    $script:project = Get-Content -LiteralPath (Join-Path $PSScriptRoot '../project.json') -Raw |
        ConvertFrom-Json
}

Describe 'PMU runtime dependency contract' -Tag 'RuntimeDependency' {
    It 'requires the exact qualified PSResourceGet version' {
        $requirement = $script:project.Manifest.RequiredModules |
            Where-Object ModuleName -CEQ 'Microsoft.PowerShell.PSResourceGet'

        @($requirement).Count | Should -Be 1
        $requirement.RequiredVersion | Should -Be '1.2.0'
        $requirement.ModuleVersion | Should -BeNullOrEmpty
        $requirement.MaximumVersion | Should -BeNullOrEmpty
    }
}

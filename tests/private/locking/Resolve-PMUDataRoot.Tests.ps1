BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Resolve-PMUDataRoot' -Tag 'PMU', 'PMUCoverage' {
    It 'uses scope-specific state locations outside module trees without creating them' {
        $user = Resolve-PMUDataRoot 'CurrentUser'
        $all = Resolve-PMUDataRoot 'AllUsers'
        $user | Should -Not -Be $all
        $user | Should -Not -Match '[/\\]Modules[/\\]'
        $all | Should -Not -Match '[/\\]Modules[/\\]'
    }

    Context 'Platform-specific roots' {
        BeforeEach {
            $script:originalWindows = $IsWindows
            $script:originalMacOS = $IsMacOS
            Mock Assert-SafePath { $Path }
        }
        AfterEach {
            Set-Variable IsWindows $script:originalWindows -Force
            Set-Variable IsMacOS $script:originalMacOS -Force
        }

        It 'uses <Folder> for Windows <Scope> state' -ForEach @(
            @{ Scope = 'CurrentUser'; Folder = 'LocalApplicationData' }
            @{ Scope = 'AllUsers'; Folder = 'CommonApplicationData' }
        ) {
            Set-Variable IsWindows $true -Force
            $expected = Join-Path ([Environment]::GetFolderPath($Folder)) 'PSModuleUpdate'
            Resolve-PMUDataRoot $Scope | Should -BeExactly $expected
            Should -Invoke Assert-SafePath -Times 1 -Exactly -ParameterFilter { $Path -ceq $expected }
        }

        It 'uses <Expected> for non-Windows AllUsers state' -ForEach @(
            @{ MacOS = $true; Expected = '/Library/Application Support/PSModuleUpdate' }
            @{ MacOS = $false; Expected = '/var/lib/PSModuleUpdate' }
        ) {
            Set-Variable IsWindows $false -Force
            Set-Variable IsMacOS $MacOS -Force
            Resolve-PMUDataRoot 'AllUsers' | Should -BeExactly $Expected
            Should -Invoke Assert-SafePath -Times 1 -Exactly -ParameterFilter { $Path -ceq $Expected }
        }
    }
}

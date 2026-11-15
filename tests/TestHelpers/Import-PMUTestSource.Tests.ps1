BeforeAll {
    $script:pmuTestImportSource = Join-Path $PSScriptRoot 'Import-PMUTestSource.ps1'
}

Describe 'Test source loading' -Tag 'PMUTestSourceLoading' {
    BeforeEach {
        $fixtureRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $fixtureRoot
        $fixture = Join-Path $fixtureRoot 'Invoke-PMUTestLoadingProbe.ps1'
        $script:pmuTestLoadMarker = Join-Path $fixtureRoot 'loads.txt'
        Set-Content -LiteralPath $fixture -Value @'
Add-Content -LiteralPath (Join-Path $PSScriptRoot 'loads.txt') -Value 'loaded'
function Invoke-PMUTestLoadingProbe {
    return 'expected source'
}
'@
        Mock Get-ChildItem { Get-Item -LiteralPath $fixture } -ParameterFilter {
            $Filter -eq '*.ps1' -and $Recurse
        }
    }

    It 'does not reload a function already imported from the same source file' {
        . $script:pmuTestImportSource
        Invoke-PMUTestLoadingProbe | Should -Be 'expected source'
        . $script:pmuTestImportSource
        Invoke-PMUTestLoadingProbe | Should -Be 'expected source'
        @(Get-Content -LiteralPath $script:pmuTestLoadMarker) | Should -HaveCount 1
    }

    It 'replaces a same-named function imported from a different source file' {
        $foreignSource = Join-Path $TestDrive 'foreign.ps1'
        Set-Content -LiteralPath $foreignSource -Value @'
function Invoke-PMUTestLoadingProbe {
    return 'foreign source'
}
'@
        . $foreignSource
        Invoke-PMUTestLoadingProbe | Should -Be 'foreign source'
        . $script:pmuTestImportSource
        Invoke-PMUTestLoadingProbe | Should -Be 'expected source'
        @(Get-Content -LiteralPath $script:pmuTestLoadMarker) | Should -HaveCount 1
    }
}

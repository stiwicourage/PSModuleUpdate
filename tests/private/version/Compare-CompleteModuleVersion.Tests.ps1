BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/tests/TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Compare-CompleteModuleVersion' -Tag 'PMU' {
    It 'orders <Left> against <Right> as <Expected>' -ForEach @(
        @{
            Left = '2.0.0-preview.2'
            Right = '2.0.0-preview.10'
            Expected = -1
        }
        @{
            Left = '2.0.0'
            Right = '2.0.0-preview.10'
            Expected = 1
        }
        @{
            Left = '2.0.0.4'
            Right = '2.0.0.3'
            Expected = 1
        }
        @{
            Left = '2.0.0-alpha.1'
            Right = '2.0.0-alpha.beta'
            Expected = -1
        }
        @{
            Left = '2.0.0'
            Right = '2.0.0'
            Expected = 0
        }
    ) {
        Compare-CompleteModuleVersion $Left $Right | Should -Be $Expected
    }
}

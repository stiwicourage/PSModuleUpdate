BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/src/private/shared/Assert-SafePath.ps1"
}
Describe 'Assert-SafePath' -Tag 'PMU', 'PMUSafePath' {
    It 'canonicalizes a non-existing owned descendant without creating it' {
        Assert-SafePath "$TestDrive/owned/../safe" | Should -Be (Join-Path $TestDrive 'safe')
        Test-Path "$TestDrive/safe" | Should -BeFalse
    }
}

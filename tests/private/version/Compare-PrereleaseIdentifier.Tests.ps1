BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/src/private/version/Compare-PrereleaseIdentifier.ps1"
}
Describe 'Compare-PrereleaseIdentifier' -Tag 'PMU' {
    It 'compares arbitrarily large numeric identifiers without overflow' {
        Compare-PrereleaseIdentifier '99999999999999999999999' '10' | Should -Be 1
    }
    It 'orders numeric identifiers before alphanumeric ones in both directions' {
        Compare-PrereleaseIdentifier '1' 'alpha' | Should -Be -1
        Compare-PrereleaseIdentifier 'alpha' '1' | Should -Be 1
    }
    It 'compares non-numeric identifiers ordinally' {
        Compare-PrereleaseIdentifier 'alpha' 'beta' | Should -Be -1
        Compare-PrereleaseIdentifier 'Alpha' 'alpha' | Should -Be -1
    }
}

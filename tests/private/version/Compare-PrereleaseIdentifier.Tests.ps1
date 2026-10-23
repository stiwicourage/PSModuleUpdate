BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/src/private/version/Compare-PrereleaseIdentifier.ps1"
}
Describe 'Compare-PrereleaseIdentifier' -Tag 'PMU' {
    It 'compares arbitrarily large numeric identifiers without overflow' {
        Compare-PrereleaseIdentifier '99999999999999999999999' '10' | Should -Be 1
    }
}

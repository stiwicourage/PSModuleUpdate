BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/src/private/version/Compare-PrereleaseIdentifier.ps1"
    . "$root/src/private/version/Compare-PrereleaseSegmentList.ps1"
    . "$root/src/private/version/Compare-PrereleaseLabel.ps1"
}
Describe 'Compare-PrereleaseLabel' -Tag 'PMU' {
    It 'orders a longer otherwise-equal identifier list after the shorter one' {
        Compare-PrereleaseLabel 'preview.1.1' 'preview.1' | Should -Be 1
    }
    It 'treats identical labels as equal and orders a stable release after a prerelease' {
        Compare-PrereleaseLabel 'preview.1' 'preview.1' | Should -Be 0
        Compare-PrereleaseLabel '' 'preview.1' | Should -Be 1
        Compare-PrereleaseLabel 'preview.1' '' | Should -Be -1
    }
}

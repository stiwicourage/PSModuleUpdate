BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/src/private/planning/Get-LivePlanRegistry.ps1"
}
Describe 'Get-LivePlanRegistry' -Tag 'PMU' {
    It 'returns the same weak-keyed registry without enumerating it onto the pipeline' {
        $first = Get-LivePlanRegistry
        [object]::ReferenceEquals($first, (Get-LivePlanRegistry)) | Should -BeTrue
    }
}

BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/src/private/shared/Write-PMUError.ps1"
    . "$root/src/private/verification/Assert-FileTreeEqual.ps1"
}
Describe 'Assert-FileTreeEqual' -Tag 'PMU' {
    It 'detects unexpected and missing records' {
        { Assert-FileTreeEqual @('a') @('a', 'b') } | Should -Throw -ErrorId 'PMU.VerificationFailed'
        { Assert-FileTreeEqual @('a', 'b') @('a') } | Should -Throw -ErrorId 'PMU.VerificationFailed'
    }
}

BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/src/private/shared/Write-PMUError.ps1"
}
Describe 'Write-PMUError' -Tag 'PMU' {
    It 'emits a stable terminating record with safe guidance' {
        try {
            Write-PMUError 'PMU.InvalidRequest' 'Safe failure' 'Correct the request'
        } catch {
            $_.FullyQualifiedErrorId | Should -Be 'PMU.InvalidRequest'
            $_.TargetObject.RecoveryGuidance | Should -Be 'Correct the request'
        }
    }
}

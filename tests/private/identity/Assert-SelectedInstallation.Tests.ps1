BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/src/private/shared/Write-PMUError.ps1"
    . "$root/src/private/identity/Assert-SelectedInstallation.ps1"
}
Describe 'Assert-SelectedInstallation' -Tag 'PMU' {
    It 'rejects a missing scope and a mismatched GUID' {
        { Assert-SelectedInstallation @() ([guid]::NewGuid()) } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
        { Assert-SelectedInstallation @([pscustomobject]@{ Guid = [guid]::Empty }) ([guid]::NewGuid()) } | Should -Throw -ErrorId 'PMU.GuidMismatch'
    }
}

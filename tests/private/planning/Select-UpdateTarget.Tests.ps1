BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/tests/TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Select-UpdateTarget' -Tag 'PMU' {
    It 'excludes prereleases for Stable but includes stable in IncludePrerelease' {
        $releases = @('2.0.0', '3.0.0-preview.1') | ForEach-Object { [pscustomobject]@{ Version = ConvertTo-CompleteModuleVersion $_ } }
        (Select-UpdateTarget $releases 'Stable').Version.FullVersion | Should -Be '2.0.0'
        (Select-UpdateTarget $releases 'IncludePrerelease').Version.FullVersion | Should -Be '3.0.0-preview.1'
    }
    It 'fails discovery rather than manufacturing UpToDate on an empty feed' {
        { Select-UpdateTarget @() 'Stable' } | Should -Throw -ErrorId 'PMU.PackageNotFound'
    }
}

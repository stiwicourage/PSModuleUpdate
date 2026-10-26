BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
}
Describe 'Save-ProviderResource' -Tag 'PMU' {
    It 'saves exact target into staging with source metadata but no execution' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Mock Save-PSResource {}
        Save-ProviderResource $operation
        Should -Invoke Save-PSResource -Times 1 -ParameterFilter { $Version -eq '2.0.0-preview.2' -and $IncludeXml -and $Path -eq $operation.StageRoot -and $Quiet }
    }
    It 'reports provider save failures with a stable error id' {
        Mock Save-PSResource { throw 'disk failure' }
        { Save-ProviderResource (Initialize-PMUTestOperation $TestDrive) } | Should -Throw -ErrorId 'PMU.InstallationFailed'
    }
}

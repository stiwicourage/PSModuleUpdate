BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module PowerShellGet -RequiredVersion 2.2.5
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
    function Assert-NativeProviderContext {
    }
}
Describe 'Save-ProviderResource' -Tag 'PMU', 'PMUNativeAdapter' {
    BeforeEach {
        Mock Save-PSResource {}
        Mock Assert-NativeProviderContext {}
    }
    It 'saves exact target into staging with source metadata but no execution' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Mock Save-Module {}
        Save-ProviderResource $operation
        Should -Invoke Save-Module -Times 1 -ParameterFilter {
            $RequiredVersion -ceq '2.0.0-preview.2' -and $AllowPrerelease -and
            $Path -ceq $operation.StageRoot -and $AcceptLicense -and
            $Repository -ceq (Get-OperationRepositoryName $operation)
        }
    }
    It 'reports provider save failures with a stable error id' {
        Mock Save-Module { throw 'disk failure' }
        { Save-ProviderResource (Initialize-PMUTestOperation $TestDrive) } | Should -Throw -ErrorId 'PMU.InstallationFailed'
    }
}

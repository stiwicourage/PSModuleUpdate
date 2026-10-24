BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-ModuleReferenceIdentity' -Tag 'PMU', 'PMUActualActive' {
    Context 'Installed target reference is not session active state' {
        It 'rejects a changed manifest GUID even with identical name and numeric version' {
            $path = Initialize-PMUTestPackage $TestDrive '2.0.0-preview.1'
            $reference = Get-Module -ListAvailable "$path/FixtureModule.psd1"
            $null = Initialize-PMUTestPackage $TestDrive '2.0.0-preview.1' ([guid]::NewGuid())
            { Get-ModuleReferenceIdentity $reference } | Should -Throw -ErrorId 'PMU.ModuleIdentityMismatch'
        }
    }
    It 'rejects a module reference whose name is not a literal module identity' {
        $reference = New-Module -Name 'bad name' -ScriptBlock { }
        { Get-ModuleReferenceIdentity $reference } | Should -Throw -ErrorId 'PMU.InvalidRequest'
    }
}

BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Assert-SurvivingManifestProperty' -Tag 'PMU' {
    It 'skips falsey surviving values: <Actual>' -TestCases @(
        @{
            Actual = $null
        }
        @{
            Actual = ''
        }
        @{
            Actual = $false
        }
        @{
            Actual = 0
        }
    ) {
        param($Actual)
        @(Assert-SurvivingManifestProperty $Actual 'expected' 'PMU.GuidMismatch').Count | Should -Be 0
    }
    It 'compares stringified identity case-insensitively: <Actual>' -TestCases @(
        @{
            Actual = 'ABC'
            Expected = 'abc'
        }
        @{
            Actual = [version]'2.0.0'
            Expected = '2.0.0'
        }
    ) {
        param($Actual, $Expected)
        @(Assert-SurvivingManifestProperty $Actual $Expected 'PMU.GuidMismatch').Count | Should -Be 0
    }
    It 'preserves the field-specific refusal: <ErrorId>' -TestCases @(
        @{
            ErrorId = 'PMU.GuidMismatch'
        }
        @{
            ErrorId = 'PMU.ModuleIdentityMismatch'
        }
    ) {
        param($ErrorId)
        { Assert-SurvivingManifestProperty 'unexpected' 'expected' $ErrorId } | Should -Throw -ErrorId $ErrorId -ExpectedMessage 'Recovery refuses to delete an installation with an unexpected manifest identity.'
    }
}

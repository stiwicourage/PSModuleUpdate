BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Invoke-TargetManifestInspection' -Tag 'PMU', 'PMUTargetManifest' {
    It 'does not publish a success result when workspace cleanup fails' {
        $operation = ConvertTo-ManifestInspectionOperation (Initialize-PMUTestOperation $TestDrive)
        Mock Invoke-RepositoryManifestInspection {
            'candidate'
        }
        Mock Clear-ManifestInspection {
            Write-PMUError 'PMU.RecoveryRequired' 'Cleanup failed.'
        }
        $output = [Collections.Generic.List[object]]::new()
        {
            Invoke-TargetManifestInspection $operation | ForEach-Object {
                $output.Add($_)
            }
        } | Should -Throw -ErrorId PMU.RecoveryRequired
        $output.Count | Should -Be 0
    }
    Context 'Workspace lifetime' {
        BeforeEach {
            $operation = ConvertTo-ManifestInspectionOperation (Initialize-PMUTestOperation $TestDrive)
            $operation.Credential = [pscredential]::new('fixture', [securestring]::new())
            $phases = [Collections.Generic.List[string]]::new()
            Mock Write-InstallationPhase { $phases.Add($Phase) }
        }
        It 'publishes the candidate after removing the owned inspection workspace and credential' {
            $candidate = [pscustomobject]@{ Version = '2.0.0' }
            Mock Invoke-RepositoryManifestInspection { $candidate }
            $result = Invoke-TargetManifestInspection $operation
            [object]::ReferenceEquals($result, $candidate) | Should -BeTrue
            Test-Path -LiteralPath $operation.WorkRoot | Should -BeFalse
            $operation.Credential | Should -BeNullOrEmpty
            @($phases) | Should -Be @('Checking', 'Completed')
        }
        It 'preserves an inspection failure while cleaning the workspace and credential' {
            Mock Invoke-RepositoryManifestInspection { throw [IO.IOException]::new('Inspection failed.') }
            { Invoke-TargetManifestInspection $operation } | Should -Throw -ExpectedMessage 'Inspection failed.'
            Test-Path -LiteralPath $operation.WorkRoot | Should -BeFalse
            $operation.Credential | Should -BeNullOrEmpty
            @($phases) | Should -Be @('Checking', 'Completed')
        }
    }
}

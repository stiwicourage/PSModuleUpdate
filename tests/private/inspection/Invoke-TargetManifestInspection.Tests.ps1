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
}

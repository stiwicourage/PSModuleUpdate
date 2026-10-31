BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Write-ManifestInspectionError' -Tag 'PMU', 'PMUTargetManifest' {
    It 'withholds arbitrary diagnostics including inner exceptions' {
        try {
            throw [InvalidOperationException]::new('fixture-secret')
        } catch {
            $failure = $_
        }
        try {
            Write-ManifestInspectionError $failure
        } catch {
            $safe = $_
        }
        $safe.FullyQualifiedErrorId | Should -Be PMU.InstallationFailed
        ($safe | Out-String) | Should -Not -Match fixture-secret
        $safe.Exception.InnerException | Should -BeNullOrEmpty
    }
    It 'preserves a safe PMU error without replacing its identifier' {
        try {
            Write-PMUError 'PMU.RepositoryTrustRequired' 'Explicit approval required.'
        } catch {
            $failure = $_
        }
        {
            Write-ManifestInspectionError $failure
        } | Should -Throw -ErrorId PMU.RepositoryTrustRequired
    }
}

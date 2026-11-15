BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Initialize-ManifestInspection' -Tag 'PMU', 'PMUTargetManifest' {
    It 'checks consent before creating an inspection workspace' {
        Mock Initialize-InstallationRequest {
            [pscustomobject]@{
                Consent = $Consent
            }
        }
        Mock Assert-InstallationConsent {
            Write-PMUError 'PMU.RepositoryTrustRequired' 'Approval required.'
        }
        Mock ConvertTo-ManifestInspectionOperation {
        }
        {
            Initialize-ManifestInspection ([pscustomobject]@{
                }) $null $false $false
        } | Should -Throw -ErrorId PMU.RepositoryTrustRequired
        Should -Invoke ConvertTo-ManifestInspectionOperation -Times 0
    }
    It 'creates an isolated inspection operation after forwarding explicitly accepted consent' {
        $request = Initialize-PMUTestOperation $TestDrive
        $expectedCredential = [pscredential]::new('fixture', [securestring]::new())
        Mock Initialize-InstallationRequest { $request }
        Mock Assert-InstallationConsent {}
        $inspection = Initialize-ManifestInspection $request.Plan $expectedCredential $true $true
        [object]::ReferenceEquals($inspection, $request) | Should -BeTrue
        $inspection.Journal.TransactionId | Should -Match '^[a-f0-9]{32}$'
        $inspection.WorkRoot | Should -BeExactly (Join-Path $inspection.DataRoot "inspection-$($inspection.Journal.TransactionId)")
        Test-Path -LiteralPath $inspection.WorkRoot | Should -BeFalse
        Should -Invoke Initialize-InstallationRequest -Times 1 -Exactly -ParameterFilter {
            $Consent.AcceptLicense -and $Consent.TrustRepository -and
            [object]::ReferenceEquals($Credential, $expectedCredential)
        }
        Should -Invoke Assert-InstallationConsent -Times 1 -Exactly
    }
}

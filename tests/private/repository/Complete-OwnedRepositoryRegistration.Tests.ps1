BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Complete-OwnedRepositoryRegistration' -Tag 'PMU', 'PMUStructuralRefinement' {
    BeforeEach {
        $fixture = Initialize-PMUUriFixture $TestDrive
        Initialize-ControlledDirectory $fixture.Root
        $receipt = ConvertTo-RepositoryReceipt $fixture.Source
        $script:registrationLease = [pscustomobject]@{
            Name = $receipt.RegistrationName
            Root = $fixture.Root
            Receipt = $receipt
            Source = $fixture.Source
            ReceiptPath = Write-RepositoryReceipt $receipt $fixture.Root
        }
        $script:createdRegistration = [pscustomobject]@{
            Name = $receipt.RegistrationName
            Uri = $fixture.Source.Uri
            ApiVersion = 'V3'
            Trusted = $false
            Priority = 50
        }
        $script:verifiedRegistration = $createdRegistration.PSObject.Copy()
        Mock Get-RepositoryRegistration { $script:verifiedRegistration }
    }
    It 'durably binds the resolved API before accepting the verified registration' {
        Complete-OwnedRepositoryRegistration $registrationLease @($createdRegistration)
        $registrationLease.Source.ApiVersion | Should -BeExactly 'V3'
        $persisted = Get-Content -LiteralPath $registrationLease.ReceiptPath -Raw | ConvertFrom-Json
        $persisted.ApiVersion | Should -BeExactly 'V3'
        $persisted.RegistrationName | Should -BeExactly $createdRegistration.Name
        $persisted.Trusted | Should -BeFalse
    }
    It 'does not bind a provider result containing <Count> registrations' -ForEach @(
        @{ Count = 0 }
        @{ Count = 2 }
    ) {
        $created = @($createdRegistration) * $Count
        { Complete-OwnedRepositoryRegistration $registrationLease $created } |
            Should -Throw -ErrorId 'PMU.RepositoryUnavailable'
        $persisted = Get-Content -LiteralPath $registrationLease.ReceiptPath -Raw | ConvertFrom-Json
        $persisted.ApiVersion | Should -BeExactly 'Unknown'
    }
    It 'retains the bound ownership receipt when fresh verification finds no registration' {
        $script:verifiedRegistration = @()
        { Complete-OwnedRepositoryRegistration $registrationLease @($createdRegistration) } |
            Should -Throw -ErrorId 'PMU.RepositoryUnavailable'
        $persisted = Get-Content -LiteralPath $registrationLease.ReceiptPath -Raw | ConvertFrom-Json
        $persisted.ApiVersion | Should -BeExactly 'V3'
    }
    It 'rejects a fresh registration whose <Property> differs from the bound identity' -ForEach @(
        @{ Property = 'Name'; ChangedValue = 'OtherRegistration' }
        @{ Property = 'Uri'; ChangedValue = 'https://other.invalid/v3/index.json' }
        @{ Property = 'ApiVersion'; ChangedValue = 'V2' }
        @{ Property = 'Trusted'; ChangedValue = $true }
        @{ Property = 'Priority'; ChangedValue = 10 }
    ) {
        $script:verifiedRegistration.$Property = $ChangedValue
        { Complete-OwnedRepositoryRegistration $registrationLease @($createdRegistration) } |
            Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired'
        Test-Path -LiteralPath $registrationLease.ReceiptPath | Should -BeTrue
    }
}

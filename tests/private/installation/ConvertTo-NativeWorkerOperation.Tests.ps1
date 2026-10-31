BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'ConvertTo-NativeWorkerOperation' -Tag 'PMU', 'PMUWorkerContracts' {
    It 'transfers credential identity and inventory without copying the lock or mutating the parent' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $credential = [pscredential]::new('fixture-user', [securestring]::new())
        $operation.Credential = $credential
        $operation.Record | Add-Member InspectedManifestHash ('a' * 64)
        $snapshot = [pscustomobject]@{ Source = [pscustomobject]@{ Name = 'ApprovedFeed' } }
        Mock Get-NativeProviderRoot { 'owned-root' }
        Mock Resolve-ModuleInstallationRoot { 'module-root' }

        $copy = ConvertTo-NativeWorkerOperation $operation $snapshot

        [object]::ReferenceEquals($copy.Credential, $credential) | Should -BeTrue
        [object]::ReferenceEquals($copy.Plan, $operation.Plan) | Should -BeTrue
        [object]::ReferenceEquals($copy.Record, $operation.Record) | Should -BeFalse
        @($copy.Record.InstalledTree) | Should -Be @($operation.Record.InstalledTree)
        $copy.Record.InspectedManifestHash | Should -BeExactly ('a' * 64)
        $copy.PSObject.Properties.Name | Should -Not -Contain 'Lock'
        $operation.PSObject.Properties.Name | Should -Not -Contain 'NativeContext'
        $copy.RepositoryName | Should -BeExactly 'ApprovedFeed'
        $copy.NativeContext.Root | Should -BeExactly 'owned-root'
        $copy.NativeContext.CurrentUserRoot | Should -BeExactly 'module-root'
        $copy.NativeContext.Paths | Should -BeNullOrEmpty
    }
}

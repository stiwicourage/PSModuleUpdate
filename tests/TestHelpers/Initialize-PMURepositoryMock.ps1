function Initialize-PMURepositoryMock {
    Mock Resolve-ModuleInstallationRoot { if ($Scope -eq 'CurrentUser') { $script:repositoryFixture.Modules } else { "$($script:repositoryFixture.Root)/Other" } }
    Mock Resolve-PMUDataRoot { $script:repositoryFixture.Data }
    Mock Get-ProviderContext { [pscustomobject]@{ Name = 'Microsoft.PowerShell.PSResourceGet'; Version = [version]'1.2.0' } }
    Mock Get-PSResourceRepository {
        if ($Name) { return $script:repositoryFixture.Repositories.Values | Where-Object Name -EQ $Name[0] }
        $script:repositoryFixture.Repositories.Values
    }
    Mock Register-PSResourceRepository { throw 'Production registration writes are prohibited.' }
    Mock Unregister-PSResourceRepository { throw 'Production registration writes are prohibited.' }
}

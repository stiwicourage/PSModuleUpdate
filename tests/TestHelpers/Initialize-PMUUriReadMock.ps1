function Initialize-PMUUriReadMock {
    Mock Get-PSResourceRepository {
        if ($Name) { return @($script:uriFixture.Entries.Values | Where-Object Name -EQ $Name[0]) }
        @($script:uriFixture.Entries.Values)
    }
}

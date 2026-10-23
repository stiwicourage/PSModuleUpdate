function Initialize-PMUUriUnregisterMock {
    Mock Unregister-PSResourceRepository {
        $script:uriFixture.Events.Add("Unregister:$($Name[0])")
        $script:uriFixture.Entries.Remove($Name[0])
    }
}

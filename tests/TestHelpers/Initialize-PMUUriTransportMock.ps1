function Initialize-PMUUriTransportMock {
    param([string]$Root)
    $script:uriFixture = Initialize-PMUUriFixture $Root
    Mock Resolve-RepositoryTransportRoot { $script:uriFixture.Root }
    Initialize-PMUUriReadMock
    Initialize-PMUUriRegisterMock
    Initialize-PMUUriUnregisterMock
}

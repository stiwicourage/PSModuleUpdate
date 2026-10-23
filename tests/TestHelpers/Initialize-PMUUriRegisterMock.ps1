function Initialize-PMUUriRegisterMock {
    Mock Register-PSResourceRepository {
        param($Name, $Uri, $ApiVersion = 'V3', $Priority, [switch]$Trusted, [switch]$PassThru)
        if ($script:uriFixture.Entries.ContainsKey($Name)) { throw 'Existing registrations cannot be overwritten.' }
        @(Get-ChildItem $script:uriFixture.Root -Filter '*.json' -Recurse).Count | Should -BeGreaterThan 0
        $script:uriFixture.Events.Add("Register:$Name")
        $script:uriFixture.Entries[$Name] = [pscustomobject]@{
            Name = $Name; Uri = [uri]$Uri; ApiVersion = "$ApiVersion"; Trusted = [bool]$Trusted; Priority = $Priority
        }
        if ($PassThru) { $script:uriFixture.Entries[$Name] }
    }
}

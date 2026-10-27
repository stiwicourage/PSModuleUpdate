function Initialize-PMUUriFixture {
    param([string]$Root)
    [pscustomobject]@{
        Root = Join-Path $Root ([guid]::NewGuid().ToString('N'))
        Entries = @{}
        Events = [Collections.Generic.List[string]]::new()
        Source = [pscustomobject]@{
            Name = $null
            Uri = 'https://transport.invalid/v3/index.json'
            ApiVersion = 'Unknown'
            Trusted = $false
        }
    }
}

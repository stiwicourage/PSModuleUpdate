function Get-PMURepositoryEntry {
    [ordered]@{
        Public = [pscustomobject]@{
            Name = 'PublicFixture'
            Uri = [uri]'https://public.invalid/v3/index.json'
            ApiVersion = 'V3'
            Trusted = $true
        }
        Private = [pscustomobject]@{
            Name = 'PrivateFixture'
            Uri = [uri]'https://private.invalid/v3/index.json'
            ApiVersion = 'V3'
            Trusted = $false
        }
    }
}

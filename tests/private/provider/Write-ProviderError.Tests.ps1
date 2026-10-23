BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/src/private/shared/Write-PMUError.ps1"
    . "$root/src/private/provider/Write-ProviderError.ps1"
}
Describe 'Write-ProviderError' -Tag 'PMU' {
    It 'maps authentication without disclosing provider secrets' {
        try { throw '401 secret-token-fixture' } catch { $failure = $_ }
        try { Write-ProviderError $failure 'PMU.DiscoveryFailed' }
        catch {
            $_.FullyQualifiedErrorId | Should -Be 'PMU.AuthenticationFailed'
            ($_ | Out-String) | Should -Not -Match 'secret-token-fixture'
        }
    }
}

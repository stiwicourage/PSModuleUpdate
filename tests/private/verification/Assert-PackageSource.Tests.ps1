BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-PackageSource' -Tag 'PMU' {
    It 'canonicalizes an absolute native file source without rewriting metadata' -Tag 'PMUNative' {
        $directory = Join-Path $TestDrive 'package'
        $null = New-Item $directory -ItemType Directory
        $source = Join-Path $TestDrive 'feed # space%25'
        $metadata = Join-Path $directory 'PSGetModuleInfo.xml'
        [pscustomobject]@{ RepositorySourceLocation = $source } | Export-Clixml $metadata
        $before = (Get-FileHash $metadata).Hash
        $plan = @{ RepositoryUri = [uri]::new($source, [UriKind]::Absolute).AbsoluteUri }
        { Assert-PackageSource $directory $plan } | Should -Not -Throw
        (Get-FileHash $metadata).Hash | Should -BeExactly $before
        $plan.RepositoryUri = [uri]::new((Join-Path $TestDrive 'other'), [UriKind]::Absolute).AbsoluteUri
        { Assert-PackageSource $directory $plan } | Should -Throw -ErrorId 'PMU.VerificationFailed'
    }
    It 'rejects available provider metadata pointing at another feed' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $directory = Split-Path -Parent $operation.Plan.InstalledManifestPath
        [pscustomobject]@{ RepositorySourceLocation = 'https://other.invalid/feed' } | Export-Clixml "$directory/PSGetModuleInfo.xml"
        { Assert-PackageSource $directory $operation.Plan } | Should -Throw -ErrorId 'PMU.VerificationFailed'
    }
}

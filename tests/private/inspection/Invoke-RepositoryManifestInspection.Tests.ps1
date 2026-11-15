BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Invoke-RepositoryManifestInspection' -Tag 'PMU', 'PMUTargetManifest' {
    It 'closes the exact temporary transport on <Outcome>' -ForEach @(
        @{
            Outcome = 'success'
        }
        @{
            Outcome = 'failure'
        }
    ) {
        $operation = Initialize-PMUTestOperation $TestDrive
        $script:lease = [pscustomobject]@{
            Name = 'owned'
            ReceiptPath = 'fixture'
        }
        Mock Open-RepositoryTransport {
            $script:lease
        }
        Mock Get-BoundTargetManifest {
            if ($Outcome -eq 'failure') {
                Write-PMUError 'PMU.PackageNotFound' 'Missing candidate.'
            }
            'candidate'
        }
        Mock Close-RepositoryTransport {
        }
        if ($Outcome -eq 'failure') {
            {
                Invoke-RepositoryManifestInspection $operation
            } | Should -Throw -ErrorId PMU.PackageNotFound
        } else {
            Invoke-RepositoryManifestInspection $operation | Should -Be candidate
        }
        $operation.RepositoryName | Should -Be owned
        Should -Invoke Close-RepositoryTransport -Times 1 -Exactly -ParameterFilter {
            [object]::ReferenceEquals($Lease, $script:lease)
        }
    }
}

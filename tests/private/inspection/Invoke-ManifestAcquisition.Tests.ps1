BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Invoke-ManifestAcquisition' -Tag 'PMU', 'PMUTargetManifest' {
    It 'rejects <Instances> built module instances' -ForEach @(
        @{
            Instances = 0
        }
        @{
            Instances = 2
        }
    ) {
        Mock Invoke-ManifestWorkerProcess {
        }
        Mock Get-Module {
            @(@([pscustomobject]@{
                        Path = 'a'
                    }, [pscustomobject]@{
                        Path = 'b'
                    }) | Select-Object -First $Instances)
        }
        {
            Invoke-ManifestAcquisition ([pscustomobject]@{
                })
        } | Should -Throw -ErrorId PMU.UnsupportedProviderBehavior
        Should -Invoke Invoke-ManifestWorkerProcess -Times 0
    }
    It 'transfers only an inspection context to the isolated worker' {
        $operation = ConvertTo-ManifestInspectionOperation (Initialize-PMUTestOperation $TestDrive)
        $operation.RepositoryName = 'owned'
        Mock Get-Module {
            [pscustomobject]@{
                Path = 'built.psm1'
            }
        }
        Mock Resolve-ModuleInstallationRoot {
            'fixture-root'
        }
        Mock Invoke-ManifestWorkerProcess {
        }
        Invoke-ManifestAcquisition $operation
        Should -Invoke Invoke-ManifestWorkerProcess -Times 1 -ParameterFilter {
            $Context.InspectManifest -and $Context.ModulePath -eq 'built.psm1' -and $Context.Operation.RepositoryName -eq 'owned'
        }
    }
}

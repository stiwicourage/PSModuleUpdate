BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module PowerShellGet -RequiredVersion 2.2.5
    $script:initializeStore = ${function:Initialize-NativeRepositoryStore}
    $script:getSnapshot = ${function:Get-NativeRepositorySnapshot}
}

Describe 'Initialize-NativeRepository' -Tag 'PMURepositoryCharacterization' {
    BeforeEach {
        $script:operation = [pscustomobject]@{
            RepositoryName = 'ApprovedFeed'
            Plan = [pscustomobject]@{ RepositoryTrusted = $false }
            Consent = [pscustomobject]@{ TrustRepository = $true }
        }
        $script:repository = [pscustomobject]@{
            Name = 'ApprovedFeed'
            InstallationPolicy = 'Untrusted'
        }
        Mock Initialize-NativeRepositoryStore { $false }
        Mock Register-NativeRepository {}
        Mock Get-NativeRepositorySnapshot { $script:repository }
        Mock PowerShellGet\Set-PSRepository {
            $script:repository.InstallationPolicy = 'Trusted'
        }
    }

    It 'registers a missing approved source and establishes trusted binding without returning native output' {
        @(Initialize-NativeRepository $operation).Count | Should -Be 0

        $repository.InstallationPolicy | Should -BeExactly 'Trusted'
        Should -Invoke Register-NativeRepository -Times 1 -Exactly -ParameterFilter {
            [object]::ReferenceEquals($Operation, $script:operation)
        }
        Should -Invoke PowerShellGet\Set-PSRepository -Times 1 -Exactly -ParameterFilter {
            $Name -ceq 'ApprovedFeed' -and
            $InstallationPolicy -ceq 'Trusted' -and
            $ErrorAction -eq 'Stop'
        }
    }

    It 'reuses an approved existing registration without registering it again' {
        Mock Initialize-NativeRepositoryStore { $true }

        Initialize-NativeRepository $operation

        Should -Invoke Register-NativeRepository -Times 0 -Exactly
        $repository.InstallationPolicy | Should -BeExactly 'Trusted'
    }

    It 'accepts prior repository trust without demanding fresh consent' {
        $operation.Plan.RepositoryTrusted = $true
        $operation.Consent.TrustRepository = $false

        Initialize-NativeRepository $operation

        $repository.InstallationPolicy | Should -BeExactly 'Trusted'
    }

    It 'rejects absent independent trust approval before touching the native store' {
        $operation.Consent.TrustRepository = $false

        { Initialize-NativeRepository $operation } |
            Should -Throw -ErrorId 'PMU.RepositoryTrustRequired'

        Should -Invoke Initialize-NativeRepositoryStore -Times 0 -Exactly
        Should -Invoke Register-NativeRepository -Times 0 -Exactly
        Should -Invoke PowerShellGet\Set-PSRepository -Times 0 -Exactly
    }

    It 'does not trust a source whose pre-trust snapshot fails validation' {
        Mock Get-NativeRepositorySnapshot {
            Write-PMUError 'PMU.SourceMismatch' 'The source no longer matches.'
        }

        { Initialize-NativeRepository $operation } |
            Should -Throw -ErrorId 'PMU.SourceMismatch'

        Should -Invoke PowerShellGet\Set-PSRepository -Times 0 -Exactly
        $repository.InstallationPolicy | Should -BeExactly 'Untrusted'
    }

    It 'rejects a trust update that leaves the final binding untrusted' {
        Mock PowerShellGet\Set-PSRepository {}

        { Initialize-NativeRepository $operation } |
            Should -Throw -ErrorId 'PMU.RepositoryChanged'

        $repository.InstallationPolicy | Should -BeExactly 'Untrusted'
    }

    It 'removes defaults populated during registration before validating and trusting the approved source' {
        $operation.Plan | Add-Member RepositoryUri 'https://feed.example.invalid/approved'
        $repository | Add-Member SourceLocation $operation.Plan.RepositoryUri
        $script:nativeSources = @()
        Mock Assert-NativeProviderPath {}
        Mock Get-NativeProviderPath {}
        Mock Initialize-NativeRepositoryStore { & $script:initializeStore $Operation }
        Mock Get-NativeRepositorySnapshot { & $script:getSnapshot $Operation }
        Mock PowerShellGet\Get-PSRepository { $script:nativeSources }
        Mock Register-NativeRepository {
            $script:nativeSources = @(
                [pscustomobject]@{ Name = 'PSGallery' }
                $script:repository
            )
        }
        Mock PowerShellGet\Unregister-PSRepository {
            $script:nativeSources = @($script:nativeSources | Where-Object Name -NE $Name)
        }

        @(Initialize-NativeRepository $operation).Count | Should -Be 0

        @($nativeSources.Name) | Should -Be @('ApprovedFeed')
        $repository.InstallationPolicy | Should -BeExactly 'Trusted'
        Should -Invoke PowerShellGet\Unregister-PSRepository -Times 1 -Exactly -ParameterFilter {
            $Name -ceq 'PSGallery' -and $ErrorAction -eq 'Stop'
        }
        Should -Invoke PowerShellGet\Set-PSRepository -Times 1 -Exactly -ParameterFilter {
            $Name -ceq 'ApprovedFeed'
        }
    }

    It 'propagates a post-registration store failure before granting trust' {
        $script:storeReads = 0
        Mock Initialize-NativeRepositoryStore {
            $script:storeReads++
            if ($script:storeReads -eq 1) {
                return $false
            }
            Write-PMUError 'PMU.RepositoryChanged' 'The owned store could not be normalized.'
        }

        { Initialize-NativeRepository $operation } | Should -Throw -ErrorId 'PMU.RepositoryChanged'

        Should -Invoke PowerShellGet\Set-PSRepository -Times 0 -Exactly
        $repository.InstallationPolicy | Should -BeExactly 'Untrusted'
    }
}

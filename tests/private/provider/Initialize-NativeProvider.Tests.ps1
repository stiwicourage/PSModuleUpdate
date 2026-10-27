BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Initialize-NativeProvider' -Tag 'PMU', 'PMUProviderContracts' {
    BeforeEach {
        $script:operation = [pscustomobject]@{
            NativeContext = [pscustomobject]@{ Paths = $null }
        }
        $script:providerPaths = [pscustomobject]@{ Marker = 'qualified-owned-paths' }
        Mock Import-Module {}
        Mock Get-NativeProviderPath { $script:providerPaths }
        Mock Assert-NativeProviderPath {}
        Mock Assert-NativeNuGetProvider {}
        Mock Initialize-NativeRepository {}
        Mock Assert-NativeProviderContext {}
    }

    It 'loads qualified runtime modules before binding the operation-owned provider context' {
        Initialize-NativeProvider $operation
        $operation.NativeContext.Paths.Marker | Should -BeExactly 'qualified-owned-paths'
        Should -Invoke Import-Module -Times 1 -Exactly -ParameterFilter {
            $Name -ceq (Join-Path $PSHOME 'Modules/PackageManagement/PackageManagement.psd1') -and
            $RequiredVersion -eq [version]'1.4.8.1'
        }
        Should -Invoke Import-Module -Times 1 -Exactly -ParameterFilter {
            $Name -ceq (Join-Path $PSHOME 'Modules/PowerShellGet/PowerShellGet.psd1') -and
            $RequiredVersion -eq [version]'2.2.5'
        }
        Should -Invoke Assert-NativeProviderContext -Times 1 -Exactly
    }

    It 'does not bind paths or register a source when provider-path validation fails' {
        Mock Assert-NativeProviderPath {
            Write-PMUError 'PMU.UnsupportedProviderBehavior' 'Provider paths escaped the owned root.'
        }
        { Initialize-NativeProvider $operation } | Should -Throw -ErrorId 'PMU.UnsupportedProviderBehavior'
        $operation.NativeContext.Paths | Should -BeNullOrEmpty
        Should -Invoke Initialize-NativeRepository -Times 0
    }

    It 'does not register a source when the NuGet provider is unqualified' {
        Mock Assert-NativeNuGetProvider {
            Write-PMUError 'PMU.UnsupportedProviderBehavior' 'The provider is unqualified.'
        }
        { Initialize-NativeProvider $operation } | Should -Throw -ErrorId 'PMU.UnsupportedProviderBehavior'
        Should -Invoke Initialize-NativeRepository -Times 0
    }

    It 'does not certify a context whose repository setup failed' {
        Mock Initialize-NativeRepository {
            Write-PMUError 'PMU.SourceMismatch' 'The approved registration changed.'
        }
        { Initialize-NativeProvider $operation } | Should -Throw -ErrorId 'PMU.SourceMismatch'
        Should -Invoke Assert-NativeProviderContext -Times 0
    }
}

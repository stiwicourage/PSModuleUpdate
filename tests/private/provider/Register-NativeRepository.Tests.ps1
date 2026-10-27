BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module PowerShellGet -RequiredVersion 2.2.5
}

Describe 'Register-NativeRepository' -Tag 'PMURepositoryCharacterization' {
    BeforeEach {
        $script:operation = [pscustomobject]@{
            RepositoryName = 'ApprovedFeed'
            Plan = [pscustomobject]@{ RepositoryUri = 'https://feed.example.invalid/approved' }
            Credential = $null
        }
        Mock PowerShellGet\Register-PSRepository { 'native registration output' }
    }

    It 'forwards only the approved <Kind> source and original credential with untrusted policy' -ForEach @(
        @{ Kind = 'HTTPS' }
        @{ Kind = 'file' }
    ) {
        $script:expectedLocation = $operation.Plan.RepositoryUri
        if ($Kind -eq 'file') {
            $script:expectedLocation = Join-Path $TestDrive 'approved feed # percent%'
            $operation.Plan.RepositoryUri = ([uri]::new($expectedLocation)).AbsoluteUri
        }
        $password = [Security.SecureString]::new()
        $operation.Credential = [pscredential]::new('fixture-user', $password)

        @(Register-NativeRepository $operation).Count | Should -Be 0

        Should -Invoke PowerShellGet\Register-PSRepository -Times 1 -Exactly -ParameterFilter {
            $Name -ceq 'ApprovedFeed' -and
            $SourceLocation -ceq $script:expectedLocation -and
            $InstallationPolicy -ceq 'Untrusted' -and
            [object]::ReferenceEquals($Credential, $script:operation.Credential) -and
            $ErrorAction -eq 'Stop' -and -not $Default
        }
    }

    It 'registers an anonymous approved source without introducing a credential' {
        Register-NativeRepository $operation

        Should -Invoke PowerShellGet\Register-PSRepository -Times 1 -Exactly -ParameterFilter {
            $Name -ceq 'ApprovedFeed' -and
            $SourceLocation -ceq 'https://feed.example.invalid/approved' -and
            $InstallationPolicy -ceq 'Untrusted' -and
            $null -eq $Credential
        }
    }

    It 'uses native default registration for PSGallery without forwarding custom source or credentials' {
        # Pester's proxy declares an empty SourceLocation even when -Default omits it.
        # Preserve the native absent-source branch without probing provider state.
        Mock Get-Variable { $null } -ModuleName PowerShellGet -ParameterFilter {
            $Name -eq 'SourceLocation'
        }
        $operation.RepositoryName = 'psgallery'
        $password = [Security.SecureString]::new()
        $operation.Credential = [pscredential]::new('fixture-user', $password)

        @(Register-NativeRepository $operation).Count | Should -Be 0

        Should -Invoke PowerShellGet\Register-PSRepository -Times 1 -Exactly -ParameterFilter {
            $Default -and $ErrorAction -eq 'Stop' -and
            -not $Name -and -not $SourceLocation -and $null -eq $Credential
        }
    }

    It 'propagates native registration failure without reporting successful registration' {
        Mock PowerShellGet\Register-PSRepository { throw 'registration denied' }

        { Register-NativeRepository $operation } | Should -Throw '*registration denied*'
    }

    It 'rejects an invalid source URI before native registration' {
        $operation.Plan.RepositoryUri = 'http://['

        { Register-NativeRepository $operation } | Should -Throw

        Should -Invoke PowerShellGet\Register-PSRepository -Times 0 -Exactly
    }
}

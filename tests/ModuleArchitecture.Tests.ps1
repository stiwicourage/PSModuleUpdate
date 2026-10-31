Describe 'PMU architecture' -Tag 'PMU' {
    BeforeAll {
        $root = Split-Path -Parent $PSScriptRoot
        $script:files = @(Get-ChildItem "$root/src" -Filter '*.ps1' -Recurse)
    }
    It 'has exactly the approved public command files' {
        @(Get-ChildItem "$root/src/public" -Filter '*.ps1').BaseName |
            Sort-Object | Should -Be @('Get-PSModuleUpdate', 'Get-PSModuleUpdateTargetManifest', 'Install-PSModuleUpdate')
    }
    It 'uses one matching top-level function per source file and no nested functions' {
        $files.Count | Should -BeGreaterThan 0
        foreach ($file in $files) {
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
            $errors.Count | Should -Be 0
            $functions = @($ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true))
            $functions.Count | Should -Be 1
            $functions[0].Name | Should -Be $file.BaseName
        }
    }
    It 'does not bootstrap or hot reload and confines registration writes to owned transport adapters' {
        foreach ($file in $files) {
            $text = Get-Content $file.FullName -Raw
            $text | Should -Not -Match '(?i)\b(Set-PSResourceRepository|Remove-Module|Install-Module)\b'
            if ($text -match '\bUpdate-Module\b') {
                $file.BaseName | Should -Be 'Install-ProviderResource'
            }
            if ($file.Directory.Name -eq 'provider') {
                $text | Should -Not -Match '(?i)\bForce\b'
            }
            if ($text -match '\bRegister-PSResourceRepository\b') {
                $file.BaseName | Should -Be 'Register-OwnedRepository'
                $text | Should -Not -Match '(?i)\b(Force|CredentialInfo|Trusted)\b'
            }
            if ($text -match '\bUnregister-PSResourceRepository\b') {
                $file.BaseName | Should -Be 'Clear-OwnedRepositoryReceipt'
            }
        }
    }
    It 'applies updates only through the native Update-Module adapter' -Tag 'PMUNativeAdapter' {
        $adapter = Get-Content "$root/src/private/provider/Install-ProviderResource.ps1" -Raw
        $adapter | Should -Match 'PowerShellGet\\Update-Module'
        $adapter | Should -Not -Match '\bInstall-PSResource\b'
    }
    It 'has a source-mirrored test for every production helper and public command' {
        foreach ($file in $files) {
            $relative = [IO.Path]::GetRelativePath("$root/src", $file.FullName)
            $test = Join-Path "$root/tests" ($relative -replace '\.ps1$', '.Tests.ps1')
            Test-Path -LiteralPath $test | Should -BeTrue -Because $relative
        }
    }
    It 'keeps provider transport and platform environment access behind their adapters' {
        foreach ($file in $files) {
            $text = Get-Content $file.FullName -Raw
            if ($text -match 'Microsoft.PowerShell.PSResourceGet\\') {
                $file.Directory.Name | Should -BeIn @('provider', 'repository')
            }
            if ($text -match '\$env:|\$HOME\b') {
                $file.Directory.Name | Should -BeIn @('identity', 'locking')
            }
        }
    }
}

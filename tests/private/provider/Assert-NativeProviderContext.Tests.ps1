BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    function Get-NativeProviderPath {
    }
    function Assert-NativeRepositoryBinding {
    }
}
Describe 'Assert-NativeProviderContext' -Tag 'PMU', 'PMUNativeAdapter' {
    BeforeEach {
        $script:guardOperation = Initialize-PMURecoveryFixture $TestDrive
        $root = Join-Path $guardOperation.WorkRoot "native-$($guardOperation.Journal.TransactionId)"
        $script:guardPaths = [pscustomobject]@{
            Store = "$root/cache/repos.xml"
            Settings = "$root/cache/settings.xml"
            Config = "$root/config"
            Temporary = "$root/tmp"
            CurrentUser = $guardOperation.Plan.DestinationRoot
            AllUsers = "$TestDrive/all-users"
        }
        $guardOperation | Add-Member NativeContext ([pscustomobject]@{
                Root = $root
                Paths = $guardPaths.PSObject.Copy()
                CurrentUserRoot = $guardPaths.CurrentUser
            })
        Mock Get-NativeProviderPath { $script:guardPaths }
        Mock Assert-NativeRepositoryBinding {}
    }
    It 'fails closed before native writers when no verified owned provider context exists' {
        $operation = Initialize-PMUTestOperation $TestDrive
        { Assert-NativeProviderContext $operation } | Should -Throw -ErrorId 'PMU.UnsupportedProviderBehavior'
    }
    It 'rejects a provider root outside the original nonce-bound owned transaction' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $operation | Add-Member NativeContext ([pscustomobject]@{ Root = Join-Path $TestDrive 'foreign' })
        { Assert-NativeProviderContext $operation } | Should -Throw -ErrorId 'PMU.UnsupportedProviderBehavior'
        Test-Path $operation.BackupPath | Should -BeTrue
    }
    It 'accepts verified owned native paths without changing the selected installation root' {
        Assert-NativeProviderContext $guardOperation
        Should -Invoke Assert-NativeRepositoryBinding -Times 1
    }
    It 'refuses a native writer on an existing-format journal without a transaction nonce' {
        $guardOperation.Journal.PSObject.Properties.Remove('TransactionId')
        { Assert-NativeProviderContext $guardOperation } | Should -Throw -ErrorId 'PMU.UnsupportedProviderBehavior'
    }
    It 'rejects an escaped or changed native provider path before any writer' -ForEach @(
        @{
            Field = 'Store'
            Value = '/foreign/PSRepositories.xml'
        }
        @{
            Field = 'Temporary'
            Value = '/foreign/tmp'
        }
        @{
            Field = 'CurrentUser'
            Value = '/foreign/Modules'
        }
    ) {
        $guardPaths.$Field = $Value
        { Assert-NativeProviderContext $guardOperation } | Should -Throw -ErrorId 'PMU.UnsupportedProviderBehavior'
    }
}

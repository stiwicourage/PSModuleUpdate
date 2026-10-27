BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'ConvertTo-NativeWorkerContext' -Tag 'PMU', 'PMUWorkerContracts' {
    BeforeEach {
        $script:operation = Initialize-PMURecoveryFixture $TestDrive
        $script:snapshot = [pscustomobject]@{
            Source = [pscustomobject]@{ Name = 'ApprovedFeed' }
        }
        $script:modulePath = Join-Path $TestDrive 'PSModuleUpdate.psm1'
        $script:ownedRoot = Join-Path $TestDrive 'native-provider'
        $script:moduleRoot = Join-Path $TestDrive 'Modules'
        Mock Get-Module {
            [pscustomobject]@{ Path = $script:modulePath }
        } -ParameterFilter { $Name -eq 'PSModuleUpdate' }
        Mock Get-NativeProviderRoot { $script:ownedRoot }
        Mock Resolve-ModuleInstallationRoot { $script:moduleRoot }
        Mock Get-RepositoryProcessStart { 'parent-start-identity' }
    }

    It 'copies the approved plan and provider roots without transferring the parent lock' {
        $context = ConvertTo-NativeWorkerContext $operation $snapshot $false
        $context.ModulePath | Should -BeExactly $script:modulePath
        $context.ParentPid | Should -Be $PID
        $context.ParentStarted | Should -BeExactly 'parent-start-identity'
        $context.AlreadyInstalled | Should -BeFalse
        $context.Operation.RepositoryName | Should -BeExactly 'ApprovedFeed'
        $context.Operation.NativeContext.Root | Should -BeExactly $script:ownedRoot
        $context.Operation.NativeContext.CurrentUserRoot | Should -BeExactly $script:moduleRoot
        $context.Operation.Plan.ModuleName | Should -BeExactly 'FixtureModule'
        $context.Operation.Plan.TargetVersion | Should -BeExactly '2.0.0-preview.2'
        $context.Operation.PSObject.Properties.Name | Should -Not -Contain 'Lock'
        $context.Operation.Credential | Should -Be $operation.Credential
    }

    It 'preserves existing-target mode and transaction identity for the worker' {
        $context = ConvertTo-NativeWorkerContext $operation $snapshot $true
        $context.AlreadyInstalled | Should -BeTrue
        $context.Token.TransactionId | Should -BeExactly $operation.Journal.TransactionId
        $context.Snapshot.Source.Name | Should -BeExactly 'ApprovedFeed'
    }

    It 'rejects an unavailable built PMU module' {
        Mock Get-Module {} -ParameterFilter { $Name -eq 'PSModuleUpdate' }
        { ConvertTo-NativeWorkerContext $operation $snapshot $false } |
            Should -Throw -ErrorId 'PMU.UnsupportedProviderBehavior'
    }

    It 'rejects ambiguous built PMU module instances' {
        Mock Get-Module {
            [pscustomobject]@{ Path = $script:modulePath }
            [pscustomobject]@{ Path = $script:modulePath }
        } -ParameterFilter { $Name -eq 'PSModuleUpdate' }
        { ConvertTo-NativeWorkerContext $operation $snapshot $false } |
            Should -Throw -ErrorId 'PMU.UnsupportedProviderBehavior'
    }
}

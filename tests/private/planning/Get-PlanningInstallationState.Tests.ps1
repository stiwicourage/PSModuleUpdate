BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/tests/TestHelpers/Import-PMUTestSource.ps1"
    . "$root/tests/TestHelpers/Initialize-PMUTestPackage.ps1"
}
Describe 'Get-PlanningInstallationState' -Tag 'PMU' {
    It 'allows read-only planning while a Preparation journal has no backup yet' {
        $script:modules = Join-Path $TestDrive 'Modules'
        $path = Initialize-PMUTestPackage $modules '2.0.0-preview.1'
        Mock Resolve-ModuleInstallationRoot { if ($Scope -eq 'CurrentUser') { $script:modules } else { "$TestDrive/Other" } }
        Mock Resolve-PMUDataRoot { "$TestDrive/data" }
        $identity = [pscustomobject]@{ ModuleName = 'FixtureModule'; ModuleGuid = [guid]'a1111111-1111-1111-1111-111111111111'; Scope = 'CurrentUser'; DestinationRoot = $modules; TargetNumericVersion = '2.0.0'; TargetVersion = '2.0.0-preview.2'; InstalledVersion = '2.0.0-preview.1'; TargetInstalledPath = $path }
        $operation = ConvertTo-InstallationOperation $identity $null @{} $null
        Initialize-ControlledDirectory $operation.WorkRoot
        Write-DurableJournal (ConvertTo-RecoveryJournal $operation @())
        $state = Get-PlanningInstallationState 'FixtureModule' 'CurrentUser' $identity.ModuleGuid
        $state.Installed.FullVersion | Should -Be '2.0.0-preview.1'
    }
}

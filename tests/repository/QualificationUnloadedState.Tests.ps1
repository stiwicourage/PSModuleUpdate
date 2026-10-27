BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . "$root/scripts/qualification/QualificationScenario.ps1"
}

Describe 'Unloaded qualification fixture identity' -Tag 'RepositoryQualification' {
    BeforeEach {
        $module = New-Module -Name QualificationUnloadedFixture -ScriptBlock {}
        $script:session = [pscustomobject]@{ Options = @{ SeedVersion = '1.0.0' } }
        $script:plan = [pscustomobject]@{
            ModuleGuid = $module.Guid
            InstalledVersion = '1.0.0'
            Scope = 'CurrentUser'
            ActiveVersion = $null
            ActivePath = $null
            ActiveScope = $null
            UpdateAvailable = $true
            TargetVersion = '1.1.0'
        }
        $script:result = [pscustomobject]@{
            SchemaVersion = 1
            Outcome = 'Installed'
            RestartRequired = $false
            ModuleName = $module.Name
            ActiveVersion = $null
        }
        Mock Get-Module {}
    }

    It 'accepts null actual active state while preserving the supplied installed identity' {
        { Assert-QualificationPlanIdentity $session $module $plan } | Should -Not -Throw
        $plan.InstalledVersion | Should -Be '1.0.0'
        $plan.TargetVersion | Should -Be '1.1.0'
    }

    It 'rejects a fabricated plan <Field> for an unloaded fixture' -TestCases @(
        @{
            Field = 'ActiveVersion'
            Value = '1.0.0'
        }
        @{
            Field = 'ActivePath'
            Value = '/not-a-loaded-module'
        }
        @{
            Field = 'ActiveScope'
            Value = 'CurrentUser'
        }
    ) {
        param(
            $Field,
            $Value
        )

        $plan.$Field = $Value
        { Assert-QualificationPlanIdentity $session $module $plan } | Should -Throw '*unloaded*'
    }

    It 'accepts a verified unloaded result with null ActiveVersion and no optional active path fields' {
        { Assert-QualificationResultStatus $result } | Should -Not -Throw
    }

    It 'rejects a fabricated result <Field> for an unloaded fixture' -TestCases @(
        @{
            Field = 'ActiveVersion'
            Value = '1.0.0'
        }
        @{
            Field = 'ActivePath'
            Value = '/not-a-loaded-module'
        }
        @{
            Field = 'ActiveScope'
            Value = 'CurrentUser'
        }
    ) {
        param(
            $Field,
            $Value
        )

        $result | Add-Member -NotePropertyName $Field -NotePropertyValue $Value -Force
        { Assert-QualificationResultStatus $result } | Should -Throw '*unloaded*'
    }

    It 'preserves the existing plan <Field> guard' -TestCases @(
        @{
            Field = 'ModuleGuid'
            Value = [guid]'11111111-1111-1111-1111-111111111111'
            Message = '*identity*'
        }
        @{
            Field = 'InstalledVersion'
            Value = '0.9.0'
            Message = '*installed version*'
        }
        @{
            Field = 'Scope'
            Value = 'AllUsers'
            Message = '*isolated scope*'
        }
        @{
            Field = 'UpdateAvailable'
            Value = $false
            Message = '*newer target*'
        }
    ) {
        param(
            $Field,
            $Value,
            $Message
        )

        $plan.$Field = $Value
        { Assert-QualificationPlanIdentity $session $module $plan } | Should -Throw $Message
    }

    It 'preserves the no-restart requirement for an unloaded result' {
        $result.RestartRequired = $true
        { Assert-QualificationResultStatus $result } | Should -Throw '*restart*'
    }

    It 'does not mistake empty active metadata for null actual loaded state' {
        $plan.ActiveVersion = ''
        { Assert-QualificationPlanIdentity $session $module $plan } | Should -Throw '*unloaded*'
    }
}

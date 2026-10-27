BeforeAll {
    . "$PSScriptRoot/Get-PMURegistrationSnapshot.ps1"
}

Describe 'Get-PMURegistrationSnapshot identity preservation' -Tag 'PMU', 'PMURegistrationSnapshot' {
    BeforeEach {
        $script:registrations = @('B', 'A') | ForEach-Object {
            [pscustomobject]@{
                Name = $_
                Uri = [uri]"https://$_.example.invalid/"
                Trusted = $false
                Priority = 50
                ApiVersion = 'V2'
            }
        }
        Mock Get-PSResourceRepository { $script:registrations }
        Mock Get-FileHash { [pscustomobject]@{ Hash = 'unchanged-store' } }
    }

    It 'compares identical registrations independently of provider enumeration order' {
        $before = Get-PMURegistrationSnapshot
        [array]::Reverse($script:registrations)

        $after = Get-PMURegistrationSnapshot

        $after.Records | Should -BeExactly $before.Records
    }

    It 'still detects a changed <Field>' -ForEach @(
        @{ Field = 'Uri'; Value = [uri]'https://changed.example.invalid/' }
        @{ Field = 'Trusted'; Value = $true }
        @{ Field = 'Priority'; Value = 10 }
        @{ Field = 'ApiVersion'; Value = 'V3' }
    ) {
        $before = Get-PMURegistrationSnapshot
        $script:registrations[0].$Field = $Value

        $after = Get-PMURegistrationSnapshot

        $after.Records | Should -Not -BeExactly $before.Records
    }
}

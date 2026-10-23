BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    Get-ChildItem "$root/src/private/version" -Filter '*.ps1' | ForEach-Object { . $_.FullName }
    . "$root/src/private/planning/Select-NewestInstallation.ps1"
}
Describe 'Select-NewestInstallation' -Tag 'PMU' {
    It 'chooses by complete version rather than enumeration order' {
        $items = @([pscustomobject]@{ FullVersion = '2.0.0-preview.2' }, [pscustomobject]@{ FullVersion = '2.0.0-preview.10' })
        (Select-NewestInstallation $items).FullVersion | Should -Be '2.0.0-preview.10'
    }
}

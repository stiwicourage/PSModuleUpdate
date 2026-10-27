BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $root 'scripts/build/ci/CiDependencyRoot.ps1')
}

Describe 'Disposable CI dependency ownership' -Tag 'BuildTooling' {
    It 'refuses to adopt or delete an existing directory without an ownership record' {
        $path = Join-Path $TestDrive 'pmu-ci-modules-existing'
        New-Item -ItemType Directory -Path $path | Out-Null
        { New-CiDependencyRoot -Path $path } | Should -Throw '*already exists*'
        { Remove-CiDependencyRoot -Owner @{
                Path = $path
                Token = 'missing'
            } } | Should -Throw
        Test-Path -LiteralPath $path | Should -BeTrue
    }

    It 'removes only the matching owned directory and builds an explicit isolated module path' {
        $owner = New-CiDependencyRoot -Path (Join-Path $TestDrive 'pmu-ci-modules-owned')
        $modulePath = Get-CiIsolatedModulePath -ModuleRoot $owner.Path
        $modulePath.Split([IO.Path]::PathSeparator) | Should -Be @($owner.Path, (Join-Path $PSHOME 'Modules'))
        Remove-CiDependencyRoot -Owner $owner
        Test-Path -LiteralPath $owner.Path | Should -BeFalse
    }

    It 'refuses cleanup when the ownership token changed' {
        $owner = New-CiDependencyRoot -Path (Join-Path $TestDrive 'pmu-ci-modules-token')
        $owner.Token = '0' * 32
        { Remove-CiDependencyRoot -Owner $owner } | Should -Throw '*ownership changed*'
        Test-Path -LiteralPath $owner.Path | Should -BeTrue
    }
}

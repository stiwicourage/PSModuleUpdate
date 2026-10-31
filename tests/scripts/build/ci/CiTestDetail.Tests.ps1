BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $root 'scripts/build/ci/CiTestDetail.ps1')
}

Describe 'Nova detailed output evidence' -Tag 'BuildTooling' {
    It 'retains expanded names, file identities and ANSI-decorated skips from the actual output' {
        $path = Join-Path $TestDrive 'detail.log'
        @(
            "Running tests from '$root/tests/private/locking/Get-WindowsDirectoryDescriptor.Tests.ps1'"
            'Describing Get-WindowsDirectoryDescriptor'
            ' Context Native Windows descriptor'
            "   $([char]27)[33m[!] reads current-user ACL metadata from a disposable directory 1ms (0ms|1ms)$([char]27)[0m"
            '   [+] example with parameter value 2 2ms (1ms|1ms)'
        ) | Set-Content -LiteralPath $path
        $detail = @(Read-CiTestDetail -Path $path)
        $detail | Should -HaveCount 2
        $detail[0].File | Should -Be 'tests/private/locking/Get-WindowsDirectoryDescriptor.Tests.ps1'
        $detail[0].Name | Should -Be 'reads current-user ACL metadata from a disposable directory'
        $detail[1].Name | Should -Be 'example with parameter value 2'
        $detail[0].Result | Should -Be 'Skipped'
    }

    It 'rejects truncated output rather than inventing missing identities from summary counts' {
        $summary = @{
            Total = 2
            Passed = 2
            Failed = 0
            Skipped = 0
        }
        { Assert-CiTestDetail -Summary $summary -Detail @() -OperatingSystem 'macOS' } | Should -Throw
    }

    It 'rejects an unexpected skip even when counts reconcile' {
        $summary = @{
            Total = 1
            Passed = 0
            Failed = 0
            Skipped = 1
        }
        $detail = @(@{
                File = 'tests/example.Tests.ps1'
                Name = 'unexpected'
                Result = 'Skipped'
            })
        { Assert-CiTestDetail -Summary $summary -Detail $detail -OperatingSystem 'macOS' } | Should -Throw '*skip*'
    }

    Context 'Exact-target inspection native fixture' {
        BeforeEach {
            $script:skipSummary = @{
                Total = 1
                Passed = 0
                Failed = 0
                Skipped = 1
            }
            $script:skipDetail = @(@{
                    File = 'tests/public/Get-PSModuleUpdateTargetManifest.Integration.Tests.ps1'
                    Name = 'inspects an offline exact package, rejects changed MinimumGerberVersion, then installs unchanged content'
                    Result = 'Skipped'
                })
        }

        It 'accepts the classified native-fixture skip on <_>' -ForEach @('Windows', 'Linux') {
            $operatingSystem = $_
            {
                Assert-CiTestDetail -Summary $script:skipSummary -Detail $script:skipDetail -OperatingSystem $operatingSystem
            } | Should -Not -Throw
        }

        It 'rejects the same skip on the qualified macOS platform' {
            {
                Assert-CiTestDetail -Summary $script:skipSummary -Detail $script:skipDetail -OperatingSystem 'macOS'
            } | Should -Throw '*Unexpected skip*'
        }

        It 'rejects a different <_> identity even on an excluded platform' -ForEach @('File', 'Name') {
            $script:skipDetail[0][$_] = 'unclassified'
            {
                Assert-CiTestDetail -Summary $script:skipSummary -Detail $script:skipDetail -OperatingSystem 'Windows'
            } | Should -Throw '*Unexpected skip*'
        }
    }
}

BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'ConvertTo-FileTreeEntry' -Tag 'PMU' {
    It 'projects a directory with fixed empty values without hashing it' {
        $directory = Get-Item -LiteralPath $TestDrive
        Mock Get-FileHash {
            throw 'Directories must not be hashed.'
        }

        $entries = @(ConvertTo-FileTreeEntry -Item $directory -RelativePath 'nested/empty')

        $entries.Count | Should -Be 1
        $entries[0] | Should -BeOfType [pscustomobject]
        @($entries[0].PSObject.Properties.Name) | Should -Be @('Path', 'Length', 'SHA256')
        $entries[0].Path | Should -BeExactly 'nested/empty/'
        $entries[0].Length | Should -Be 0
        $entries[0].SHA256 | Should -BeExactly ''
        Should -Invoke Get-FileHash -Times 0 -Exactly
    }

    It 'projects file length and SHA256 using the literal full path' {
        $path = Join-Path $TestDrive 'payload[1].psm1'
        [IO.File]::WriteAllText($path, 'abc')
        $file = Get-Item -LiteralPath $path
        Mock Get-FileHash {
            [pscustomobject]@{
                Hash = 'fixture-sha256'
            }
        }

        $entry = ConvertTo-FileTreeEntry -Item $file -RelativePath 'nested/payload[1].psm1'

        $entry.Path | Should -BeExactly 'nested/payload[1].psm1'
        $entry.Length | Should -Be 3
        $entry.SHA256 | Should -BeExactly 'fixture-sha256'
        Should -Invoke Get-FileHash -Times 1 -Exactly -ParameterFilter {
            $LiteralPath -ceq $file.FullName -and $Algorithm -eq 'SHA256'
        }
    }

    It 'propagates a hash failure without emitting a partial entry' {
        $path = Join-Path $TestDrive 'unreadable.psm1'
        [IO.File]::WriteAllText($path, 'fixture')
        $file = Get-Item -LiteralPath $path
        Mock Get-FileHash {
            throw 'Hash access denied.'
        }

        { ConvertTo-FileTreeEntry -Item $file -RelativePath 'unreadable.psm1' } |
            Should -Throw -ExpectedMessage 'Hash access denied.'
    }
}

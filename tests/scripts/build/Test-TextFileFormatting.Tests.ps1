BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    $script:formattingScript = Join-Path $root 'scripts/build/Test-TextFileFormatting.ps1'
}

Describe 'Formatting script entrypoint' -Tag 'BuildTooling' {
    It 'reports successful validation on the information stream' {
        Set-Content -LiteralPath (Join-Path $TestDrive 'README.md') -Value 'Valid text'
        $records = @(& $script:formattingScript -ProjectRoot $TestDrive 6>&1)
        $records.Count | Should -Be 1
        $records[0] | Should -BeOfType ([System.Management.Automation.InformationRecord])
        $records[0].ToString() | Should -BeLike 'All tracked text files*'
    }

    It 'fails on invalid endings without modifying the source file' {
        $path = Join-Path $TestDrive 'README.md'
        [System.IO.File]::WriteAllText($path, 'Missing newline')
        { & $script:formattingScript -ProjectRoot $TestDrive } | Should -Throw '*ending violations*'
        [System.IO.File]::ReadAllText($path) | Should -BeExactly 'Missing newline'
    }
}

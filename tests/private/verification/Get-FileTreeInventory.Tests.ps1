BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/tests/TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Get-FileTreeInventory' -Tag 'PMU' {
    BeforeEach {
        $tree = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item $tree -ItemType Directory
        [IO.File]::WriteAllText("$tree/code.psm1", 'safe fixture')
    }
    It 'ignores only provider PSGetModuleInfo.xml and detects modifications' {
        $before = @(Get-FileTreeInventory $tree)
        [IO.File]::WriteAllText("$tree/PSGetModuleInfo.xml", 'provider')
        @(Get-FileTreeInventory $tree) | ConvertTo-Json -Compress | Should -Be ($before | ConvertTo-Json -Compress)
        [IO.File]::WriteAllText("$tree/code.psm1", 'changed')
        @(Get-FileTreeInventory $tree) | ConvertTo-Json -Compress | Should -Not -Be ($before | ConvertTo-Json -Compress)
    }
    It 'rejects symbolic links without following them' {
        $null = New-Item "$tree/link" -ItemType SymbolicLink -Target "$tree/code.psm1"
        { Get-FileTreeInventory $tree } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
    }
    It 'records unexpected empty directories as part of the complete tree' {
        $before = @(Get-FileTreeInventory $tree)
        $null = New-Item "$tree/empty" -ItemType Directory
        @(Get-FileTreeInventory $tree).Count | Should -Be ($before.Count + 1)
    }
}

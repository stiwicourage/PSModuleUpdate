BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Initialize-WindowsControlledDirectory' -Tag 'PMU' {
    Context 'Protected Windows state' {
        It 'requires a trusted descriptor before allowing subsequent writes' {
            Mock Get-WindowsDirectoryDescriptor { @{ Owner = 'owner'; Trusted = @('owner'); Access = @() } }
            $path = Join-Path $TestDrive 'owned'
            Initialize-WindowsControlledDirectory $path
            Test-Path $path | Should -BeTrue
            Should -Invoke Get-WindowsDirectoryDescriptor -Times 1
        }
    }
}

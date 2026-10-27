BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Get-NativeWorkerBootstrap' -Tag 'PMU', 'PMUWorkerBootstrap' {
    It 'stops on errors and decodes one stdin line as a UTF8 serialized context' {
        $lines = (Get-NativeWorkerBootstrap) -split '\r?\n'

        $lines.Count | Should -Be 12
        $lines[0..4] | Should -BeExactly @(
            '$ErrorActionPreference = ''Stop'''
            '$encodedContext = [Console]::In.ReadLine()'
            '$contextBytes = [Convert]::FromBase64String($encodedContext)'
            '$serializedContext = [Text.Encoding]::UTF8.GetString($contextBytes)'
            '$context = [Management.Automation.PSSerializer]::Deserialize($serializedContext)'
        )
    }

    It 'imports the requested module and invokes its private worker with the decoded context' {
        $lines = (Get-NativeWorkerBootstrap) -split '\r?\n'

        $lines[5..11] | Should -BeExactly @(
            '$module = Import-Module -Name $context.ModulePath -PassThru'
            ''
            '& $module {'
            '    param($workerContext)'
            ''
            '    Invoke-NativeWorker -Context $workerContext'
            '} $context'
        )
    }
}

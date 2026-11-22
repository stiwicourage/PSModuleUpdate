BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $directory = Join-Path $root '.github/workflows'
    $script:testsWorkflow = Get-Content (Join-Path $directory 'Tests.yml') -Raw
    $script:publishWorkflow = Get-Content (Join-Path $directory 'Publish.yml') -Raw
    $securityPath = Join-Path $directory 'Security.yml'
    $script:securityWorkflow = if (Test-Path $securityPath) { Get-Content $securityPath -Raw } else { '' }
    $dependabotPath = Join-Path $root '.github/dependabot.yml'
    $script:dependabot = if (Test-Path $dependabotPath) { Get-Content $dependabotPath -Raw } else { '' }
}

Describe 'Shared CI consumer contracts' -Tag 'SharedCi', 'WorkflowPolicy', 'BuildTooling' {
    It 'uses the shared test workflow without replacing its test command' {
        $script:testsWorkflow | Should -Match 'uses: stiwicourage/powershell-ci/\.github/workflows/tests\.yml@\S+'
        $script:testsWorkflow | Should -Not -Match 'test-command:'
        $script:testsWorkflow | Should -Not -Match 'runs-on:'
    }

    It 'requests isolated exact-version test dependencies' {
        $script:testsWorkflow | Should -Match 'dependency-mode: isolated'
        $script:testsWorkflow | Should -Match "pester-required-version: '5.7.1'"
        $script:testsWorkflow | Should -Not -Match 'install-command:'
    }

    It 'uses the common analyzer version and validates both release documents' {
        $script:testsWorkflow | Should -Match "script-analyzer-required-version: '1.25.0'"
        $script:testsWorkflow | Should -Not -Match 'script-analyzer-settings-file:|script-analyzer-enabled:'
        $script:testsWorkflow | Should -Match 'changelog-files: ./CHANGELOG.md ./RELEASE_NOTE.md'
    }

    It 'preserves coverage artifacts and analysis without enabling Codecov' {
        $script:testsWorkflow | Should -Not -Match 'codecov'
        $script:testsWorkflow | Should -Not -Match 'codescene-enabled:|artifact-name:'
        $script:testsWorkflow | Should -Match 'secrets: inherit'
    }

    It 'keeps test scheduling and pull requests to both release branches' {
        $script:testsWorkflow | Should -Match '(?s)branches-ignore:\s+- main'
        $script:testsWorkflow | Should -Match '(?s)pull_request:\s+branches:\s+- main\s+- develop'
        $script:testsWorkflow | Should -Match "cron: '0 3 \* \* \*'"
        $script:testsWorkflow | Should -Match 'workflow_dispatch:'
    }

    It 'uses the shared publisher with GerberCore release semantics and isolated dependencies' {
        $script:publishWorkflow | Should -Match 'uses: stiwicourage/powershell-ci/\.github/workflows/publish\.yml@\S+'
        $script:publishWorkflow | Should -Match 'test-command: Test-NovaBuild'
        $script:publishWorkflow | Should -Match 'release-continuous-integration: true'
        $script:publishWorkflow | Should -Match 'dependency-mode: isolated'
    }

    It 'delegates all three security checks and keeps dependency review PR-only' {
        $script:securityWorkflow | Should -Match 'uses: stiwicourage/powershell-ci/\.github/workflows/codeql\.yml@\S+'
        $script:securityWorkflow | Should -Match 'uses: stiwicourage/powershell-ci/\.github/workflows/powershell-analyzer\.yml@\S+'
        $script:securityWorkflow | Should -Match 'uses: stiwicourage/powershell-ci/\.github/workflows/dependency-review\.yml@\S+'
        $script:securityWorkflow | Should -Match "github.event_name == 'pull_request'"
        $script:securityWorkflow | Should -Not -Match 'fail-on-severity:'
    }

    It 'uses the common weekly security schedule without per-job schedule routing' {
        @([regex]::Matches($script:securityWorkflow, '(?m)^\s+- cron:')).Count | Should -Be 1
        $script:securityWorkflow | Should -Match "cron: '34 3 \* \* 1'"
        $script:securityWorkflow | Should -Not -Match 'github.event.schedule'
    }

    It 'groups shared workflow dependency updates daily without the release cooldown' {
        $script:dependabot | Should -Match 'package-ecosystem: github-actions'
        $script:dependabot | Should -Match 'directory: /'
        $script:dependabot | Should -Match 'interval: daily'
        $script:dependabot | Should -Match 'prefix: chore'
        $script:dependabot | Should -Match 'powershell-ci:'
        $script:dependabot | Should -Match 'stiwicourage/powershell-ci\*'
        $script:dependabot | Should -Match '(?s)cooldown:\s+exclude:\s+- "stiwicourage/powershell-ci\*"'
    }
}

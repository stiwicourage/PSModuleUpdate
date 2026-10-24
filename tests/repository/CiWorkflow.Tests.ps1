BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $workflowDirectory = Join-Path $root '.github/workflows'
    $script:workflowFile = @(Get-ChildItem -LiteralPath $workflowDirectory -Filter '*.yml' -File)
    $script:ci = Get-Content -LiteralPath (Join-Path $workflowDirectory 'ci.yml') -Raw
    $script:publish = Get-Content -LiteralPath (Join-Path $workflowDirectory 'Publish.yml') -Raw
}

Describe 'CI workflow security and gate policy' -Tag 'BuildTooling', 'WorkflowPolicy' {
    It 'never uses pull_request_target' {
        foreach ($file in $script:workflowFile) {
            (Get-Content -LiteralPath $file.FullName -Raw) | Should -Not -Match 'pull_request_target' -Because $file.Name
        }
    }

    It 'pins every external platform-matrix action to a full commit SHA' {
        $uses = @([regex]::Matches($script:ci, '(?m)^\s*(?:-\s*)?uses:\s*(\S+)') | ForEach-Object { $_.Groups[1].Value })
        foreach ($reference in $uses | Where-Object { -not $_.StartsWith('./') }) {
            $reference | Should -Match '@[0-9a-f]{40}$' -Because "ci.yml must pin '$reference'"
        }
    }

    It 'grants the platform matrix only read access to repository contents' {
        $script:ci | Should -Match '(?m)^permissions:\s*\r?\n\s+contents: read\s*$'
        $script:ci | Should -Not -Match ':\s*write'
    }

    It 'keeps the platform matrix free of secrets and publishing commands' {
        $script:ci | Should -Not -Match '\$\{\{\s*secrets\.'
        $script:ci | Should -Not -Match '(?i)psgallery|Publish-Nova|Invoke-NovaRelease|SkipTests'
    }

    It 'does not use moving runner aliases in the platform matrix' {
        $script:ci | Should -Not -Match '(ubuntu|windows|macos)-latest'
    }

    It 'does not trigger the dedicated publish workflow for pull requests' {
        $script:publish | Should -Not -Match '(?m)^  pull_request(?:_target)?:'
    }

    It 'supports pull requests and pushes for develop and main plus reuse' {
        $script:ci | Should -Match '(?m)^\s+pull_request:'
        $script:ci | Should -Match '(?m)^\s+push:'
        $script:ci | Should -Match '(?m)^\s+workflow_call:'
        $script:ci | Should -Match '(?s)pull_request:\s*\r?\n\s+branches:\s*\[develop, main\]'
        $script:ci | Should -Match '(?s)push:\s*\r?\n\s+branches:\s*\[develop, main\]'
    }

    It 'defines an always-evaluated ci-gate that depends on every mandatory job' {
        $script:ci | Should -Match '(?ms)^  ci-gate:\s*\r?\n(?:.*?\r?\n)*?\s+needs:\s*\[plan, quality, platform\]'
        $script:ci | Should -Match '(?ms)^  ci-gate:.*?if:\s*\$\{\{\s*always\(\)\s*\}\}'
    }

    It 'builds the platform matrix from the lane definition so the gate and matrix share one source' {
        $script:ci | Should -Match 'fromJSON\(needs\.plan\.outputs\.matrix\)'
        $script:ci | Should -Match 'fail-fast:\s*false'
    }

    It 'uploads lane artifacts even when tests fail and sets a retention period' {
        $script:ci | Should -Match '(?s)upload-artifact@[0-9a-f]{40}.*?if:\s*\$\{\{\s*always\(\)\s*\}\}'
        $script:ci | Should -Match 'retention-days:\s*14'
    }

    It 'does not persist checkout credentials' {
        $script:ci | Should -Match 'persist-credentials:\s*false'
    }

    It 'invokes the provisioned executable explicitly for dependency provisioning and the lane' {
        $script:ci | Should -Match 'steps\.pwsh\.outputs\.executable'
        $script:ci | Should -Match 'ModuleRoot'
    }

    It 'binds named artifacts to the current run and attempt without cross-run download credentials' {
        $script:ci | Should -Match 'pmu-ci-lane-\$\{\{ github\.run_id \}\}-\$\{\{ github\.run_attempt \}\}-'
        $script:ci | Should -Not -Match 'github-token:'
        $script:ci | Should -Match 'merge-multiple:\s*false'
    }

    It 'cannot mask an artifact download or digest verification failure' {
        $download = [regex]::Match($script:ci, '(?ms)^      - name: Download lane manifests\r?\n.*?(?=^      - name:|\z)').Value
        $download | Should -Not -BeNullOrEmpty
        $download | Should -Not -Match 'continue-on-error:\s*true'
    }
}

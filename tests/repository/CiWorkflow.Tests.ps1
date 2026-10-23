BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $workflowDirectory = Join-Path $root '.github/workflows'
    $script:workflowFile = @(Get-ChildItem -LiteralPath $workflowDirectory -Filter '*.yml' -File)
    $script:ci = Get-Content -LiteralPath (Join-Path $workflowDirectory 'ci.yml') -Raw
}

Describe 'CI workflow security and gate policy' -Tag 'BuildTooling' {
    It 'never uses pull_request_target' {
        foreach ($file in $script:workflowFile) {
            (Get-Content -LiteralPath $file.FullName -Raw) | Should -Not -Match 'pull_request_target' -Because $file.Name
        }
    }

    It 'pins every external action to a full commit SHA' {
        foreach ($file in $script:workflowFile) {
            $uses = @(Select-String -LiteralPath $file.FullName -Pattern '^\s*(?:-\s*)?uses:\s*(\S+)' | ForEach-Object { $_.Matches[0].Groups[1].Value })
            foreach ($reference in $uses | Where-Object { -not $_.StartsWith('./') }) {
                $reference | Should -Match '@[0-9a-f]{40}$' -Because "$($file.Name) must pin '$reference'"
            }
        }
    }

    It 'grants only read access to repository contents and nothing else' {
        foreach ($file in $script:workflowFile) {
            $text = Get-Content -LiteralPath $file.FullName -Raw
            $text | Should -Match '(?m)^permissions:\s*\r?\n\s+contents: read\s*$' -Because $file.Name
            $text | Should -Not -Match ':\s*write' -Because "$($file.Name) must not request write permissions"
        }
    }

    It 'contains no secret references or publishing commands in Phase 1' {
        foreach ($file in $script:workflowFile) {
            $text = Get-Content -LiteralPath $file.FullName -Raw
            $text | Should -Not -Match '\$\{\{\s*secrets\.' -Because $file.Name
            $text | Should -Not -Match '(?i)psgallery|Publish-Nova|Invoke-NovaRelease|SkipTests' -Because $file.Name
        }
    }

    It 'does not use moving runner aliases' {
        foreach ($file in $script:workflowFile) {
            (Get-Content -LiteralPath $file.FullName -Raw) | Should -Not -Match '(ubuntu|windows|macos)-latest' -Because $file.Name
        }
    }

    It 'does not add a release workflow before Phase 2' {
        $script:workflowFile.Name | Should -Not -Contain 'release.yml'
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
}

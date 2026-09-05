param(
    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [switch]$AllIterations,

    [Parameter(Mandatory = $false)]
    [switch]$PrintTemplate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Status {
    param(
        [string]$Level,
        [string]$Message
    )

    switch ($Level) {
        'PASS' { Write-Host "[PASS] $Message" -ForegroundColor Green }
        'FAIL' { Write-Host "[FAIL] $Message" -ForegroundColor Red }
        'WARN' { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
        default { Write-Host "[$Level] $Message" }
    }
}

function Show-Template {
    @'
### Iteration K
- Applied fixes summary: [files + brief changes]
- Verification scope: scoped (N build targets, M test targets) / full solution (fallback) / skipped (no changes)
- Verification: [profile] build [pass/fail], tests [pass/fail] / skipped (no changes), previous: [result]
- Post-fix re-run: Stage 1 [pass/fail/blocked], Stage 2 [pass/fail/blocked], Stage 3 [pass/fail/blocked]
- Re-run evidence: [finding deltas (e.g., P2: 3 -> 1) and key references]
- Findings counts: P1 = X, P2 = Y, P3 = Z
- Decision: continue / stop
- Reason: [why]

Finalization gate (before final answer):
- If code changed in the latest iteration, verification was executed (scoped or full).
- If no code changed in the latest iteration, verification was explicitly skipped with previous result noted.
- If code changed in the latest iteration, post-fix Stage 1/2/3 re-run was completed.
- Latest iteration includes findings deltas vs previous iteration (or baseline for iteration 1).
- Final Decision: stop is justified by a stop condition or hard-stop condition.
'@ | Write-Output
}

function Get-IterationBlocks {
    param([string]$Text)

    $pattern = '(?ms)^### Iteration[^\r\n]*\r?\n.*?(?=^### Iteration[^\r\n]*\r?\n|\z)'
    return [regex]::Matches($Text, $pattern)
}

function Test-IterationBlock {
    param(
        [string]$Block,
        [int]$Index
    )

    $requiredLabels = @(
        'Applied fixes summary:',
        'Verification scope:',
        'Verification:',
        'Post-fix re-run:',
        'Re-run evidence:',
        'Findings counts:',
        'Decision:',
        'Reason:'
    )

    $isValid = $true
    Write-Host ""
    Write-Host ("--- Iteration Block #{0} ---" -f $Index)

    foreach ($label in $requiredLabels) {
        $escaped = [regex]::Escape($label)
        if ([regex]::IsMatch($Block, "(?m)^-\s+$escaped")) {
            Write-Status -Level 'PASS' -Message $label
        }
        else {
            # Verification scope is WARN during transition period (backward compat)
            if ($label -eq 'Verification scope:') {
                Write-Status -Level 'WARN' -Message "Missing field (optional during transition): $label"
            }
            else {
                Write-Status -Level 'FAIL' -Message "Missing field: $label"
                $isValid = $false
            }
        }
    }

    if ([regex]::IsMatch($Block, '(?m)^-\s+Findings counts:\s*P1\s*=\s*\d+,\s*P2\s*=\s*\d+,\s*P3\s*=\s*\d+')) {
        Write-Status -Level 'PASS' -Message 'Findings counts format looks valid'
    }
    else {
        Write-Status -Level 'FAIL' -Message 'Findings counts format should be: P1 = X, P2 = Y, P3 = Z'
        $isValid = $false
    }

    $decisionMatch = [regex]::Match($Block, '(?im)^-\s+Decision:\s*(.+)$')
    if ($decisionMatch.Success) {
        $decisionText = $decisionMatch.Groups[1].Value.Trim()
        if ($decisionText -match '^(continue|stop)\b') {
            Write-Status -Level 'PASS' -Message "Decision value detected: $decisionText"
        }
        else {
            Write-Status -Level 'FAIL' -Message "Decision should start with 'continue' or 'stop' (actual: $decisionText)"
            $isValid = $false
        }
    }

    $reRunMatch = [regex]::Match($Block, '(?im)^-\s+Post-fix re-run:\s*(.+)$')
    if ($reRunMatch.Success) {
        $reRunText = $reRunMatch.Groups[1].Value.Trim()
        $hasStage1 = $reRunText -match 'Stage 1\s+(pass|fail|blocked)'
        $hasStage2 = $reRunText -match 'Stage 2\s+(pass|fail|blocked)'
        $hasStage3 = $reRunText -match 'Stage 3\s+(pass|fail|blocked)'
        if ($hasStage1 -and $hasStage2 -and $hasStage3) {
            Write-Status -Level 'PASS' -Message 'Post-fix re-run statuses include Stage 1/2/3'
        }
        else {
            Write-Status -Level 'FAIL' -Message 'Post-fix re-run should include Stage 1/2/3 statuses (pass/fail/blocked)'
            $isValid = $false
        }
    }

    if ([regex]::IsMatch($Block, '(?im)^-\s+Re-run evidence:\s*(.+)$')) {
        $evidenceText = [regex]::Match($Block, '(?im)^-\s+Re-run evidence:\s*(.+)$').Groups[1].Value
        if ($evidenceText -match 'P[123].*(->|unchanged|baseline)') {
            Write-Status -Level 'PASS' -Message 'Re-run evidence appears to include finding delta/baseline'
        }
        else {
            Write-Status -Level 'WARN' -Message 'Re-run evidence present but no obvious delta keyword found (-> / unchanged / baseline)'
        }
    }

    if ([regex]::IsMatch($Block, '(?im)^-\s+Applied fixes summary:\s*(.+)$')) {
        $appliedText = [regex]::Match($Block, '(?im)^-\s+Applied fixes summary:\s*(.+)$').Groups[1].Value.Trim()
        if ($appliedText -eq '') {
            Write-Status -Level 'WARN' -Message 'Applied fixes summary label exists but inline text is empty (nested bullets may still be valid)'
        }
    }

    # Validate Verification scope content
    $scopeMatch = [regex]::Match($Block, '(?im)^-\s+Verification scope:\s*(.+)$')
    if ($scopeMatch.Success) {
        $scopeText = $scopeMatch.Groups[1].Value.Trim()
        if ($scopeText -match '(scoped|full solution|skipped)') {
            Write-Status -Level 'PASS' -Message "Verification scope value detected: $scopeText"
        }
        else {
            Write-Status -Level 'WARN' -Message "Verification scope should contain 'scoped', 'full solution', or 'skipped' (actual: $scopeText)"
        }
    }

    return $isValid
}

if ($PrintTemplate) {
    Show-Template
    exit 0
}

if ([string]::IsNullOrWhiteSpace($FilePath)) {
    Write-Host "Usage:"
    Write-Host "  pwsh .\stage4_iteration_check.ps1 -FilePath <report.md>"
    Write-Host "  pwsh .\stage4_iteration_check.ps1 -FilePath <report.md> -AllIterations"
    Write-Host "  pwsh .\stage4_iteration_check.ps1 -PrintTemplate"
    exit 2
}

if (-not (Test-Path -LiteralPath $FilePath)) {
    Write-Status -Level 'FAIL' -Message "File not found: $FilePath"
    exit 2
}

$raw = Get-Content -LiteralPath $FilePath -Raw -Encoding UTF8
$matches = Get-IterationBlocks -Text $raw

if ($matches.Count -eq 0) {
    Write-Status -Level 'FAIL' -Message "No '### Iteration' blocks found in: $FilePath"
    exit 1
}

Write-Host ("Found {0} iteration block(s) in {1}" -f $matches.Count, $FilePath)

$overallValid = $true
$targetMatches = @(
    if ($AllIterations) { $matches } else { $matches[$matches.Count - 1] }
)

for ($i = 0; $i -lt $targetMatches.Count; $i++) {
    $match = $targetMatches[$i]
    $displayIndex = if ($AllIterations) { $i + 1 } else { $matches.Count }
    $valid = Test-IterationBlock -Block $match.Value -Index $displayIndex
    if (-not $valid) {
        $overallValid = $false
    }
}

if ($overallValid) {
    Write-Host ""
    Write-Status -Level 'PASS' -Message 'Stage 4 iteration output fields are complete for the checked block(s).'
    exit 0
}

Write-Host ""
Write-Status -Level 'FAIL' -Message 'Stage 4 iteration output is missing required fields or has invalid formatting.'
exit 1
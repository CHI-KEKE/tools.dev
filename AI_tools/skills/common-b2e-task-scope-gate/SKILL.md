---
name: common-b2e-task-scope-gate
description: >
  Evaluate whether a work scope should be merged or split using normalized task-scope signals,
  aligned with common-b2e-nine1-tasks task-breakdown rules. Use this whenever Quick Implement,
  Story-to-Tasks, or Tasks flow needs an advisory split/merge judgment from ImplementPlan,
  clarifications, or task drafts, even if the user does not explicitly ask for "scope gate".
---

# common-b2e-task-scope-gate

Reusable advisory scope gate for deciding whether task scope is likely better as merge/split/manual review.

## Contract

Return a **neutral** result object (no `next_action` field):

```json
{
  "decision": "merge_preferred | split_required | manual_review",
  "score": 0,
  "matched_rules": [],
  "risk_flags": [],
  "evidence": [],
  "overrides": "allow_merge | force_split | partial_split"
}
```

## Normalized Input

Callers must map their source data into this shape before evaluation:

```json
{
  "source": "quick_implement | story_to_tasks | nine1_tasks | other",
  "implement_plan": "string",
  "clarifications": ["string"],
  "task_drafts": [
    {
      "title": "string",
      "domain": "string",
      "estimated_minutes": 0,
      "estimated_file_count": 0,
      "layers": ["Controller", "Service", "Repository", "Entity", "DTO"],
      "non_functional": false
    }
  ],
  "scope_signals": {
    "same_domain_crud": false,
    "entity_plus_repository": false,
    "repository_plus_service": false,
    "api_plus_service": false,
    "cross_domain": false,
    "multi_team_or_multi_stream": false
  },
  "caller_override": "allow_merge | force_split | partial_split | none"
}
```

### Input mapping guidance

1. **quick-implement**
   - Primary source: `Custom.ImplementPlan`.
   - Secondary source: `Description`.
   - If effort/file estimates are missing, infer conservatively and mark evidence as inferred.

2. **story-to-tasks / common-b2e-nine1-tasks**
   - Source bundle: `ImplementPlan + clarifications + task drafts`.
   - Prefer explicit estimates from task drafts over inferred estimates.

## Rule Set (aligned with task-breakdown.md)

### Merge-favoring rules

1. `<30m` estimated effort → merge-favoring.
2. `1 file` impact → merge-favoring.
3. Same-domain CRUD that can finish in `2-4h` → merge-favoring.
4. `Entity + Repository interface` cohesion → merge-favoring.
5. `Repository + Service logic` cohesion → merge-favoring.
6. `API endpoint + Service methods` cohesion → merge-favoring.

### Split-forcing rules

1. `>8h` estimated effort → split-forcing.
2. `>10 files` impact → split-forcing.
3. Cross-domain scope (e.g., Product + Promotion together) → split-forcing.
4. Multi-team/non-functional heavy scope (performance/security/monitoring/integration-load test) → split-forcing.

### Manual review rules

Return `manual_review` when any condition is true:

1. Missing critical evidence (no usable effort + no usable file impact).
2. Strong conflict between merge-favoring and split-forcing signals with low confidence.
3. Scope text is too vague to map to functional units.

## Decision policy

1. Apply `caller_override` first:
   - `force_split` → decision `split_required`.
   - `allow_merge` → decision `merge_preferred` unless a hard split-forcing rule exists (`>8h` or `>10 files`).
   - `partial_split` → decision `manual_review` (requires caller-side partitioning choice).
2. If manual-review rules are triggered, return `manual_review`.
3. Otherwise:
   - Any split-forcing rule hit → `split_required`.
   - Else any merge-favoring rule hit → `merge_preferred`.
   - Else → `manual_review`.

## Score guideline (0-100 confidence)

- Start from 50.
- `+10` per strong matched rule supporting the final decision (max +40).
- `-15` per major evidence gap.
- `-10` per unresolved merge/split conflict.
- Clamp to `[0, 100]`.

Interpretation:
- `80-100`: high confidence
- `60-79`: usable advisory confidence
- `<60`: low confidence, prefer `manual_review`

## Output field requirements

1. `decision`
   - Must be exactly one of: `merge_preferred`, `split_required`, `manual_review`.
2. `score`
   - Integer `0-100`.
3. `matched_rules[]`
   - Include canonical identifiers like:
     - `R-MERGE-UNDER-30M`
     - `R-MERGE-ONE-FILE`
     - `R-MERGE-COHESION-ENTITY-REPO`
     - `R-SPLIT-OVER-8H`
     - `R-SPLIT-OVER-10-FILES`
4. `risk_flags[]`
   - Short machine-readable tags, for example:
     - `missing_effort_estimate`
     - `missing_file_impact`
     - `cross_domain_scope`
     - `conflicting_signals`
5. `evidence[]`
   - Human-readable bullet facts with source tags:
     - `"[ImplementPlan] mentions API + Service in same module"`
     - `"[TaskDraft] estimated_minutes=600 (>8h)"`
6. `overrides`
   - Echo final override state: `allow_merge | force_split | partial_split`.

## Caller integration expectation

This skill is **advisory only** by default:
- It must not auto-create/delete/split tasks directly.
- Caller flow ownership remains in Quick Implement / Story-to-Tasks / Tasks skills.
- Existing A/B/C granularity confirmation stays unchanged; gate output is supporting evidence.

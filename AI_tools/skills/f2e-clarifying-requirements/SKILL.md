---
name: f2e-clarifying-requirements
description: Systematically scan Work Item requirements across frontend-focused five critical categories to identify ambiguities and avoid backend implementation scope
allowed-tools: []
---

## Preconditions

- Work Item information must be provided, including: ID, title, description, requirements, and functional specifications
- Related design documents or API specifications (if available) should also be provided
- Any related business logic or technical documents (if available)

## Workflow Steps

**Output:**
- Scan result report, including:
  - Systematic assessment across five priority categories
  - Status of specific check items under each category (Clear / Partial / Missing)

**Five priority categories:**
Perform systematic ambiguity detection across five priority categories:

**Priority 1 - 業務目標 (Business Goals):**
- **Goal & Value**: Is the core problem this feature aims to solve clearly defined? Are the expected business value and user value explicitly stated?
- **User Journey & Context**: Are the usage scenarios clearly described? Is the complete user flow from start to finish documented? Is the expected usage frequency specified?
- **Scope & Priority**: Are the must-have core features identified? Are deferred features and out-of-scope items declared? Are non-negotiable features specified when time is limited?
- **Success Criteria & Acceptance**: Are the conditions for "successfully completed" clearly defined? Are key validation scenarios specified? Is the verification method for stakeholders documented?
- **User Roles & Personas**: Are different user roles/personas and their corresponding UI flows differentiated?

**Priority 2 - 資料模型 (Data Model):**
- Are required data structures and API response formats clear?
- Are client-side state management needs identified (local state, global state, cache)?
- Are data transformation and normalization requirements specified?
- Are pagination, filtering, and sorting behaviors documented?

**Priority 3 - 外部依賴 (External Dependencies):**
- Are external APIs/services identified with error handling strategies?
- Are third-party libraries and SDKs specified (analytics, payment, maps, etc.)?
- Are API versioning and backward compatibility assumptions documented?
- Are CORS, authentication, and authorization requirements clear?
- Are CDN, asset hosting, and media delivery dependencies identified?

**Priority 4 - 邊界案例 (Edge Cases):**
- Are error states and error handling UI flows covered (network errors, API errors)?
- Are empty states and loading states defined (no data, initial load, refresh)?
- Are form validation and input edge cases specified (invalid formats, max length)?
- Are browser compatibility and responsive breakpoint requirements documented?
- Are concurrent user actions and race conditions considered (optimistic updates, debouncing)?

**Priority 5 - 非功能需求 (Non-Functional Requirements):**
- Are security/privacy requirements documented (XSS prevention, CSRF protection, data masking)?
- Are responsive design requirements specified (breakpoints, mobile-first approach)?

**Internal Assessment:**
For each category, assess: **Clear / Partial / Missing**

## Hard Constraints

- **Frontend scope only**: Must not extend into backend implementation scope (API implementation, database design, etc.)
- **Assessment completeness**: All five Priority categories must be assessed; none may be skipped
- **No assumptions**: Do not infer missing requirements; mark ambiguous items as Missing and list specific questions
- **Evidence-based**: Every assessment conclusion must reference specific text from the Work Item

## Good/Bad Examples

**✅ Good — Systematic scan with per-category assessment**
```
Priority 1 - Business Goals: ⚠️ Partial
- Goal & Value: ✅ Clear — "Add KOL exclusive discount codes to boost referral conversion rate"
- User Journey: ❌ Missing — No explanation of the complete flow for KOL to obtain a discount code
- Success Criteria: ⚠️ Partial — Acceptance criteria exist but lack quantitative targets (e.g., conversion rate goal)

Priority 2 - Data Model: ⚠️ Partial
- API response format has a spec, but client-side cache strategy is not described
```

**❌ Bad — Skipping systematic assessment, jumping straight to a question list**
```
I found the following issues in the requirements that need clarification:
1. How does a KOL obtain a discount code?
2. What is the maximum discount limit?
3. Is there a usage count limit?
```
(Missing the full scan across the five categories; cannot ensure complete requirements coverage)

## Quality Checklist

- [ ] All five Priority categories have been assessed (Clear / Partial / Missing)
- [ ] Every Missing or Partial item has specific questions listed
- [ ] Assessment conclusions reference Work Item content; no self-inferred assumptions
- [ ] Has not extended into backend implementation scope (API implementation, DB schema, etc.)
- [ ] Missing items have been compiled into a question list ready to ask PO/BA directly
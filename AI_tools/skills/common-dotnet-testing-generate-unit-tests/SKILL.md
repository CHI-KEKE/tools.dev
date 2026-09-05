---
name: common-dotnet-testing-generate-unit-tests
description: Use when new or modified C# business-logic services need unit tests generated after implementation stabilizes, especially in Final Gate or post-implementation verification workflows.
---

# common-dotnet-testing-generate-unit-tests

Generate unit tests for changed C# business logic with version-aware xUnit, NSubstitute, and FluentAssertions handling.

Keep this root skill minimal. Load detailed workflow instructions from `references/workflow-details.md` only when needed.

## Quick Start

1. Confirm the caller scope is compact: changed service files, target methods (if known), relevant test project, and cached `repoContext`.
2. Prefer a code-focused mid-tier caller model such as `gpt-5.3-codex` for bounded generation. Escalate to `gpt-5.4` only after compile-fix loops fail or the mocking / branching complexity requires higher reasoning.
3. Load `references/workflow-details.md`.
4. Identify qualifying business-logic targets from changed `.cs` files.
5. Detect test project package versions before generating any code.
6. Generate or append tests, then run compile verification with the profile from `repoContext.verificationProfile`.

## Caller Scope Rules

- Invoke this skill only after implementation is stable enough for test generation.
- Pass only the changed service / method scope and the relevant test-project context. Do **not** send whole-story context unless the test logic truly depends on it.
- Reuse cached `repoContext` instead of re-reading repository instructions in every invocation.
- Skip this skill entirely when no qualifying BL / BLV2 service logic changed.

## Non-Negotiable Rules

- Never assume package versions — detect them from `packages.config` or `.csproj`.
- Never modify production code; generate or update test code only.
- Never emit test code that does not compile; fix and re-run compile verification before finalizing.
- Never generate tests for Entity / DTO / ViewModel / config-only classes.
- Async unit tests must match the SUT contract: keep tests synchronous for synchronous paths, and use `async`/`await` only when executing async (`Task`/`Task<T>`/`ValueTask`) paths.
- Do not force every test in the same class to be async, and do not introduce async wrappers or `Task.Run` just to make synchronous code look async; never use fire-and-forget in tests.
- For multi-repo usage (.NET Framework and .NET/Core), follow each target project's actual async model instead of enforcing one global style.
- Add race/concurrency tests only when shared state, parallel side effects, or explicit idempotency requirements exist; proactively evaluate these tests when shared/static/singleton/cache/dedup-retry state is involved.
- Plain async repository/API `await` tests do not automatically require race tests; deterministic single-thread business flows should not get concurrency tests by default.
- If tests depend on mutable `static` state, enforce per-test isolation: set required static values during Arrange and restore original values during teardown (`try/finally` or `IDisposable` scope helper).
- Never rely on constructor-only static assignment for isolation; every test case (including each `Theory` row) must be independently deterministic.
- When multiple tests mutate the same static resource, require xUnit Collection-level serialization (`[Collection]` + `DisableParallelization = true`) to avoid flaky CI.

## Reference Map

- `references/workflow-details.md`
  - Full prerequisites, execution flow, code patterns, compile verification, and output format.
- `templates/service-test-template.cs`
  - Service test template using `GetSystemUnderTest()`.

## When to Escalate

- Generated tests fail compile verification more than once.
- Target method setup needs complex mocks, exception orchestration, or many conditional branches.
- The service spans multiple collaborating layers and the expected assertions are not obvious from the bounded diff alone.

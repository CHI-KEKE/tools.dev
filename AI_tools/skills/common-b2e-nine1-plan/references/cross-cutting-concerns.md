# Cross-Cutting Concerns — Cross-Cutting Concerns Analysis

---

## Analysis Scope

Focus on the aspects **most relevant** to this feature, avoid boilerplate analysis.

---

## Security（安全性）

Analysis focus:
- Unauthorized access risk (is the endpoint protected by `[Authorize]`?)
- Data validation layers (defense in depth across API layer + Service layer)
- Sensitive data handling (encryption, masking, log filtering)
- SQL Injection prevention (use ORM / parameterized queries)

Output format:
```markdown
##### 🔐 Security
- **風險：** {描述具體風險}
- **緩解措施：**
  - {措施 1}
  - {措施 2}
```

---

## Performance（效能）

Analysis focus:
- N+1 query risk (is eager loading used for related queries?)
- Index coverage (do WHERE / JOIN / ORDER BY columns have indexes?)
- Caching opportunities (high read frequency, low change frequency data)
- Pagination for large datasets (does the LIST API support paging?)

Output format:
```markdown
##### ⚡ Performance
- **潛在瓶頸：** {描述具體瓶頸}
- **優化策略：**
  - {策略 1（例：在 X 欄位加 index）}
  - {策略 2（例：快取 TTL = 5 分鐘）}
```

---

## Maintainability（可維護性）

Analysis focus:
- Layering clarity (clear responsibility boundaries across API / Service / Repository)
- Unit test coverage target (target percentage + core critical paths)
- Business logic documentation (are complex validation rules documented?)
- Dependency injection (is everything injected via DI, to make mocking easy?)

Output format:
```markdown
##### 🛠️ Maintainability
- **方法：**
  - {措施 1（例：清晰分層架構）}
  - {措施 2（例：Service 層單元測試目標 80%+）}
```

---

## Other Concerns (conditional — analyze only if relevant to the feature scope)

### Scalability（擴展性）
Only analyze if the WI mentions high traffic or horizontal scaling requirements.

### Observability（可觀測性）
Only analyze if the WI mentions monitoring, APM, or alerting requirements.

### Error Handling（錯誤處理）
Only analyze if the flow has complex cross-service calls, async flows, or retry mechanisms.

---

## Conciseness Principle

- Only analyze aspects that have a **direct impact on the implementation of this feature**
- No need to apply every category — writing "本功能不涉及，略過" is actually clearer
- Every recommendation for each aspect should be concrete enough to be written directly into a Task's description

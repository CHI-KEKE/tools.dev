# Severity Levels Reference

This document provides guidance on assigning the appropriate severity level to code review rules.

## Severity Levels

### BLOCKER
**Definition**: Critical issues that must be fixed immediately. The code should not be deployed or merged until resolved.

**Examples**:
- Security vulnerabilities (SQL injection, XSS, etc.)
- Data loss risks
- System crash scenarios
- Critical performance issues that make the system unusable

**When to use**: 
- Issues that can cause immediate and severe harm to the system, data, or users
- Violations that completely break core functionality

---

### CRITICAL
**Definition**: Very serious issues that should be fixed as soon as possible. May allow temporary workarounds but require immediate attention.

**Examples**:
- Authentication/Authorization flaws
- Cross-store data access violations (like N00022)
- Significant memory leaks
- Incorrect error handling that could expose sensitive information

**When to use**:
- Issues that pose significant security, data integrity, or reliability risks
- Problems that affect core business logic
- Violations that could lead to data corruption

---

### MAJOR
**Definition**: Important issues that should be addressed. They don't immediately break the system but can cause problems over time.

**Examples**:
- Incorrect use of data types (like DateTime vs DateTimeOffset for UTC)
- Missing input validation
- Improper resource disposal
- Violation of important coding standards

**When to use**:
- Issues that reduce code quality significantly
- Problems that make maintenance difficult
- Violations of important design principles
- Issues that could become critical if not addressed

---

### MINOR
**Definition**: Small issues that should be fixed but are not urgent. Often related to code style or minor improvements.

**Examples**:
- Missing XML documentation
- Minor naming convention violations
- Unnecessary code complexity
- Missing unit tests for edge cases

**When to use**:
- Issues that affect code readability
- Minor style violations
- Small opportunities for improvement
- Issues that have minimal impact on functionality

---

### INFO
**Definition**: Informational items that don't necessarily need to be fixed but provide helpful suggestions.

**Examples**:
- Code style recommendations
- Optimization opportunities
- Alternative approaches
- Best practice suggestions

**When to use**:
- Suggestions for improvement
- Educational information
- Optional enhancements
- Code smells that might indicate deeper issues

---

## Decision Matrix

| Impact | Security Risk | Data Integrity | Performance | → Severity |
|--------|--------------|----------------|-------------|-----------|
| High | Yes | Yes | Critical | **BLOCKER** |
| High | Yes | Yes | Any | **CRITICAL** |
| Medium | Possible | Possible | Any | **MAJOR** |
| Low | No | No | Minor | **MINOR** |
| None | No | No | No | **INFO** |

## Examples from Existing Rules

### N00022 - CRITICAL
**Rule**: Ensure Query Conditions Include StoreId / StoredValueId
**Why CRITICAL**: Directly impacts data security and integrity. Could lead to cross-store data access, which is a serious business and security concern.

### N00016 - MAJOR
**Rule**: Use DateTimeOffset for UTC Properties
**Why MAJOR**: Important for correctness but doesn't immediately break functionality. Can cause issues with time zone handling over time.

## Tips for Assigning Severity

1. **Ask "What's the worst that could happen?"**
   - Data loss/corruption → BLOCKER/CRITICAL
   - Security breach → BLOCKER/CRITICAL
   - Incorrect business logic → CRITICAL/MAJOR
   - Hard to maintain → MAJOR/MINOR

2. **Consider the likelihood of problems**
   - Always causes issues → Higher severity
   - Might cause issues in specific scenarios → Lower severity

3. **Think about business impact**
   - Affects customers directly → Higher severity
   - Internal quality concern → Lower severity

4. **When in doubt, start higher**
   - It's better to be cautious initially
   - Can always reduce severity based on team feedback
   - Easier to justify lowering than raising

5. **Consistency is key**
   - Compare with similar existing rules
   - Maintain relative importance across rules
   - Document reasoning for borderline cases

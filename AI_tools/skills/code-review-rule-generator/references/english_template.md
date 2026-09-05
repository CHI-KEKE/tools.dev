# [Rule Title - Clear and Concise Description of the Rule]

- **Key**: N00000  
- **Repository**: [repository-name]  
- **Created At**: YYYYMMDD  
- **Severity**: [BLOCKER|CRITICAL|MAJOR|MINOR|INFO]  
- **Status**: [READY|BETA|DEPRECATED]  
- **Language**: [C#|Java|JavaScript|Python|...]  

---

## Why is this an issue?

[Provide a clear explanation of why this is a problem. Include:]
- The technical reason behind the rule
- Potential consequences of not following the rule
- Impact on code quality, maintainability, performance, or security
- Best practices or standards that support this rule

---

## **Noncompliant Code Example**

```[language]
// Example of code that violates this rule
// Include clear comments explaining what's wrong
public class NonCompliantExample {
    // Problem description
    public DateTime CreateDateTimeUtc { get; set; }
}
```

### Issue

1. [First issue with the noncompliant code]  
2. [Second issue - explain the problem clearly]  
3. [Additional issues if applicable]  

---

## **Compliant Solution**

```[language]
// Example of code that follows this rule correctly
// Include clear comments explaining the improvement
public class CompliantExample {
    // Solution description
    public DateTimeOffset CreateDateTimeUtc { get; set; }
}
```

### Solution

1. [First improvement or fix applied]  
2. [Second improvement - explain how it solves the problem]  
3. [Additional improvements if applicable]  

---

## Additional Recommendations

1. **Code Reviews**: [Guidance for code reviewers]  
2. **Static Analysis**: [How to enforce this rule with tools]  
3. **Documentation**: [Documentation best practices related to this rule]  
4. **Team Guidelines**: [Team-specific recommendations]  
5. **Testing**: [Testing considerations if applicable]  

---

## Resources

- [Link to official documentation]
- [Link to related standards or guidelines]
- [Link to relevant articles or blog posts]

---

## Exceptions

[Describe any valid exceptions to this rule, if applicable]
- Exception scenario 1
- Exception scenario 2

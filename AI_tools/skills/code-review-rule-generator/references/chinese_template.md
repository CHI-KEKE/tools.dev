# [規則標題 - 清晰簡潔的規則描述]

- **Key**: N00000  
- **Repository**: [repository-name]  
- **Created At**: YYYYMMDD  
- **Severity**: [BLOCKER|CRITICAL|MAJOR|MINOR|INFO]  
- **Status**: [READY|BETA|DEPRECATED]  
- **Language**: [C#|Java|JavaScript|Python|...]  

---

## 為什麼這是個問題？

[提供清晰的問題說明，包含：]
- 規則背後的技術原因
- 不遵循此規則可能導致的後果
- 對程式碼品質、可維護性、效能或安全性的影響
- 支持此規則的最佳實踐或標準

---

## **不合規的程式碼範例**

```[language]
// 違反此規則的程式碼範例
// 包含清晰的註解說明問題所在
public class NonCompliantExample {
    // 問題描述
    public DateTime CreateDateTimeUtc { get; set; }
}
```

### 問題

1. [不合規程式碼的第一個問題]  
2. [第二個問題 - 清楚說明問題]  
3. [其他問題(如適用)]  

---

## **合規的解決方案**

```[language]
// 正確遵循此規則的程式碼範例
// 包含清晰的註解說明改進之處
public class CompliantExample {
    // 解決方案描述
    public DateTimeOffset CreateDateTimeUtc { get; set; }
}
```

### 解決方案

1. [第一個改進或修正]  
2. [第二個改進 - 說明如何解決問題]  
3. [其他改進(如適用)]  

---

## 額外建議

1. **程式碼審查**：[給程式碼審查者的指導]  
2. **靜態分析**：[如何使用工具強制執行此規則]  
3. **文件**：[與此規則相關的文件最佳實踐]  
4. **團隊指南**：[團隊特定建議]  
5. **測試**：[測試考量事項(如適用)]  

---

## 資源

- [官方文件連結]
- [相關標準或指南連結]
- [相關文章或部落格文章連結]

---

## 例外情況

[描述此規則的任何有效例外情況(如適用)]
- 例外情況 1
- 例外情況 2

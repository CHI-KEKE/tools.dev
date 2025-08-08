# 雜湊演算法指南

## 目錄
- [SHA-256](#sha-256)
- [應用場景](#應用場景)
- [C# 應用實例](#c-應用實例)

<br><br>

---

## SHA-256

SHA-256 是一種「固定長度、不可逆、不可碰撞」的數位指紋產生器。

<br>

這台碎紙機（SHA-256）有幾個魔法特性：

<br>

| 特性 | 說明 |
|------|------|
| 🟰 輸入一樣 → 輸出一定一樣 | 相同內容輸入，產出絕對相同指紋。 |
| 🧩 輸入不一樣 → 輸出完全不同 | 哪怕只改一個字母，產生的結果也會完全不一樣。 |
| 🔒 無法還原（不可逆） | 從碎紙機出來的紙屑（雜湊值）無法回推原內容。 |
| 📏 固定長度 | 無論你輸入多長的內容，輸出都剛剛好是 256 位元（32 位元組）。 |

<br>

它就是一個「雜湊函式（Hash Function）」：

<br>

將任何長度的資料 → 轉成一串長度固定的亂數字串（雜湊值）。

<br>

範例：

<br>

```
輸入："hello"
SHA-256 輸出：
2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
```

<br>

**說明：**

<br>

SHA = Secure Hash Algorithm，由美國國安局設計。

<br>

SHA-256 屬於 SHA-2 系列，是目前最常用的加密雜湊算法之一。

<br>

它不是加密（Encryption），因為不能還原。

<br>

產出長度：256 位元 = 32 位元組 = 64 個 16 進位字元。

<br><br>

---

## 應用場景

### 驗證資料完整性（類似防偽標籤）

把原始檔案跑一次 SHA-256，記住這組值。

<br>

未來每次下載都重新比對，看有沒有被竄改。

<br>

### 密碼儲存

不直接存使用者的密碼，而是存 SHA-256 之後的值。

<br>

萬一資料庫被駭，駭客也拿不到真正密碼。

<br>

### 區塊鏈

每個區塊的資料都經過 SHA-256 雜湊，保證資料一致性。

<br>

任何一筆資料只要被改動，整條鏈就會驗證失敗。

<br><br>

---

## C# 應用實例

### 基本使用

```csharp
using System.Security.Cryptography;
using System.Text;

string input = "Hello, SHA-256!";

// Step 1: 建立 SHA256 演算法物件
using (SHA256 sha256 = SHA256.Create())
{
    // Step 2: 將字串轉成 byte[]（先用 UTF-8 編碼）
    byte[] inputBytes = Encoding.UTF8.GetBytes(input);

    // Step 3: 計算雜湊值
    byte[] hashBytes = sha256.ComputeHash(inputBytes);

    // Step 4: 將 byte[] 轉成可讀的 16 進位格式
    StringBuilder sb = new StringBuilder();
    foreach (byte b in hashBytes)
    {
        sb.Append(b.ToString("x2")); // 兩位 16 進位小寫格式
    }

    string hashResult = sb.ToString();

    Console.WriteLine($"原始內容: {input}");
    Console.WriteLine($"SHA-256 雜湊值: {hashResult}");
}
```

<br>

輸出結果：

<br>

```
原始內容: Hello, SHA-256!
SHA-256 雜湊值: 86c8f367e...（共 64 字）
```

<br>

### 密碼儲存

```csharp
string password = "MyS3cret!";

// 將密碼轉為 SHA-256
string hashedPassword = GetSha256Hash(password);

// 儲存在資料庫中（這裡只是模擬）
Console.WriteLine($"儲存的密碼雜湊值：{hashedPassword}");

// 驗證登入時的密碼
string inputFromUser = "MyS3cret!";
string hashedInput = GetSha256Hash(inputFromUser);

if (hashedInput == hashedPassword)
{
    Console.WriteLine("登入成功！");
}
else
{
    Console.WriteLine("密碼錯誤！");
}

// 小函式：封裝 SHA-256 功能
string GetSha256Hash(string text)
{
    using (SHA256 sha256 = SHA256.Create())
    {
        byte[] bytes = Encoding.UTF8.GetBytes(text);
        byte[] hashBytes = sha256.ComputeHash(bytes);
        StringBuilder sb = new StringBuilder();
        foreach (byte b in hashBytes)
        {
            sb.Append(b.ToString("x2"));
        }
        return sb.ToString();
    }
}
```

<br>

### 檔案完整性驗證

```csharp
string filePath = "C:\\Users\\YourName\\Documents\\test.txt";

using (FileStream stream = File.OpenRead(filePath))
using (SHA256 sha256 = SHA256.Create())
{
    byte[] hashBytes = sha256.ComputeHash(stream);
    
    string fileHash = BitConverter.ToString(hashBytes).Replace("-", "").ToLower();
    Console.WriteLine($"檔案 SHA-256：{fileHash}");
}
```
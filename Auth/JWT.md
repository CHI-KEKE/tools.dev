# JWT 認證指南

## 目錄
- [什麼是 JWT](#什麼是-jwt)
- [為什麼要有 JWT](#為什麼要有-jwt)
- [JWT 的結構](#jwt-的結構)
- [Base64Url 編碼](#base64url-編碼)
- [簽名的本質](#簽名的本質)
- [JWT 的驗證流程](#jwt-的驗證流程)
- [JWT 不是加密](#jwt-不是加密)
- [為什麼大多數 JWT 不加密](#為什麼大多數-jwt-不加密)
- [安全實務建議](#安全實務建議)
- [什麼情境適合用 JWT](#什麼情境適合用-jwt)
- [C# 建立 Token 實作](#c-建立-token-實作)

<br><br>

---

## 什麼是 JWT

JWT 全名是 JSON Web Token，標準規範為 RFC 7519。

<br>

它是一種用 JSON 格式描述的無狀態認證憑證，常用來在 Web API、前後端分離系統、微服務之間傳遞「使用者的身份」。

<br><br>

---

## 為什麼要有 JWT

**傳統 Session 的問題**：

- 每次請求需要查資料庫或 Redis 取得 Session
- 後端需要保存 Session 狀態 (Stateful)

<br>

**JWT 的好處**：

- 無狀態 (Stateless)：伺服器不需要保存 Session
- 快速：只要檢查 Token 的簽名與有效期
- 容易擴展：多台伺服器共享驗證，不需要同步 Session

<br><br>

---

## JWT 的結構

JWT 由三段組成，用 . 隔開：

```
Header.Payload.Signature
```

<br>

**Header**

JSON，描述演算法與型態

```json
{ "alg": "HS256", "typ": "JWT" }
```

<br>

**Payload**

JSON，記錄使用者的資料 (Claims)，例如：

```json
{ "sub": "123", "name": "Allen", "role": "Admin", "exp": 1723695600 }
```

<br>

**Signature**

- 用 Header + Payload + SecretKey 計算出來
- 防止內容被竄改

<br><br>

---

## Base64Url 編碼

Header 與 Payload 都是 Base64Url 編碼

<br>

任何人拿到 JWT 都能用 Base64 decode 看到內容

<br>

簽名不是為了隱藏內容，而是保證內容完整性

<br><br>

---

## 簽名的本質

以常用的 HMAC-SHA256 (HS256) 為例：

```
Signature = HMACSHA256(
    Base64Url(Header) + "." + Base64Url(Payload),
    SecretKey
)
```

<br>

**伺服器驗證方式**：

- 用同樣的 SecretKey 和演算法重新計算簽名
- 比對是否和 Token 裡的 Signature 一致

<br>

重點：演算法公開，安全性來自 Secret Key

<br><br>

---

## JWT 的驗證流程

1. 用 Secret Key 驗證簽名
2. 檢查 Token 是否過期 (exp)
3. 如果簽名正確且沒過期 → Token 有效，可以直接信任 Payload 裡的資訊

<br>

整個過程不需要查資料庫。

<br><br>

---

## JWT 不是加密

**常見誤解**

「JWT 使用 HMAC、RSA、ECDSA 等演算法來加密」這句話是錯的！

<br>

這些演算法在 JWS 裡的用途是簽名，不是加密

<br>

簽名確保「內容沒有被改過」，並不會隱藏內容

<br>

如果要讓內容看不懂，必須用 JWE (JSON Web Encryption)，這是另一個規範

<br><br>

---

## 為什麼大多數 JWT 不加密

- 設計目標是完整性，不是隱私
- 效能考量：加密/解密會增加 CPU 負擔
- 敏感資訊不應該放進 Token
- 重要資料要查資料庫
- 傳輸時使用 HTTPS 保護

<br><br>

---

## 安全實務建議

- JWT 裡不要放敏感資訊（密碼、信用卡、身份證號）
- 傳輸時一定要用 HTTPS
- 縮短 JWT 的有效期 (例如 15 分鐘)
- 需要長時間登入：Access Token + Refresh Token
- Secret Key 必須保護好，不能被洩漏

<br><br>

---

## 什麼情境適合用 JWT

**適合**：

- 前後端分離 (SPA + API)
- 微服務之間的身份驗證
- 無狀態、可水平擴展的服務

<br>

**不適合**：

- 需要「馬上讓 Token 失效」的情境（因為無法撤銷已發出的 Token）
- Token 很大，傳輸頻寬敏感

<br><br>

---

## C# 建立 Token 實作

```csharp
void Main()
{
	GenerateJwtToken().Dump();
}

public static string GenerateJwtToken()
{
	var tokenHandler = new JwtSecurityTokenHandler();
	var key = Encoding.ASCII.GetBytes("your_secret_key_here_longer_longer_longer_your_secret_key_here_longer_longer_longer");
	var tokenDescriptor = new SecurityTokenDescriptor
	{
		Subject = new ClaimsIdentity(new[]
		{
			new Claim(ClaimTypes.Name, "今天是UserAllen")
		}),

		Expires = DateTime.UtcNow.AddHours(1),
		Issuer = "your_issuer",
		Audience = "your_audience",
		SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
	};

	var token = tokenHandler.CreateToken(tokenDescriptor);
	return tokenHandler.WriteToken(token);
}
```

這段程式碼要做的是：

<br>

建立一張 JWT（JSON Web Token），裡面寫著使用者資訊，並用密鑰簽名，最後輸出成一段字串。

<br>

這張 Token 可以用來讓伺服器之後快速辨認「這個人是誰」。

<br>

### 程式中的主要角色與本質

**1. JwtSecurityTokenHandler**

本質：這是一個 Token 工廠 / 工具人，負責：

- 幫你根據規格組合 JWT
- 也能幫你解析、驗證 JWT

<br>

為什麼要有它？JWT 的標準包含 Header、Payload、Signature 三段，要自己手工組裝不方便，所以用現成的類別。

<br>

**2. key (byte[])**

```csharp
var key = Encoding.ASCII.GetBytes("your_secret_key_here_longer_longer_longer_your_secret_key_here_longer_longer_longer");
```

本質：伺服器用來簽名的秘密金鑰 (Secret Key)。

<br>

深一層意義：這個 key 是伺服器自己知道的「印章」。之後驗證 Token 時，也要用這把 key 才能確認 Token 不是假的。

<br>

注意：不能洩漏，不然任何人都可以偽造 Token。

<br>

**3. SecurityTokenDescriptor**

```csharp
var tokenDescriptor = new SecurityTokenDescriptor { ... };
```

本質：描述 Token 的內容規格。

<br>

包含哪些東西？

- Subject：使用者身份 (Claims)
- Expires：有效期限
- Issuer / Audience：誰發 Token，發給誰
- SigningCredentials：用哪個密鑰與演算法簽名

<br>

比喻：像在訂單上填寫：顧客是誰、什麼時候有效、誰開的單、要用哪種章蓋章。

<br>

**4. ClaimsIdentity / Claim**

```csharp
new ClaimsIdentity(new[] { new Claim(ClaimTypes.Name, "今天是UserAllen") })
```

本質：這個 Token 裡面要攜帶的身份資訊 (Payload)。

<br>

Claim：一條身份資料，例如「Name = 今天是UserAllen」。

<br>

比喻：就像門票上寫著「這張票是屬於 Allen 的」。

<br>

**5. SigningCredentials**

```csharp
new SigningCredentials(
    new SymmetricSecurityKey(key),
    SecurityAlgorithms.HmacSha256Signature
)
```

本質：告訴 Token 工廠：

- 用哪一把密鑰 (key)
- 用什麼演算法 (HMAC-SHA256) 來產生簽名

<br>

深一層意義：這是最關鍵的「防偽章」設定。

<br>

**6. CreateToken / WriteToken**

```csharp
var token = tokenHandler.CreateToken(tokenDescriptor);
return tokenHandler.WriteToken(token);
```

CreateToken：依照 tokenDescriptor 組出一個 Token 物件（還沒轉成字串）

<br>

WriteToken：把 Token 物件轉成字串 (xxxxx.yyyyy.zzzzz)

<br>

### 實務情境：完整流程

假設情境是「使用者登入系統，系統簽發 JWT」。

<br>

**Step 1. 使用者提供帳號密碼登入**

後端檢查帳密正確，決定要發給這個人一張「身分證」。

<br>

**Step 2. 建立 Token 描述 (SecurityTokenDescriptor)**

系統準備一張電子票，票上要寫：

- 使用者名稱：Allen
- 有效時間：1 小時
- 簽發者：your_issuer
- 發給誰用：your_audience
- 要用哪個秘密章：密鑰 + HMAC-SHA256

<br>

**Step 3. JwtSecurityTokenHandler 負責「蓋章並製作 Token」**

- 把 Header（alg、typ）和 Payload（你的名字、有效期限）組起來
- 用密鑰算出簽名 (Signature)
- 把三段組合起來變成：xxxxx.yyyyy.zzzzz

<br>

**Step 4. 系統把 Token 回傳給使用者**

使用者之後每次呼叫 API，都要帶這段 Token。

<br>

**Step 5. 驗證時**

伺服器收到 Token：

- 用密鑰重新計算簽名
- 簽名一致 → 內容沒被改
- 檢查時間 → 沒過期
- 從 Payload 拿出 Name = Allen，直接相信這次請求就是 Allen 發的

<br>

### 為什麼只要驗簽名和期限就知道「是誰」？

因為這張票是伺服器自己簽發的，且內容不能被改

<br>

伺服器可以直接信任 Payload 裡面的資料，不需要每次查資料庫

<br>

### 比喻

這整段程式就是「做門票」：

- SecurityTokenDescriptor = 門票規格
- JwtSecurityTokenHandler = 印票機
- Secret Key = 門票的防偽章
- Token = 門票本身

<br>

使用者之後拿著票就能進場，工作人員只需要看防偽章和有效日期。

<br>

### 這段程式產生的結果

會輸出一個長長的 JWT 字串，例如：

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

前兩段 decode 後是 JSON：

- Header: alg, typ
- Payload: { "unique_name": "今天是UserAllen", "exp": 1723..., "iss": "your_issuer" ... }
---
name: bruno-api-testing
description: Comprehensive guide for setting up and using Bruno HTTP client for API testing. Use this when the user asks to set up Bruno collections, write HTTP requests, configure environments, set up authentication, or do anything related to API testing with Bruno.
---

# Bruno API Testing

Bruno is an open-source API client (similar to Postman/Insomnia) that stores collections as plain files on disk, making them version-control friendly.

---

## My Local Bruno Workspaces

| Workspace | Path |
|-----------|------|
| Personal | `C:\Users\Allen Lin\Desktop\Tool.dev_ingit\tools.dev\bruno-client-personal` |
| Work | `C:\Users\Allen Lin\Desktop\Tool.dev_ingit\tools.dev\BrunoClient` |

When the user asks to run commands (e.g., `npm install`) or navigate to a collection, always reference the correct workspace path above unless they specify otherwise.

---

## 1. Collection Structure

A Bruno collection is a **directory** on disk. The minimal structure looks like this:

```
my-api/
├── bruno.json           ← required: marks this folder as a Bruno collection
├── environments/
│   ├── local.bru
│   └── staging.bru
├── auth/
│   └── login.bru
└── users/
    ├── get-users.bru
    └── create-user.bru
```

### `bruno.json` (required at collection root)

```json
{
  "version": "1",
  "name": "My API",
  "type": "collection",
  "ignore": [
    "node_modules",
    ".git"
  ]
}
```

> ⚠️ Without `bruno.json`, Bruno will not recognize the folder as a collection.

---

## 2. Environment Variables

Environment files live in the `environments/` folder inside the collection.

### Example: `environments/local.bru`

```
vars {
  baseUrl: http://localhost:3000
  apiKey: my-local-key
}

vars:secret [
  apiKey
]
```

### Using variables in requests

Use `{{variableName}}` syntax in URLs, headers, and body:

```
url: {{baseUrl}}/api/users
```

> ⚠️ Bruno uses `{{variable}}` syntax — NOT `${variable}` or `:variable`.

---

## 3. Writing Requests

Each request is a `.bru` file. Examples below:

### GET Request

```
meta {
  name: Get Users
  type: http
  seq: 1
}

get {
  url: {{baseUrl}}/api/users
  body: none
  auth: bearer
}

auth:bearer {
  token: {{accessToken}}
}

query {
  page: 1
  limit: 20
}
```

### POST Request with JSON Body

```
meta {
  name: Create User
  type: http
  seq: 2
}

post {
  url: {{baseUrl}}/api/users
  body: json
  auth: bearer
}

auth:bearer {
  token: {{accessToken}}
}

headers {
  Content-Type: application/json
}

body:json {
  {
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

### POST Request with Form Data

```
post {
  url: {{baseUrl}}/api/upload
  body: multipart
  auth: none
}

body:multipart {
  field1: value1
  field2: value2
}
```

### PUT / PATCH / DELETE

Same pattern — replace `post` with `put`, `patch`, or `delete`.

---

## 4. Authentication

### Bearer Token (per request)

```
auth:bearer {
  token: {{accessToken}}
}
```

### Basic Auth

```
auth:basic {
  username: {{username}}
  password: {{password}}
}
```

### Setting Auth at Folder Level (Inheritance)

Create a `folder.bru` file inside a folder to set shared settings:

```
meta {
  name: Users API
}

auth: bearer

auth:bearer {
  token: {{accessToken}}
}
```

> ⚠️ Auth inheritance is NOT automatic. Each request inside the folder must explicitly set `auth: inherit` to use the folder-level auth. The default is `auth: none`.

```
get {
  url: {{baseUrl}}/api/users
  body: none
  auth: inherit    ← must explicitly set this
}
```

---

## 5. Pre-Request and Post-Response Scripts

Scripts use JavaScript and run before/after a request.

### Pre-request script (e.g., set a timestamp variable)

```
script:pre-request {
  bru.setVar("timestamp", Date.now());
}
```

### Post-response script (e.g., save token from login response)

```
script:post-response {
  const token = res.getBody().data.accessToken;
  bru.setEnvVar("accessToken", token);
}
```

### Variable Scopes in Scripts

Bruno variables have **three scopes**. Always use the correct API for the correct scope:

| API | Scope | When to use |
|-----|-------|-------------|
| `bru.getRequestVar("key")` | Request-level | Variables set within the same request |
| `bru.getCollectionVar("key")` | Collection-level | Variables shared across the whole collection |
| `bru.getEnvVar("key")` | Environment-level | Variables defined in `environments/*.bru` files |
| `bru.setEnvVar("key", value)` | Environment-level | Save a value into the active environment |
| `bru.setCollectionVar("key", value)` | Collection-level | Save a value at collection scope |
| `res.getBody()` | — | Get parsed response body (in post-response only) |
| `res.getStatus()` | — | Get HTTP status code (in post-response only) |

> ⚠️ `bru.getEnvVar()` and `bru.getCollectionVar()` are NOT interchangeable. If a variable is stored in the collection, `getEnvVar` will return `undefined` (and vice versa). Always verify which scope your variable belongs to.

**Recommended: use a fallback helper to avoid scope confusion:**

```js
const getVal = (name) =>
  bru.getRequestVar(name) ||
  bru.getCollectionVar(name) ||
  bru.getEnvVar(name);

const secretKey = getVal("secret-key");
```

### ⚠️ `req.getBody()` returns raw unresolved template

In a pre-request script, `req.getBody()` returns the **raw template string**, with `{{variable}}` placeholders still unexpanded. For example:

```js
// ❌ WRONG — payload will contain "{{merchant-id}}" as a literal string
const payload = req.getBody();
```

**Always build the payload manually using `bru` variable APIs:**

```js
// ✅ CORRECT
const payload = {
  merchantID: getVal("merchant-id"),
  invoiceNo:  getVal("invoice-no"),
  amount:     getVal("amount"),
};
```

### Pattern: Sign a JWT in Pre-Request Script

```js
script:pre-request {
  const jwt = require("jsonwebtoken");

  const getVal = (name) =>
    bru.getRequestVar(name) ||
    bru.getCollectionVar(name) ||
    bru.getEnvVar(name);

  const secretKey = getVal("secret-key");

  const payload = {
    merchantID: getVal("merchant-id"),
    invoiceNo:  getVal("invoice-no"),
  };

  const token = jwt.sign(payload, secretKey, { algorithm: "HS256" });
  bru.setVar("jwtToken", token);
}
```

> ✅ `jsonwebtoken` is available in Bruno's default Safe Mode — no extra setup needed.
> ❌ Do NOT use `require("crypto")` to build JWT manually — `crypto` is not available in Bruno's script sandbox.

### Pattern: Decode a JWT Response in Post-Response Script

Some APIs return a JWT as the response payload. To decode it:

```js
script:post-response {
  const jwt = require("jsonwebtoken");

  const responseBody = res.getBody();
  const encodedPayload = responseBody.payload;

  // jwt.decode() does NOT verify signature — use when you just need the claims
  const decoded = jwt.decode(encodedPayload);

  // Save individual fields as Bruno variables
  bru.setEnvVar("payment-token", decoded.paymentToken);
  bru.setEnvVar("web-payment-url", decoded.webPaymentUrl);
  bru.setEnvVar("resp-code", decoded.respCode);
}
```

---

## 6. Assertions / Tests

```
tests {
  test("should return 200", function() {
    expect(res.getStatus()).to.equal(200);
  });

  test("should have access token", function() {
    expect(res.getBody()).to.have.property("accessToken");
  });
}
```

---

## 7. External Libraries (Developer Mode)

By default, Bruno runs scripts in **Safe Mode**, which only allows a small set of built-in modules (e.g., `jsonwebtoken`). To use external npm packages, you must switch to **Developer Mode**.

### Step 1: Enable Developer Mode in Bruno UI

1. Open the Collection in Bruno Desktop
2. Go to **Collection Settings**
3. Find **JavaScript Sandbox**
4. Switch from **Safe Mode** → **Developer Mode**

For CLI runs:
```bash
bru run --sandbox=developer
```

### Step 2: Install packages in the collection folder

Run `npm install` **in the same directory as `bruno.json`** — NOT inside the Bruno UI.

```bash
cd "path/to/your/collection"   # the folder that contains bruno.json
npm init -y
npm install <package-name>
```

### ⚠️ ESM-only packages will fail

Bruno's script sandbox uses **CommonJS (`require()`)**. If a package is ESM-only, you will see:

```
Pre-Request Script Error
Unexpected token 'export'
```

**Fix**: install an older version of the package that supports CommonJS. Example for `jose`:

```bash
npm uninstall jose
npm install jose@5   # jose@5 supports CommonJS; latest versions are ESM-only
```

> General rule: if you see `Unexpected token 'export'` after installing a package, the package is ESM-only. Look for an older version or an alternative package.

---

## 8. Known Pitfalls

- **`bruno.json` is required**: The collection root directory must contain `bruno.json`. Without it, Bruno will not recognize the folder as a collection.
- **Variable syntax is `{{var}}`**: Do NOT use `${var}` or `:var` — those will not be substituted.
- **Auth inheritance requires explicit opt-in**: Setting auth on a folder does NOT automatically apply to child requests. Each request must set `auth: inherit` explicitly.
- **Environment must be selected in Bruno UI**: Defining an environment file is not enough — the user must also select the active environment in the Bruno UI or CLI for variables to resolve.
- **`require("crypto")` is NOT available**: Bruno's sandbox does not expose Node.js built-in modules like `crypto`. Use `jsonwebtoken` (available in Safe Mode) instead of manually implementing crypto/JWT logic.
- **`req.getBody()` returns unresolved template**: In pre-request scripts, `req.getBody()` returns the raw `.bru` body with `{{variable}}` not yet substituted. Never use it as a data source for signing or hashing — always build the payload manually via `bru.getCollectionVar()` / `bru.getEnvVar()`.
- **Variable scope mismatch causes silent `undefined`**: `bru.getEnvVar()` and `bru.getCollectionVar()` are distinct — using the wrong one returns `undefined` with no error. Always verify which scope your variable is in, or use the fallback helper pattern.
- **`npm install` goes in the collection folder**: External packages must be installed in the folder containing `bruno.json`, not anywhere else. Bruno looks for `node_modules` relative to the collection root.
- **ESM-only npm packages will fail with `Unexpected token 'export'`**: Bruno's sandbox is CommonJS-based. If this error appears after installing a package, downgrade to a CommonJS-compatible version.

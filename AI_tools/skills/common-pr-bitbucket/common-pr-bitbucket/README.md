# pr-bitbucket Prerequisites

The `pr-bitbucket` skill requires the following environment variables:

| Variable | Required | Description |
|----------|----------|-------------|
| `BB_TOKEN` | ✅ | Bitbucket API Token (scopes listed below) |
| `BB_USERNAME` | ✅ | Your Atlassian account email (used for Basic Auth) |
| `BB_PROJECT_KEY` | ⬜ | Bitbucket project key for fetching default reviewers (e.g. `YOUR_PROJECT_KEY`) |

**BB_TOKEN required scopes** (select App: **Bitbucket** when creating the token):

| Scope | Reason |
|-------|--------|
| `Repositories:Read` (`read:repository:bitbucket`) | Search remote branches |
| `Pull requests:Read` (`read:pullrequest:bitbucket`) | Read PR info |
| `Pull requests:Write` (`write:pullrequest:bitbucket`) | Create PR |
| `Projects:Read` (`read:project:bitbucket`) | Fetch default reviewers |

```powershell
# Windows (PowerShell) — set once, persists across sessions
[System.Environment]::SetEnvironmentVariable("BB_TOKEN", "your-api-token-here", "User")
[System.Environment]::SetEnvironmentVariable("BB_USERNAME", "your@email.com", "User")
[System.Environment]::SetEnvironmentVariable("BB_PROJECT_KEY", "YOUR_PROJECT_KEY", "User")
# Restart your terminal / IDE after running this
```

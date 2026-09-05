

## mcp 建置


.vscode / mcp.json


```json
{
	"servers": {
        "Azure DevOps Assistant": {
          "command": "C:\\Users\\Allen Lin\\AppData\\Local\\Programs\\Python\\Python313\\Scripts\\uv.exe",
          "args": [
            "--directory",
            "C:\\91App\\AI_Devs\\mcp-azure-devops\\src\\mcp_azure_devops",
            "run",
            "--with",
            "mcp[cli]",
            "mcp",
            "run",
            "C:\\91App\\AI_Devs\\mcp-azure-devops\\src\\mcp_azure_devops\\server.py"
          ],
		   "env": {
        "AZURE_DEVOPS_PAT": "",
        "AZURE_DEVOPS_ORG_URL": "https://91appinc.visualstudio.com"
      }
        }
	},
	"inputs": []
}
```


## 法2 - 直接放在 Globally json

C:\Users\Allen Lin\AppData\Roaming\Code\User\mcp.json

```json
{
	"servers": {
		// "Framelink Figma MCP": {
		// 	"command": "cmd",
		// 	"args": [
		// 		"/c",
		// 		"npx",
		// 		"-y",
		// 		"figma-developer-mcp",
		// 		"--figma-api-key=xxx",
		// 		"--stdio"
		// 	],
		// 	"type": "stdio"
		// },
		"Azure DevOps Assistant": {
			"command": "C:\\Users\\Allen Lin\\AppData\\Local\\Programs\\Python\\Python313\\Scripts\\uv.exe",
			"args": [
				"--directory",
				"C:\\91APP\\AI_Devs\\Azure2\\mcp-azure-devops\\src\\mcp_azure_devops",
				"run",
				"--with",
				"mcp[cli]",
				"mcp",
				"run",
				"C:\\91APP\\AI_Devs\\Azure2\\mcp-azure-devops\\src\\mcp_azure_devops\\server.py"
			],
			"type": "stdio",
			"env": {
			"AZURE_DEVOPS_PAT": "",
			"AZURE_DEVOPS_ORG_URL": "https://91appinc.visualstudio.com"
      	}
		}
	},
	"inputs": []
}
```
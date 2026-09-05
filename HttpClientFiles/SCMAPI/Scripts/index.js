

//// 組織基本要素
function getTimestamp() {
    const gtm = new Date(Date.UTC(1970, 0, 1));
    const utc = new Date();
    const localTime = new Date(utc.getTime() + 8 * 3600 * 1000);
    return Math.floor((localTime - gtm) / 1000);
}

const body = {
    "ShopId": 83,
    "CellPhone": "+6598505280",
    "RegisterSourceType": "Web",
    "RegisterDevice": "Chrome",
    "AppVersion": "1.2.3",
    "LocationId": 12,
    "LocationEmployeeId": 345,
    "MemberId": 123,
    "CountryCode": "65",
    "CountryProfileId": 35,
    "IsNotSendSmsAfterRegister": false,
    "IsUseRandomPassword": true,
    "RegisteredDateTime": "2025-12-11T16:20:00",
    "VipMemberId": 123,
    "IsOpen": false
};

// const API_URL = "http://api.qa1.my.91dev.tw";
// const APIKey = "1815fe08-7258-4e6a-b2a0-ed9743450e93";
// const SaltKey = "be84da03";

////MY PROD 200017
const API_URL = "https://api2.91app.com.my";
const APIKey = "fada146b-a28b-46f7-9a90-1174ab32ce59";
const SaltKey = "3f904682";
const Token = "45961234";


const ts = getTimestamp();


//// 取得 Signature
async function getSignature() {
    const bodyJson = JSON.stringify(body).toLowerCase();

    const content = `ts=${ts}&data=${bodyJson}&sk=${SaltKey}`;
    console.log("apiKey: " , APIKey);
    console.log("timestamp: ", ts);
    console.log("body: ", body);
    console.log("saltKey: ", SaltKey);
    console.log("content: ", content);
    const formData = new FormData();
    formData.append("content", content);
    formData.append("key", APIKey);

    const url = `${API_URL}/scm/v1/Sample/GetEncryptData`;

    const response = await fetch(url, { method: "POST", body: formData });
    const json = await response.json();
    console.log("content: ", json.Data);
    return json.Data;
}

//// 執行
async function sendMainRequest() {
    const signature = await getSignature();
    console.log("=============== apiKey=============================");
log(COLORS.magenta, "[apiKey] =", APIKey);
    console.log("===================timestamp=========================");
log(COLORS.yellow, "[timestamp] =", ts);
    console.log("===================signature=========================");
log(COLORS.green, "[signature] =", signature);
}

sendMainRequest();


// | 顏色     | 代碼         |
// | ------ | ---------- |
// | Reset  | `\x1b[0m`  |
// | **紅色** | `\x1b[31m` |
// | **綠色** | `\x1b[32m` |
// | **黃色** | `\x1b[33m` |
// | **藍色** | `\x1b[34m` |
// | **洋紅** | `\x1b[35m` |
// | **青色** | `\x1b[36m` |
// | **白色** | `\x1b[37m` |
// | **粗體** | `\x1b[1m`  |

function log(color, label, value) {
    console.log(`${color}${label} ${value}\x1b[0m`);
}

const COLORS = {
    red: "\x1b[31m",
    green: "\x1b[32m",
    yellow: "\x1b[33m",
    blue: "\x1b[34m",
    magenta: "\x1b[35m",
    cyan: "\x1b[36m",
    bold: "\x1b[1m"
};
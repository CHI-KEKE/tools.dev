// ============ Timestamp Function ============
function getTimestamp() {
    const gtm = new Date(Date.UTC(1970, 0, 1));
    const utc = new Date();
    const localTime = new Date(utc.getTime() + 8 * 3600 * 1000);
    return Math.floor((localTime - gtm) / 1000);
}

// ============ 固定測試 Body ============
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

// ============ API Key / Salt ============
// const API_URL = "http://api.qa1.hk.91dev.tw";
// const API_Key = "1815fe08-7258-4e6a-b2a0-ed9743450e93";
// const SaltKey = "be84da03";
const API_URL = "https://api2.91app.com.my";
const API_Key = "fada146b-a28b-46f7-9a90-1174ab32ce59";
const SaltKey = "3f904682";

// ============ 計算 Signature ============
async function getSignature() {
    const timestamp = getTimestamp();
    const bodyJson = JSON.stringify(body).toLowerCase();

    const content = `ts=${timestamp}&data=${bodyJson}&sk=${SaltKey}`;

    const formData = new FormData();
    formData.append("content", content);
    formData.append("key", API_Key);

    const signatureApiUrl = `${API_URL}/scm/v1/Sample/GetEncryptData`;

    const response = await fetch(signatureApiUrl, {
        method: "POST",
        body: formData
    });

    const json = await response.json();
    return json.Data;
}


// ============ 主 API Request ============
async function sendMainRequest() {
    const signature = await getSignature();

    const finalBody = {
        data: JSON.stringify(body)
    };

    const mainApiUrl = `${API_URL}/your/main/api/path`; // ← 改成你真正要打的 API

    const response = await fetch(mainApiUrl, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "Signature": signature
        },
        body: JSON.stringify(finalBody)
    });

    const result = await response.json();
    console.log("Response:", result);
}

// 執行
sendMainRequest();

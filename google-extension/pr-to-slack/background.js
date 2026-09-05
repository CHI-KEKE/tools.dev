const API_URL = 'https://api.infra.91app.io/v1/Ops/SlackSimple';
const API_KEY = 'zrAygatRzh1Xs8ozgqPiX3KeGLHpfGYX3xkP9BLq';

chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
  if (msg.action === 'sendSlack') {
    fetch(API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': API_KEY
      },
      body: JSON.stringify({
        slack_channel: msg.slackChannel,
        message: msg.text,
        broadcast: true,
        username: 'PR',
        icon: ':atom_symbol:',
        level: 'Info'
      })
    })
      .then(async (res) => {
        const body = await res.text().catch(() => '');
        if (res.ok) {
          sendResponse({ success: true });
        } else {
          sendResponse({ success: false, error: `HTTP ${res.status} ${res.statusText} — ${body}` });
        }
      })
      .catch((err) => sendResponse({ success: false, error: `${err.name}: ${err.message}` }));

    // 回傳 true 保持 sendResponse 非同步可用
    return true;
  }
});

// ── 訊息模板 ────────────────────────────────────────────
const TEMPLATES = {
  review: (title, url, headBranch, baseBranch) => {
    const branchLine = headBranch && baseBranch
      ? `\`${headBranch}\` => \`${baseBranch}\`\n`
      : '';
    return `<!here> from @allenlin\n*${title}*\n${branchLine}${url}\n`;
  },
  merged: (title, url) =>
    `✅ *PR 已 Merge*\n*${title}*\n${url}`,
  simple: (title, url) =>
    `*${title}*\n${url}`
};

const AI_REVIEW_LINE = '\n✅已確認 ai code review 結果';


function extractPRInfo() {
  const url = window.location.href;

  // ── 判斷平台 ──────────────────────────────────────────────
  const isGitHub    = /github\.com\/.+\/.+\/pull\/\d+/.test(url);
  const isGitLab    = /\/-\/merge_requests\/\d+/.test(url);
  const isBitbucket = !isGitHub && !isGitLab && /\/pull-requests\/\d+/.test(url);
  const isPR        = isGitHub || isGitLab || isBitbucket;

  let title      = '';
  let headBranch = '';
  let baseBranch = '';

  if (isGitHub) {
    // ── GitHub ─────────────────────────────────────────────
    const titleEl =
      document.querySelector('h1 .js-issue-title') ||
      document.querySelector('h1 bdi') ||
      document.querySelector('[data-testid="issue-title"]');
    title = titleEl?.innerText?.trim() || document.title.replace(/ by .+$/, '').trim();

    // 新版 GitHub UI
    const branchLinks = document.querySelectorAll('a.prc-BranchName-BranchName-CMTaU');
    baseBranch = branchLinks[0]?.innerText?.trim() || '';
    headBranch = branchLinks[1]?.innerText?.trim() || '';

    // 舊版 GitHub fallback
    if (!baseBranch) baseBranch = document.querySelector('.base-ref')?.innerText?.trim() || '';
    if (!headBranch) headBranch = document.querySelector('.head-ref')?.innerText?.trim() || '';

  } else if (isGitLab) {
    // ── GitLab ─────────────────────────────────────────────
    title = document.querySelector('h1[data-testid="title-content"]')?.innerText?.trim()
         || document.title.replace(/\s*[·|].*$/, '').trim();

    // ref-container：第1個=head(source)，第2個=base(target)
    // 用 title 屬性取得完整 branch 名（text 會被截斷）
    const refLinks = document.querySelectorAll('a.ref-container');
    headBranch = refLinks[0]?.getAttribute('title')?.trim() || refLinks[0]?.innerText?.trim() || '';
    baseBranch = refLinks[1]?.getAttribute('title')?.trim() || refLinks[1]?.innerText?.trim() || '';

  } else if (isBitbucket) {
    // ── Bitbucket ──────────────────────────────────────────
    title = document.querySelector('h1[tabindex="-1"]')?.innerText?.trim()
         || document.querySelector('h1')?.innerText?.trim()
         || document.title.replace(/\s*[·|—].*$/, '').trim();

    // data-qa="pr-branches-and-state-styles" 內有兩個 div[role="button"]
    // 格式：「Branch: repo:branch-name」或「repo:branch-name」
    // 第1個 = source (head)，第2個 = destination (base)
    const branchContainer = document.querySelector('[data-qa="pr-branches-and-state-styles"]');
    if (branchContainer) {
      const extractBranch = (btn) => {
        const raw = btn?.querySelector('span[aria-hidden="true"]')?.innerText?.trim()
                 || btn?.querySelector('span span')?.innerText?.trim()
                 || '';
        // 去掉 "Branch: " 前綴，再去掉 "repo:" 前綴，只保留 branch 名稱
        return raw.replace(/^Branch:\s*/i, '').replace(/^[^:]+:/, '').trim();
      };
      const branchBtns = branchContainer.querySelectorAll('div[role="button"]');
      headBranch = extractBranch(branchBtns[0]);
      baseBranch = extractBranch(branchBtns[1]);
    }
  }

  return { title, url, isPR, headBranch, baseBranch };
}

// ── DOM 元素 ─────────────────────────────────────────────
const prInfo         = document.getElementById('prInfo');
const msgArea        = document.getElementById('msgArea');
const slackChannelEl = document.getElementById('slackChannel');
const showBranchEl   = document.getElementById('showBranch');
const aiReviewEl     = document.getElementById('aiReview');
const autoSendEl     = document.getElementById('autoSend');
const sendBtn        = document.getElementById('sendBtn');
const resetBtn       = document.getElementById('resetBtn');
const statusEl       = document.getElementById('status');

let currentTitle      = '';
let currentUrl        = '';
let currentHeadBranch = '';
let currentBaseBranch = '';

// ── 初始化：抓資料 + 讀儲存的 Webhook ────────────────────
chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
  const tabId = tabs[0].id;

  // 讀已儲存的 Slack Channel & showBranch
  chrome.storage.local.get(['slackChannel', 'showBranch', 'aiReview', 'autoSend'], (data) => {
    if (data.slackChannel) slackChannelEl.value = data.slackChannel;
    if (data.showBranch === false) showBranchEl.checked = false;
    if (data.aiReview === true) aiReviewEl.checked = true;
    if (data.autoSend === false) autoSendEl.checked = false;
  });

  // 注入腳本抓 PR 資訊
  chrome.scripting.executeScript(
    { target: { tabId }, func: extractPRInfo },
    (results) => {
      if (chrome.runtime.lastError || !results?.[0]?.result) {
        prInfo.innerHTML = '<span style="color:#e01e5a">無法讀取頁面資訊</span>';
        return;
      }

      const { title, url, isPR, headBranch, baseBranch } = results[0].result;
      currentTitle      = title;
      currentUrl        = url;
      currentHeadBranch = headBranch;
      currentBaseBranch = baseBranch;

      if (!isPR) {
        prInfo.innerHTML =
          '<div class="not-pr">⚠️ 目前頁面不是 GitHub PR / GitLab MR / Bitbucket PR，請切換到正確頁面</div>';
        sendBtn.disabled = true;
      } else {
        prInfo.innerHTML = `
          <div class="pr-title">${escapeHtml(title)}</div>
          ${headBranch && baseBranch ? `<div class="pr-url">${escapeHtml(headBranch)} => ${escapeHtml(baseBranch)}</div>` : ''}
          <div class="pr-url">${escapeHtml(url)}</div>`;
        // 預設用 review 模板
        const branch = showBranchEl.checked ? headBranch : '';
        const base   = showBranchEl.checked ? baseBranch : '';
        msgArea.value = applyOptions(TEMPLATES.review(title, url, branch, base));
      }
    }
  );
});

// ── 模板按鈕 ─────────────────────────────────────────────
document.querySelectorAll('.tpl-btn').forEach((btn) => {
  btn.addEventListener('click', () => {
    const tpl = btn.dataset.tpl;
    if (TEMPLATES[tpl] && currentTitle) {
      const branch = showBranchEl.checked ? currentHeadBranch : '';
      const base   = showBranchEl.checked ? currentBaseBranch : '';
      msgArea.value = applyOptions(TEMPLATES[tpl](currentTitle, currentUrl, branch, base));
    }
  });
});

// ── showBranch checkbox ───────────────────────────────────
showBranchEl.addEventListener('change', () => {
  chrome.storage.local.set({ showBranch: showBranchEl.checked });
  if (currentTitle) {
    const branch = showBranchEl.checked ? currentHeadBranch : '';
    const base   = showBranchEl.checked ? currentBaseBranch : '';
    msgArea.value = applyOptions(TEMPLATES.review(currentTitle, currentUrl, branch, base));
  }
});

// ── autoSend checkbox ─────────────────────────────────────
autoSendEl.addEventListener('change', () => {
  chrome.storage.local.set({ autoSend: autoSendEl.checked });
  if (currentTitle) {
    const branch = showBranchEl.checked ? currentHeadBranch : '';
    const base   = showBranchEl.checked ? currentBaseBranch : '';
    msgArea.value = applyOptions(TEMPLATES.review(currentTitle, currentUrl, branch, base));
  }
});

// ── aiReview checkbox ─────────────────────────────────────
aiReviewEl.addEventListener('change', () => {
  chrome.storage.local.set({ aiReview: aiReviewEl.checked });
  msgArea.value = aiReviewEl.checked
    ? msgArea.value.replace(AI_REVIEW_LINE, '') + AI_REVIEW_LINE
    : msgArea.value.replace(AI_REVIEW_LINE, '');
});

// ── Slack Channel 自動儲存 ────────────────────────────────
slackChannelEl.addEventListener('blur', () => {
  const val = slackChannelEl.value.trim();
  if (val) chrome.storage.local.set({ slackChannel: val });
});

// ── 重置按鈕 ─────────────────────────────────────────────
resetBtn.addEventListener('click', () => {
  if (currentTitle) {
    const branch = showBranchEl.checked ? currentHeadBranch : '';
    const base   = showBranchEl.checked ? currentBaseBranch : '';
    msgArea.value = applyOptions(TEMPLATES.review(currentTitle, currentUrl, branch, base));
  }
  setStatus('');
});

// ── 發送按鈕 ─────────────────────────────────────────────
sendBtn.addEventListener('click', () => {
  const text         = msgArea.value.trim();
  const slackChannel = slackChannelEl.value.trim();

  if (!text)         { setStatus('❌ 訊息不能為空', 'err'); return; }
  if (!slackChannel) { setStatus('❌ 請填入 Slack Channel', 'err'); return; }

  sendBtn.disabled  = true;
  sendBtn.textContent = '發送中...';

  chrome.runtime.sendMessage(
    { action: 'sendSlack', text, slackChannel },
    (res) => {
      sendBtn.disabled  = false;
      sendBtn.textContent = '發送到 Slack ▶';
      if (res?.success) {
        setStatus('✅ 已成功發送到 Slack！', 'ok');
      } else {
        setStatus(`❌ ${res?.error || '未知錯誤'}`, 'err');
      }
    }
  );
});

// ── 工具函式 ─────────────────────────────────────────────
function applyOptions(text) {
  let result = autoSendEl.checked
    ? text
    : text.replace('<!here> from @allenlin', '@here');
  result = result.replace(AI_REVIEW_LINE, '');
  if (aiReviewEl.checked) result += AI_REVIEW_LINE;
  return result;
}

function setStatus(msg, type = '') {
  statusEl.textContent  = msg;
  statusEl.className    = type === 'ok' ? 'status-ok' : type === 'err' ? 'status-err' : '';
}

function escapeHtml(str) {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

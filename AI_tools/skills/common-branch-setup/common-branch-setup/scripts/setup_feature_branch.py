#!/usr/bin/env python3
"""
Git Feature Branch Setup Script

Ensures a clean git state and creates a properly-named feature branch
from an up-to-date main branch (develop / master / main).

Usage:
    python setup_feature_branch.py --vsts-id 123456 --name my-feature
    python setup_feature_branch.py  (interactive prompts)
    python setup_feature_branch.py --main-branch master --vsts-id 123456 --name my-feature
"""

import argparse
import subprocess
import sys


def run(cmd, capture=True, check=True):
    """Run a shell command and return (stdout, stderr, returncode)."""
    result = subprocess.run(
        cmd, shell=True, capture_output=capture, text=True,
        encoding="utf-8", errors="replace"
    )
    if check and result.returncode != 0:
        print(f"[ERROR] Command failed: {cmd}")
        print(result.stderr.strip())
        sys.exit(1)
    return result.stdout.strip(), result.stderr.strip(), result.returncode


def is_git_repo():
    _, _, code = run("git rev-parse --is-inside-work-tree", check=False)
    return code == 0


def current_branch():
    out, _, _ = run("git rev-parse --abbrev-ref HEAD")
    return out


def is_dirty():
    """Return True if there are any uncommitted, staged, or untracked changes."""
    out, _, _ = run("git status --porcelain")
    return bool(out)


def get_dirty_summary():
    out, _, _ = run("git status --short")
    return out


def prompt_choice(question, choices):
    """Simple numbered prompt; returns chosen index (0-based)."""
    print(f"\n{question}")
    for i, choice in enumerate(choices, 1):
        print(f"  {i}. {choice}")
    while True:
        raw = input("選擇 (輸入數字): ").strip()
        if raw.isdigit() and 1 <= int(raw) <= len(choices):
            return int(raw) - 1
        print("  請輸入有效的數字。")


def handle_dirty_state():
    """
    Offer user options when working tree is dirty.
    Returns stash_label if stashed, None otherwise.
    """
    print("\n[警告] 工作目錄有未提交的變更：")
    print(get_dirty_summary())

    idx = prompt_choice(
        "請選擇處理方式：",
        [
            "保留現有異動（stash → 建立新分支 → stash pop，變更會帶到新分支）",
            "自動 stash（stash → 建立新分支，變更保留在 stash 中）",
            "自行處理（結束腳本，請手動清理後再執行）",
        ],
    )

    if idx == 2:
        print("\n[結束] 請手動處理工作目錄後再執行此腳本。")
        sys.exit(0)

    # Both option 0 and 1 require stash
    label = "skill/feature-branch-setup"
    print(f"\n[執行] git stash push -u -m \"{label}\" ...")
    run(f'git stash push -u -m "{label}"')
    print("[OK] Stash 成功。")

    return label if idx == 0 else None  # None = don't pop later


def detect_main_branch():
    """
    Auto-detect the main integration branch of this repository.
    Priority: develop > master > main.
    Returns the branch name, or None if none of the candidates exist.
    """
    candidates = ["develop", "master", "main"]
    out, _, _ = run("git branch -a", check=False)
    existing = set()
    for line in out.splitlines():
        # strip leading '* ' or '  ', and strip 'remotes/origin/' prefix
        name = line.strip().lstrip("* ").strip()
        # normalise remote refs like 'remotes/origin/develop' → 'develop'
        if name.startswith("remotes/"):
            name = name.split("/", 2)[-1]
        existing.add(name)

    for candidate in candidates:
        if candidate in existing:
            return candidate
    return None


def ensure_on_main_branch(main_branch):
    """Switch to main_branch if currently on a feature branch or elsewhere."""
    branch = current_branch()
    if branch.startswith("feature/"):
        print(f"\n[偵測] 目前在 feature branch：{branch}")
        print(f"[執行] 切換回 {main_branch} ...")
        run(f"git checkout {main_branch}")
        print(f"[OK] 已切換至 {main_branch}。")
    elif branch != main_branch:
        print(f"\n[警告] 目前在 branch：{branch}（非 {main_branch} 也非 feature/*）")
        idx = prompt_choice(
            f"是否繼續切換至 {main_branch}？",
            [f"是，切換至 {main_branch}", "否，結束腳本"],
        )
        if idx == 1:
            print("[結束] 使用者取消。")
            sys.exit(0)
        run(f"git checkout {main_branch}")
        print(f"[OK] 已切換至 {main_branch}。")
    else:
        print(f"[OK] 目前已在 {main_branch} 分支。")


def get_remotes():
    """Return a list of configured remote names."""
    out, _, _ = run("git remote")
    return [r.strip() for r in out.splitlines() if r.strip()]


def sync_main_branch(main_branch):
    """Pull latest main_branch from upstream (if present) or origin."""
    remotes = get_remotes()

    if "upstream" in remotes:
        # Fork 架構：從 upstream 同步主線再 merge
        print("\n[執行] git fetch upstream ...")
        run("git fetch upstream")
        print("[OK] upstream fetch 完成。")
        print(f"[執行] git merge upstream/{main_branch} ...")
        run(f"git merge upstream/{main_branch}")
        print(f"[OK] {main_branch} 已與 upstream/{main_branch} 同步。")
    else:
        # 單一 remote：直接從 origin pull
        print(f"\n[執行] git pull origin {main_branch} ...")
        run(f"git pull origin {main_branch}")
        print(f"[OK] {main_branch} 已與 origin/{main_branch} 同步。")


def create_feature_branch(vsts_id, name):
    """Create and checkout feature/VSTS{id}-{name} from current head."""
    branch_name = f"feature/VSTS{vsts_id}-{name}"
    print(f"\n[執行] git checkout -b {branch_name} ...")
    run(f"git checkout -b {branch_name}")
    print(f"[OK] 已建立並切換至：{branch_name}")
    return branch_name


def restore_stash(label):
    """Pop the stash created by this script."""
    print(f"\n[執行] git stash pop (還原 \"{label}\") ...")
    run("git stash pop")
    print("[OK] 變更已還原至新分支。")


def main():
    parser = argparse.ArgumentParser(description="Git Feature Branch Setup")
    parser.add_argument("--vsts-id", help="VSTS Work Item ID（例如：123456）")
    parser.add_argument("--name", help="分支名稱描述（例如：add-login-page）")
    parser.add_argument(
        "--main-branch",
        help="主線分支名稱（例如：develop、master、main）。若不指定則自動偵測。",
    )
    args = parser.parse_args()

    # Validate git repo
    if not is_git_repo():
        print("[ERROR] 目前目錄不是 git repository。")
        sys.exit(1)

    print("=== Git Feature Branch Setup ===")

    # Detect or validate main branch
    if args.main_branch:
        main_branch = args.main_branch
        print(f"[設定] 主線分支（手動指定）：{main_branch}")
    else:
        main_branch = detect_main_branch()
        if main_branch is None:
            print("[ERROR] 無法自動偵測主線分支（找不到 develop / master / main）。")
            print("        請使用 --main-branch <name> 手動指定。")
            sys.exit(1)
        print(f"[偵測] 主線分支：{main_branch}")

    # Step 1: Handle dirty state
    stash_label = None
    if is_dirty():
        stash_label = handle_dirty_state()

    # Step 2: Ensure on main branch
    ensure_on_main_branch(main_branch)

    # Step 3: Sync main branch
    sync_main_branch(main_branch)

    # Step 4: Collect branch info
    vsts_id = args.vsts_id
    if not vsts_id:
        vsts_id = input("\n請輸入 VSTS Work Item ID（例如：123456）: ").strip()
    if not vsts_id.isdigit():
        print("[ERROR] VSTS ID 必須為數字。")
        sys.exit(1)

    name = args.name
    if not name:
        name = input("請輸入分支名稱描述（例如：add-login-page，只允許英文字母、數字、連字號）: ").strip()
    name = name.replace(" ", "-").lower()
    if not name:
        print("[ERROR] 分支名稱不可為空。")
        sys.exit(1)

    # Step 5: Create feature branch
    branch_name = create_feature_branch(vsts_id, name)

    # Step 6: Restore stash if "keep changes"
    if stash_label is not None:
        restore_stash(stash_label)

    print(f"\n✅ 完成！目前分支：{branch_name}")
    if stash_label is not None:
        print("   原有變更已帶入新分支。")
    elif stash_label == "":
        pass  # auto stash, changes still in stash
    print("   祝開發順利！")


if __name__ == "__main__":
    main()

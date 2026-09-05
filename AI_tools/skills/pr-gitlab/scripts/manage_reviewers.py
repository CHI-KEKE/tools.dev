#!/usr/bin/env python3
"""
GitLab Reviewer Registry Manager — manage default reviewers without creating a MR.

Usage:
    python manage_reviewers.py [command]

Commands:
    show       Show current reviewer settings for this repo
    set        Set default reviewers (select from project members)
    mode       Change reviewer mode (default / ask / none)
    clear      Remove this repo's entry from registry
    list       List all entries in the registry

If no command is given, shows current settings and presents options interactively.

Environment:
    GL_TOKEN   GitLab Personal Access Token (api scope) — required for 'set' command
    GL_HOST    GitLab instance URL (optional, defaults to https://gitlab.com)
"""

import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
import urllib.parse


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

REGISTRY_PATH = os.path.expanduser("~/.copilot/gitlab-reviewers-registry.md")

REGISTRY_TEMPLATE = """# GitLab Reviewers Registry

Maps repository names to their reviewer configuration.

Modes:
- `default` → use listed reviewers automatically
- `ask` → prompt user to select reviewers each time
- `none` → skip reviewers entirely

## Registry

| Repo Name | Mode | Reviewers | Notes |
|-----------|------|-----------|-------|

---

<!-- When adding a new entry, append a row to the table above. -->
<!-- Repo name = the root folder name of the git repository. -->
<!-- Reviewers: comma-separated GitLab usernames -->
"""


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def get_gitlab_host():
    return os.environ.get("GL_HOST", "https://gitlab.com").rstrip("/")


def get_gitlab_domain():
    host = get_gitlab_host()
    return re.sub(r"^https?://", "", host)


def run_silent(cmd):
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.returncode, result.stdout.strip()


def get_repo_name():
    code, root = run_silent(["git", "rev-parse", "--show-toplevel"])
    if code != 0:
        print("ERROR: not inside a git repository.", file=sys.stderr)
        sys.exit(1)
    return os.path.basename(root)


def parse_gitlab_remote(remote_name):
    """Parse a git remote URL -> path_with_namespace. Returns None if not GitLab."""
    code, url = run_silent(["git", "remote", "get-url", remote_name])
    if code != 0:
        return None
    domain = get_gitlab_domain()
    if domain not in url:
        return None
    match = re.search(re.escape(domain) + r"[:/](.+?)(?:\.git)?$", url)
    if match:
        return match.group(1)
    return None


def get_project_path():
    """Get the GitLab project path from remotes (prefer upstream, fallback origin)."""
    for remote in ["upstream", "origin"]:
        path = parse_gitlab_remote(remote)
        if path:
            return path
    print("ERROR: no GitLab remote found.", file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------------------
# GitLab API
# ---------------------------------------------------------------------------

def api_get(path, token):
    host = get_gitlab_host()
    url = host + "/api/v4" + path
    req = urllib.request.Request(url=url, headers={"PRIVATE-TOKEN": token})
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        print(f"ERROR: GitLab API (HTTP {exc.code})", file=sys.stderr)
        sys.exit(1)


def fetch_project_members(project_path, token):
    encoded = urllib.parse.quote(project_path, safe="")
    members = []
    page = 1
    while True:
        data = api_get(f"/projects/{encoded}/members/all?per_page=100&page={page}", token)
        if not data:
            break
        for m in data:
            if m.get("state") == "active":
                members.append({"id": m["id"], "username": m["username"], "name": m.get("name", m["username"])})
        if len(data) < 100:
            break
        page += 1
    return members


# ---------------------------------------------------------------------------
# Registry operations
# ---------------------------------------------------------------------------

def ensure_registry():
    if not os.path.exists(REGISTRY_PATH):
        os.makedirs(os.path.dirname(REGISTRY_PATH), exist_ok=True)
        with open(REGISTRY_PATH, "w", encoding="utf-8") as f:
            f.write(REGISTRY_TEMPLATE)


def read_registry():
    ensure_registry()
    registry = {}
    with open(REGISTRY_PATH, "r", encoding="utf-8") as f:
        content = f.read()
    for line in content.split("\n"):
        line = line.strip()
        if not line.startswith("|") or line.startswith("| Repo") or line.startswith("|---"):
            continue
        parts = [p.strip() for p in line.split("|")[1:-1]]
        if len(parts) >= 3:
            repo = parts[0]
            mode = parts[1]
            reviewers = parts[2] if len(parts) > 2 else ""
            notes = parts[3] if len(parts) > 3 else ""
            registry[repo] = {"mode": mode, "reviewers": reviewers, "notes": notes}
    return registry


def write_registry_entry(repo_name, mode, reviewers="", notes=""):
    ensure_registry()
    with open(REGISTRY_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    new_row = f"| {repo_name} | {mode} | {reviewers} | {notes} |"

    lines = content.split("\n")
    found = False
    for i, line in enumerate(lines):
        if line.strip().startswith("|") and repo_name in line:
            parts = [p.strip() for p in line.split("|")[1:-1]]
            if parts and parts[0] == repo_name:
                lines[i] = new_row
                found = True
                break

    if found:
        content = "\n".join(lines)
    else:
        insert_idx = None
        for i, line in enumerate(lines):
            if line.strip() == "---":
                insert_idx = i
                break
        if insert_idx is not None:
            lines.insert(insert_idx, new_row)
            content = "\n".join(lines)
        else:
            content = content.rstrip() + "\n" + new_row + "\n"

    with open(REGISTRY_PATH, "w", encoding="utf-8") as f:
        f.write(content)


def remove_registry_entry(repo_name):
    ensure_registry()
    with open(REGISTRY_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    lines = content.split("\n")
    new_lines = []
    removed = False
    for line in lines:
        if line.strip().startswith("|") and repo_name in line:
            parts = [p.strip() for p in line.split("|")[1:-1]]
            if parts and parts[0] == repo_name:
                removed = True
                continue
        new_lines.append(line)

    if removed:
        with open(REGISTRY_PATH, "w", encoding="utf-8") as f:
            f.write("\n".join(new_lines))
    return removed


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def cmd_show(repo_name):
    registry = read_registry()
    entry = registry.get(repo_name)
    print(f"\n  Repo: {repo_name}")
    if not entry:
        print("  Status: no configuration found")
        print("  (Run 'set' or 'mode' to configure)")
    else:
        print(f"  Mode: {entry['mode']}")
        if entry["reviewers"]:
            print(f"  Reviewers: {entry['reviewers']}")
        if entry.get("notes"):
            print(f"  Notes: {entry['notes']}")
    print()


def cmd_set(repo_name):
    token = os.environ.get("GL_TOKEN", "")
    if not token:
        print("ERROR: GL_TOKEN is required to fetch project members.", file=sys.stderr)
        print("  Run check_env.py for setup instructions.", file=sys.stderr)
        sys.exit(1)

    project_path = get_project_path()
    print(f"\n  Fetching members for: {project_path}")
    members = fetch_project_members(project_path, token)

    if not members:
        print("  No active members found.")
        return

    print(f"\n  Project members ({len(members)}):\n")
    for i, m in enumerate(members, start=1):
        print(f"    {i:2d}  {m['username']} ({m['name']})")

    print("\n  Enter numbers separated by commas (e.g., 1,3,5):")
    while True:
        sel = input("  > ").strip()
        if not sel:
            print("  Cancelled.")
            return
        try:
            indices = [int(x.strip()) for x in sel.split(",")]
            usernames = []
            valid = True
            for idx in indices:
                if 1 <= idx <= len(members):
                    usernames.append(members[idx - 1]["username"])
                else:
                    print(f"  Invalid number: {idx}")
                    valid = False
                    break
            if valid and usernames:
                write_registry_entry(repo_name, "default", ",".join(usernames))
                print(f"\n  ✓ Default reviewers set: {', '.join(usernames)}")
                return
        except ValueError:
            print("  Please enter numbers separated by commas.")


def cmd_mode(repo_name):
    print(f"\n  Select reviewer mode for '{repo_name}':\n")
    print("    1  default — use saved reviewer list")
    print("    2  ask     — prompt every time")
    print("    3  none    — skip reviewers entirely")
    print()

    while True:
        choice = input("  > ").strip()
        if choice == "1":
            registry = read_registry()
            entry = registry.get(repo_name)
            existing = entry["reviewers"] if entry else ""
            if existing:
                write_registry_entry(repo_name, "default", existing)
                print(f"\n  ✓ Mode set to 'default' (reviewers: {existing})")
            else:
                print("  No reviewers saved yet. Use 'set' command first to select reviewers.")
            return
        elif choice == "2":
            write_registry_entry(repo_name, "ask")
            print("\n  ✓ Mode set to 'ask' — will prompt for reviewers each time.")
            return
        elif choice == "3":
            write_registry_entry(repo_name, "none")
            print("\n  ✓ Mode set to 'none' — no reviewers will be assigned.")
            return
        else:
            print("  Please enter 1, 2, or 3.")


def cmd_clear(repo_name):
    if remove_registry_entry(repo_name):
        print(f"\n  ✓ Removed '{repo_name}' from registry.")
    else:
        print(f"\n  '{repo_name}' not found in registry.")


def cmd_list():
    registry = read_registry()
    if not registry:
        print("\n  Registry is empty.")
        print(f"  Path: {REGISTRY_PATH}")
        return

    print(f"\n  {'Repo':<25} {'Mode':<10} {'Reviewers'}")
    print("  " + "-" * 60)
    for repo, entry in sorted(registry.items()):
        reviewers = entry["reviewers"] or "—"
        print(f"  {repo:<25} {entry['mode']:<10} {reviewers}")
    print(f"\n  Registry path: {REGISTRY_PATH}")


def cmd_interactive(repo_name):
    """Interactive mode — show current and present options."""
    cmd_show(repo_name)
    print("  Available actions:\n")
    print("    1  Set default reviewers (從專案成員選取)")
    print("    2  Change mode (default / ask / none)")
    print("    3  Clear this repo's settings (移除設定)")
    print("    4  List all repos in registry")
    print("    5  Exit")
    print()

    while True:
        choice = input("  > ").strip()
        if choice == "1":
            cmd_set(repo_name)
            break
        elif choice == "2":
            cmd_mode(repo_name)
            break
        elif choice == "3":
            cmd_clear(repo_name)
            break
        elif choice == "4":
            cmd_list()
            break
        elif choice == "5":
            break
        else:
            print("  Please enter 1-5.")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    repo_name = get_repo_name()

    print("=" * 55)
    print("  pr-gitlab  /  Reviewer Manager")
    print("=" * 55)

    command = sys.argv[1] if len(sys.argv) > 1 else None

    if command == "show":
        cmd_show(repo_name)
    elif command == "set":
        cmd_set(repo_name)
    elif command == "mode":
        cmd_mode(repo_name)
    elif command == "clear":
        cmd_clear(repo_name)
    elif command == "list":
        cmd_list()
    else:
        cmd_interactive(repo_name)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
GitLab PR Creator — push current branch and create a Merge Request via GitLab REST API.

Usage:
    python create_pr.py

Environment:
    GL_TOKEN   GitLab Personal Access Token (api scope)
    GL_HOST    GitLab instance URL (optional, defaults to https://gitlab.com)

Reviewer registry:
    ~/.copilot/gitlab-reviewers-registry.md
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
# Git helpers
# ---------------------------------------------------------------------------

def run(cmd):
    """Run a shell command and return stdout; exit on failure."""
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print("ERROR: " + " ".join(cmd) + "\n" + result.stderr.strip(), file=sys.stderr)
        sys.exit(1)
    return result.stdout.strip()


def run_silent(cmd):
    """Run command, return (returncode, stdout)."""
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.returncode, result.stdout.strip()


def get_gitlab_host():
    return os.environ.get("GL_HOST", "https://gitlab.com").rstrip("/")


def get_gitlab_domain():
    host = get_gitlab_host()
    return re.sub(r"^https?://", "", host)


def parse_gitlab_remote(remote_name):
    """Parse a git remote URL -> {namespace, project, remote_name, path_with_namespace}.
    Returns None if not found or not matching GitLab domain."""
    code, url = run_silent(["git", "remote", "get-url", remote_name])
    if code != 0:
        return None

    domain = get_gitlab_domain()
    if domain not in url:
        return None

    # SSH: git@gitlab.com:namespace/project.git
    # HTTPS: https://gitlab.com/namespace/project.git
    match = re.search(re.escape(domain) + r"[:/](.+?)(?:\.git)?$", url)
    if match:
        path = match.group(1)
        parts = path.rsplit("/", 1)
        if len(parts) == 2:
            return {
                "namespace": parts[0],
                "project": parts[1],
                "path_with_namespace": path,
                "remote_name": remote_name,
            }
    return None


def get_current_branch():
    branch = run(["git", "rev-parse", "--abbrev-ref", "HEAD"])
    if branch == "HEAD":
        print("detached HEAD - cannot create MR.", file=sys.stderr)
        sys.exit(1)
    return branch


def get_last_commit_subject():
    result = subprocess.run(
        ["git", "log", "-1", "--pretty=format:%s"],
        capture_output=True, text=True, encoding="utf-8", errors="replace",
    )
    return result.stdout.strip() if result.returncode == 0 and result.stdout else ""


def get_commits_ahead_of_remote(target_remote, target_branch):
    """Get commit subjects ahead of remote target branch.
    Uses remote tracking ref to avoid stale local branch comparison.
    Returns list of commit subjects (newest first)."""
    # Fetch latest state of remote target branch
    fetch_result = subprocess.run(
        ["git", "fetch", target_remote, target_branch],
        capture_output=True, text=True,
    )
    if fetch_result.returncode != 0:
        return []

    ref = f"{target_remote}/{target_branch}"
    result = subprocess.run(
        ["git", "log", f"{ref}..HEAD", "--pretty=format:%s"],
        capture_output=True, text=True, encoding="utf-8", errors="replace",
    )
    if result.returncode != 0 or not result.stdout.strip():
        return []
    return [line for line in result.stdout.strip().split("\n") if line]


def prompt_mr_title(target_remote, target_branch, current_branch):
    """Determine MR title. If multiple commits, prompt user for confirmation."""
    commits = get_commits_ahead_of_remote(target_remote, target_branch)

    if len(commits) <= 1:
        # Single commit or no commits: use commit subject or branch name
        title = commits[0] if commits else (get_last_commit_subject() or current_branch)
        return title

    # Multiple commits: show list and ask user for title
    print("\n" + "=" * 50)
    print("MR Title (multiple commits detected)")
    print("=" * 50)
    print(f"\n  Found {len(commits)} commits:")
    for i, subj in enumerate(commits, start=1):
        print(f"    {i}. {subj}")
    print("\n  Please provide an MR title that summarizes these changes:")
    print()

    while True:
        user_input = input("> ").strip()
        if user_input:
            return user_input
        print("  Title cannot be empty. Please enter a title.")


def get_repo_name():
    """Return the root folder name of the git repository."""
    root = run(["git", "rev-parse", "--show-toplevel"])
    return os.path.basename(root)


# ---------------------------------------------------------------------------
# Remote resolution
# ---------------------------------------------------------------------------

def resolve_remotes():
    """
    Detect push remote (origin) and MR destination (upstream).

    Scenarios:
      origin + upstream  -> push to origin, MR: source=origin -> target=upstream
      only origin        -> push to origin, MR within origin
      only upstream      -> push to upstream, MR within upstream
      neither            -> exit with error
    """
    origin = parse_gitlab_remote("origin")
    upstream = parse_gitlab_remote("upstream")

    if origin and upstream:
        return origin, upstream

    if origin:
        print("INFO: no upstream GitLab remote found; MR will be created within origin.")
        return origin, origin

    if upstream:
        print("INFO: no origin GitLab remote found; will push and create MR within upstream.")
        return upstream, upstream

    print("ERROR: no GitLab remote found (checked: origin, upstream).", file=sys.stderr)
    print("  Run 'git remote -v' to verify your remote configuration.", file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------------------
# GitLab API helpers
# ---------------------------------------------------------------------------

def api_request(method, path, token, data=None):
    """Make a GitLab API request. Returns parsed JSON."""
    host = get_gitlab_host()
    url = host + "/api/v4" + path

    headers = {
        "PRIVATE-TOKEN": token,
        "Content-Type": "application/json",
    }

    body = json.dumps(data).encode("utf-8") if data else None
    req = urllib.request.Request(url=url, data=body, headers=headers, method=method)

    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        error_body = exc.read().decode("utf-8", errors="replace")
        if exc.code == 401:
            print("ERROR: HTTP 401 — Token 無效或已過期。", file=sys.stderr)
            print(f"  請重新建立 Token: {host}/-/user_settings/personal_access_tokens", file=sys.stderr)
        elif exc.code == 403:
            print("ERROR: HTTP 403 — Token scope 不足。", file=sys.stderr)
            print("  請確認 GL_TOKEN 建立時已勾選 'api' scope。", file=sys.stderr)
        elif exc.code == 409:
            print("ERROR: HTTP 409 — MR 已存在（相同 source/target branch）。", file=sys.stderr)
            # Try to extract existing MR URL
            try:
                err_data = json.loads(error_body)
                if "message" in err_data:
                    print(f"  {err_data['message']}", file=sys.stderr)
            except (json.JSONDecodeError, KeyError):
                pass
        else:
            print(f"ERROR: GitLab API (HTTP {exc.code}): {error_body}", file=sys.stderr)
        sys.exit(1)


def get_project_id(path_with_namespace, token):
    """Get the numeric project ID from path_with_namespace."""
    encoded = urllib.parse.quote(path_with_namespace, safe="")
    data = api_request("GET", f"/projects/{encoded}", token)
    return data["id"]


def fetch_project_members(project_id, token):
    """Fetch project members (active). Returns list of {id, username, name}."""
    members = []
    page = 1
    while True:
        data = api_request("GET", f"/projects/{project_id}/members/all?per_page=100&page={page}", token)
        if not data:
            break
        for m in data:
            if m.get("state") == "active":
                members.append({
                    "id": m["id"],
                    "username": m["username"],
                    "name": m.get("name", m["username"]),
                })
        if len(data) < 100:
            break
        page += 1
    return members


def fetch_branches_containing(project_id, keyword, token):
    """Return branch names that contain keyword."""
    encoded_keyword = urllib.parse.quote(keyword, safe="")
    data = api_request("GET", f"/projects/{project_id}/repository/branches?search={encoded_keyword}&per_page=20", token)
    return [b["name"] for b in data] if data else []


def get_default_branch(project_id, token):
    """Get the default branch of the project."""
    data = api_request("GET", f"/projects/{project_id}", token)
    return data.get("default_branch", "main")


# ---------------------------------------------------------------------------
# Interactive branch selection
# ---------------------------------------------------------------------------

def prompt_destination_branch(project_id, token, default_branch="main"):
    """
    Show default branch and accept any keyword to search remote branches.
    """
    print("\n" + "=" * 50)
    print("Select target branch:")
    print(f"  {default_branch}  (press Enter for default)")
    print("  (or type a keyword to search remote branches)")
    print("=" * 50 + "\n")

    while True:
        user_input = input("> ").strip()

        if not user_input or user_input == default_branch:
            return default_branch

        # Search for matching branches
        print(f"\nSearching for remote branches containing '{user_input}'...")
        matches = fetch_branches_containing(project_id, user_input, token)

        if not matches:
            print(f"  No remote branches found, using '{user_input}' as-is.")
            return user_input

        if len(matches) == 1:
            print(f"  Auto-selected: {matches[0]}")
            return matches[0]

        print(f"\nFound {len(matches)} matching branches:")
        for i, branch in enumerate(matches, start=1):
            print(f"  {i}  {branch}")
        print()

        while True:
            sel = input("Enter number: ").strip()
            if sel.isdigit() and 1 <= int(sel) <= len(matches):
                return matches[int(sel) - 1]
            print(f"  Please enter a number from 1 to {len(matches)}.")


# ---------------------------------------------------------------------------
# Reviewer registry
# ---------------------------------------------------------------------------

def ensure_registry():
    """Create registry file if it doesn't exist."""
    if not os.path.exists(REGISTRY_PATH):
        os.makedirs(os.path.dirname(REGISTRY_PATH), exist_ok=True)
        with open(REGISTRY_PATH, "w", encoding="utf-8") as f:
            f.write(REGISTRY_TEMPLATE)
        print(f"  Created reviewer registry: {REGISTRY_PATH}")


def read_registry():
    """Read registry and return dict of {repo_name: {mode, reviewers, notes}}."""
    ensure_registry()
    registry = {}
    with open(REGISTRY_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    # Parse markdown table rows
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
    """Add or update a registry entry."""
    ensure_registry()
    with open(REGISTRY_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    new_row = f"| {repo_name} | {mode} | {reviewers} | {notes} |"

    # Check if repo already exists — replace the line
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
        # Insert before the separator line "---"
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


# ---------------------------------------------------------------------------
# Reviewer selection
# ---------------------------------------------------------------------------

def select_reviewers_interactive(project_id, token):
    """Fetch members and let user select reviewers interactively.
    Accepts numbers, usernames, or a mix (comma-separated).
    Returns (list of user IDs, list of usernames)."""
    members = fetch_project_members(project_id, token)
    if not members:
        print("  No project members found.")
        return [], []

    username_map = {m["username"].lower(): m for m in members}

    print("\nProject members:")
    for i, m in enumerate(members, start=1):
        print(f"  {i}  {m['username']} ({m['name']})")
    print()
    print("Enter numbers or usernames separated by commas (e.g., 1,3,5 or john,jane), or 'none' to skip:")

    while True:
        sel = input("> ").strip()
        if sel.lower() == "none" or sel == "":
            return [], []

        parts = [x.strip() for x in sel.split(",") if x.strip()]
        selected = []
        usernames = []
        valid = True

        for part in parts:
            if part.isdigit():
                idx = int(part)
                if 1 <= idx <= len(members):
                    selected.append(members[idx - 1]["id"])
                    usernames.append(members[idx - 1]["username"])
                else:
                    print(f"  Invalid number: {idx} (valid range: 1-{len(members)}). Please try again.")
                    valid = False
                    break
            else:
                member = username_map.get(part.lower())
                if member:
                    selected.append(member["id"])
                    usernames.append(member["username"])
                else:
                    print(f"  Username not found: '{part}'. Please try again.")
                    valid = False
                    break

        if valid:
            return selected, usernames


def resolve_reviewers(project_id, token, repo_name):
    """Determine reviewers based on registry. Returns list of user IDs."""
    registry = read_registry()
    entry = registry.get(repo_name)

    if not entry:
        # First time — ask user for preference
        print("\n" + "=" * 50)
        print(f"  Reviewer 設定 (repo: {repo_name})")
        print("=" * 50)
        print("\n  No reviewer configuration found for this repo.")
        print("  How would you like to handle reviewers?\n")
        print("  1  Set default reviewers (選取預設 Reviewers)")
        print("  2  Ask every time (每次詢問)")
        print("  3  No reviewers (不需要 Reviewers)")
        print()

        while True:
            choice = input("> ").strip()
            if choice == "1":
                ids, usernames = select_reviewers_interactive(project_id, token)
                if usernames:
                    write_registry_entry(repo_name, "default", ",".join(usernames))
                    print(f"\n  Saved default reviewers: {', '.join(usernames)}")
                else:
                    write_registry_entry(repo_name, "none")
                    print("\n  No reviewers selected. Saved as 'none'.")
                return ids
            elif choice == "2":
                write_registry_entry(repo_name, "ask")
                print("\n  Saved: will ask for reviewers each time.")
                ids, _ = select_reviewers_interactive(project_id, token)
                return ids
            elif choice == "3":
                write_registry_entry(repo_name, "none")
                print("\n  Saved: no reviewers.")
                return []
            else:
                print("  Please enter 1, 2, or 3.")

    # Existing entry
    mode = entry["mode"]

    if mode == "none":
        return []

    if mode == "ask":
        ids, _ = select_reviewers_interactive(project_id, token)
        return ids

    if mode == "default":
        usernames = [u.strip() for u in entry["reviewers"].split(",") if u.strip()]
        if not usernames:
            ids, _ = select_reviewers_interactive(project_id, token)
            return ids

        # Resolve usernames to IDs directly without prompting
        print(f"\n  Using default reviewers: {', '.join(usernames)}")
        members = fetch_project_members(project_id, token)
        member_map = {m["username"]: m["id"] for m in members}
        ids = [member_map[u] for u in usernames if u in member_map]
        not_found = [u for u in usernames if u not in member_map]
        if not_found:
            print(f"  WARNING: could not resolve users: {', '.join(not_found)}")
        return ids

    return []


# ---------------------------------------------------------------------------
# MR creation
# ---------------------------------------------------------------------------

def create_pr(push_remote, mr_destination, destination_branch, token, reviewer_ids, dest_project_id, title):
    current_branch = get_current_branch()
    source_path = push_remote["path_with_namespace"]
    dest_path = mr_destination["path_with_namespace"]

    print(f"\nSource: {source_path}  (branch: {current_branch})")
    print(f"Target: {dest_path}  (branch: {destination_branch})")

    # Push current branch
    print(f"\nPushing '{current_branch}' to {push_remote['remote_name']}...")
    subprocess.run(["git", "push", push_remote["remote_name"], current_branch], check=True)
    print("Push OK\n")

    print("\nCreating MR...")
    print(f"  {source_path} ({current_branch})  ->  {dest_path} ({destination_branch})")
    print(f"  Title: {title}")

    payload = {
        "source_branch": current_branch,
        "target_branch": destination_branch,
        "title": title,
        "remove_source_branch": True,
    }

    # Fork MR: created on source project, targeting destination project
    if source_path != dest_path:
        source_project_id = get_project_id(source_path, token)
        payload["target_project_id"] = dest_project_id
        mr_data = api_request("POST", f"/projects/{source_project_id}/merge_requests", token, payload)
    else:
        mr_data = api_request("POST", f"/projects/{dest_project_id}/merge_requests", token, payload)

    mr_iid = mr_data["iid"]
    mr_project_id = mr_data["project_id"]

    # Assign reviewers if any
    if reviewer_ids:
        api_request("PUT", f"/projects/{mr_project_id}/merge_requests/{mr_iid}", token, {
            "reviewer_ids": reviewer_ids,
        })
        print(f"  Reviewers: {len(reviewer_ids)} reviewer(s) assigned.")

    print("\nMR created successfully!")
    print(f"  MR !{mr_iid}: {mr_data['title']}")
    print(f"  URL: {mr_data['web_url']}")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    token = os.environ.get("GL_TOKEN", "")
    if not token:
        print("ERROR: GL_TOKEN is not set.", file=sys.stderr)
        print("  Run check_env.py for setup instructions.", file=sys.stderr)
        sys.exit(1)

    push_remote, mr_destination = resolve_remotes()
    repo_name = get_repo_name()

    # Get destination project ID for branch search and default branch
    dest_project_id = get_project_id(mr_destination["path_with_namespace"], token)
    default_branch = get_default_branch(dest_project_id, token)

    destination_branch = prompt_destination_branch(dest_project_id, token, default_branch)

    # Determine MR title (prompts user if multiple commits)
    current_branch = get_current_branch()
    target_remote = mr_destination["remote_name"]
    title = prompt_mr_title(target_remote, destination_branch, current_branch)

    # Resolve reviewers
    reviewer_ids = resolve_reviewers(dest_project_id, token, repo_name)

    create_pr(push_remote, mr_destination, destination_branch, token, reviewer_ids, dest_project_id, title)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Bitbucket PR Creator — push current branch and create a PR via Bitbucket REST API.

Usage:
    python create_pr.py [--token TOKEN]

Environment:
    BB_TOKEN       Bitbucket API Token (Repositories:Read + Pull requests:Write)
    BB_USERNAME    Atlassian account email (required for Basic Auth)
    BB_PROJECT_KEY Bitbucket project key (optional; used for default reviewers)
"""

import argparse
import base64
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request


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


def parse_bitbucket_remote(remote_name):
    """Parse a git remote URL -> {workspace, repo, remote_name}. Returns None if not found."""
    result = subprocess.run(
        ["git", "remote", "get-url", remote_name],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        return None
    url = result.stdout.strip()
    match = re.search(r"bitbucket\.org[:/]([^/]+)/(.+?)(?:\.git)?$", url)
    if match:
        return {"workspace": match.group(1), "repo": match.group(2), "remote_name": remote_name}
    return None


def get_current_branch():
    """Return current branch name; exit if in detached HEAD."""
    branch = run(["git", "rev-parse", "--abbrev-ref", "HEAD"])
    if branch == "HEAD":
        print("detached HEAD - cannot create PR.", file=sys.stderr)
        sys.exit(1)
    return branch


def get_last_commit_subject():
    """Return the subject line of the most recent commit."""
    result = subprocess.run(
        ["git", "log", "-1", "--pretty=format:%s"],
        capture_output=True, text=True, encoding="utf-8", errors="replace",
    )
    return result.stdout.strip() if result.returncode == 0 and result.stdout else ""


# ---------------------------------------------------------------------------
# Remote resolution
# ---------------------------------------------------------------------------

def resolve_origin_remote():
    """
    Resolve the push remote (origin) with a two-step lookup:
      1. Try 'origin'            — must be a Bitbucket URL.
      2. Fallback to 'origin@bitbucket' — also validated as Bitbucket URL.
    Returns the remote dict or None if neither is found.
    """
    remote = parse_bitbucket_remote("origin")
    if remote:
        return remote

    remote = parse_bitbucket_remote("origin@bitbucket")
    if remote:
        print("INFO: 'origin' not found or not Bitbucket; using 'origin@bitbucket' as push remote.")
        return remote

    return None


def resolve_upstream_remote():
    """
    Resolve the PR destination (upstream) remote with a two-step lookup:
      1. Try 'upstream'            — must be a Bitbucket URL.
      2. Fallback to 'upstream@bitbucket' — also validated as Bitbucket URL.
    Returns the remote dict or None if neither is found.
    """
    remote = parse_bitbucket_remote("upstream")
    if remote:
        return remote

    remote = parse_bitbucket_remote("upstream@bitbucket")
    if remote:
        print("INFO: 'upstream' not found or not Bitbucket; using 'upstream@bitbucket' as PR destination.")
        return remote

    return None


def resolve_remotes():
    """
    Detect push remote (origin) and PR destination (upstream) and return both.

    Resolution order:
      push_remote  : origin  ->  origin@bitbucket  (fallback, both must be Bitbucket)
      pr_dest      : upstream  ->  upstream@bitbucket  (fallback, both must be Bitbucket)

    Scenarios:
      origin(-ish) + upstream(-ish)  -> push to origin,   PR: origin -> upstream
      only origin(-ish)              -> push to origin,   PR: origin -> origin
      only upstream(-ish)            -> error: cannot push to upstream (no write access)
      neither                        -> exit with error
    """
    origin   = resolve_origin_remote()
    upstream = resolve_upstream_remote()

    if origin and upstream:
        return origin, upstream

    if origin:
        print("INFO: no upstream Bitbucket remote found; PR will be created within origin.")
        return origin, origin

    if upstream:
        print("ERROR: found Bitbucket upstream (" + upstream["remote_name"] + ") but no Bitbucket origin fork.", file=sys.stderr)
        print("  Pushing directly to upstream is not allowed (no write access).", file=sys.stderr)
        print("  Please fork the repo and add your fork as 'origin' or 'origin@bitbucket':", file=sys.stderr)
        print("    git remote add origin@bitbucket https://bitbucket.org/<your-workspace>/" + upstream["repo"] + ".git", file=sys.stderr)
        sys.exit(1)

    print("ERROR: no Bitbucket remote found (checked: origin, origin@bitbucket, upstream, upstream@bitbucket).", file=sys.stderr)
    print("  Run 'git remote -v' to verify your remote configuration.", file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------------------
# Bitbucket API helpers
# ---------------------------------------------------------------------------

def _make_auth_header(token, username=""):
    """
    Build Authorization header.
    - If username is provided: Basic Auth (email:token) for personal API tokens.
    - Otherwise: Bearer token for Workspace/Repo access tokens.
    """
    if username:
        credentials = base64.b64encode((username + ":" + token).encode("utf-8")).decode("utf-8")
        return "Basic " + credentials
    return "Bearer " + token


def api_get(url, token, username=""):
    req = urllib.request.Request(url=url, headers={"Authorization": _make_auth_header(token, username)})
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))


def fetch_default_reviewers(workspace, project_key, token, username=""):
    """Fetch project-level default reviewers and return list of {uuid} dicts.

    Uses: GET /workspaces/{workspace}/projects/{project_key}/default-reviewers
    Response shape: values[].user.uuid
    """
    if not project_key:
        print("  Reviewers: BB_PROJECT_KEY not set, skipping default reviewers.")
        return []
    url = (
        "https://api.bitbucket.org/2.0/workspaces/" + workspace
        + "/projects/" + project_key + "/default-reviewers?pagelen=50"
    )
    try:
        data = api_get(url, token, username)
        reviewers = [
            {"uuid": v["user"]["uuid"]}
            for v in data.get("values", [])
            if v.get("user") and v["user"].get("uuid")
        ]
        print("  Reviewers: " + str(len(reviewers)) + " default reviewer(s) found.")
        return reviewers
    except urllib.error.HTTPError as exc:
        print("WARNING: could not fetch default reviewers (HTTP " + str(exc.code) + "), skipping.")
        return []


def fetch_branches_containing(workspace, repo, keyword, token, username=""):
    """Return branch names that contain keyword (server-side filter)."""
    url = (
        "https://api.bitbucket.org/2.0/repositories/" + workspace + "/" + repo
        + '/refs/branches?q=name~"' + keyword + '"&pagelen=20&sort=-target.date'
    )
    try:
        data = api_get(url, token, username)
        return [v["name"] for v in data.get("values", [])]
    except urllib.error.HTTPError as exc:
        print("WARNING: could not fetch branches (HTTP " + str(exc.code) + "), skipping search.")
        return []


# ---------------------------------------------------------------------------
# Interactive branch selection
# ---------------------------------------------------------------------------

def prompt_destination_branch(dest, token, username=""):
    """
    Show develop as default and accept any keyword to search remote branches:
      - Press Enter or type "develop" -> develop
      - Type any keyword -> search remote; auto-select if exactly one match, else show list
    """
    print("\n" + "="*50)
    print("Select target branch:")
    print("  develop  (press Enter for default)")
    print("  (or type a keyword to search remote branches)")
    print("="*50 + "\n")

    while True:
        user_input = input("> ").strip()

        if not user_input or user_input == "develop":
            return "develop"

        return _resolve_branch_by_keyword(dest, user_input, token, username)


def _resolve_branch_by_keyword(dest, keyword, token, username=""):
    """Search remote for branches containing keyword.
    Auto-select if exactly one match; show list if multiple."""
    print("\nSearching for remote branches containing '" + keyword + "'...")
    matches = fetch_branches_containing(dest["workspace"], dest["repo"], keyword, token, username)

    if not matches:
        print("  No remote branches found, using '" + keyword + "' as-is.")
        return keyword

    # Auto-select if exactly one match
    if len(matches) == 1:
        print("  Auto-selected: " + matches[0])
        return matches[0]

    print("\nFound " + str(len(matches)) + " matching branches:")
    for i, branch in enumerate(matches, start=1):
        print("  " + str(i) + "  " + branch)
    print()

    while True:
        sel = input("Enter number: ").strip()
        if sel.isdigit() and 1 <= int(sel) <= len(matches):
            return matches[int(sel) - 1]
        print("  Please enter a number from 1 to " + str(len(matches)) + ".")


# ---------------------------------------------------------------------------
# Token validation with guidance
# ---------------------------------------------------------------------------

def require_credentials(cli_token):
    """
    Return (token, username, project_key) from CLI arg or env vars.
    - BB_TOKEN:       Bitbucket API Token with scopes (Repositories:Read + Pull requests:Write)
    - BB_USERNAME:    Atlassian account email — required for Basic Auth with personal API tokens
    - BB_PROJECT_KEY: Bitbucket project key (e.g. YOUR_PROJECT_KEY) — optional; skips default reviewers if unset
    """
    token       = cli_token or os.environ.get("BB_TOKEN", "")
    username    = os.environ.get("BB_USERNAME", "")
    project_key = os.environ.get("BB_PROJECT_KEY", "")

    if token and username:
        if not project_key:
            print("WARNING: BB_PROJECT_KEY is not set — default reviewers will be skipped.")
            print("  Set it with: [System.Environment]::SetEnvironmentVariable(\"BB_PROJECT_KEY\", \"YOUR_KEY\", \"User\")\n")
        return token, username, project_key

    if not token:
        print("ERROR: BB_TOKEN is not set.\n")
    if not username:
        print("ERROR: BB_USERNAME is not set.\n")

    print("Both BB_TOKEN and BB_USERNAME are required.\n")
    print("Steps to create a Bitbucket API Token (with scopes):")
    print("  1. Go to: https://id.atlassian.com/manage-profile/security/api-tokens")
    print("  2. Click 'Create API token WITH SCOPES' (NOT the plain 'Create API token')")
    print("  3. Enter a name and expiry date -> Next")
    print("  4. Select App: [Bitbucket] -> Next  ⚠️  Must select Bitbucket, not Jira/Confluence")
    print("  5. Select Scopes: Repositories -> Read, Pull requests -> Write")
    print("  6. Click 'Create token' and copy it\n")
    print("Set as PERSISTENT USER environment variables:\n")
    print("  Windows (PowerShell):")
    print('    [System.Environment]::SetEnvironmentVariable("BB_TOKEN", "paste-your-token-here", "User")')
    print('    [System.Environment]::SetEnvironmentVariable("BB_USERNAME", "your@email.com", "User")')
    print('    [System.Environment]::SetEnvironmentVariable("BB_PROJECT_KEY", "YOUR_PROJECT_KEY", "User")')
    print("    # Then restart your terminal / IDE to load the new values\n")
    print("  macOS / Linux:")
    print('    echo \'export BB_TOKEN="paste-your-token-here"\' >> ~/.bashrc')
    print('    echo \'export BB_USERNAME="your@email.com"\' >> ~/.bashrc')
    print('    echo \'export BB_PROJECT_KEY="YOUR_PROJECT_KEY"\' >> ~/.bashrc')
    print("    source ~/.bashrc\n")
    print("Then re-run:")
    print("  python create_pr.py\n")
    sys.exit(1)


# ---------------------------------------------------------------------------
# PR creation
# ---------------------------------------------------------------------------

def create_pr(push_remote, pr_destination, destination_branch, token, username="", project_key=""):
    current_branch = get_current_branch()
    source_full    = push_remote["workspace"] + "/" + push_remote["repo"]
    dest_full      = pr_destination["workspace"] + "/" + pr_destination["repo"]

    print("\nSource: " + source_full + "  (branch: " + current_branch + ")")
    print("Target: " + dest_full + "  (branch: " + destination_branch + ")")

    # Title always comes from the last commit subject to avoid prompting the user
    title = get_last_commit_subject() or current_branch

    # Push current branch to the push remote
    print("\nPushing '" + current_branch + "' to " + push_remote["remote_name"] + "...")
    subprocess.run(["git", "push", push_remote["remote_name"], current_branch], check=True)
    print("Push OK\n")

    print("\nCreating PR...")
    print("  " + source_full + " (" + current_branch + ")  ->  " + dest_full + " (" + destination_branch + ")")
    print("  Title: " + title)
    reviewers = fetch_default_reviewers(pr_destination["workspace"], project_key, token, username)
    api_url = "https://api.bitbucket.org/2.0/repositories/" + dest_full + "/pullrequests"
    print()

    payload = {
        "title": title,
        "source": {
            "branch":     {"name": current_branch},
            "repository": {"full_name": source_full},
        },
        "destination": {
            "branch":     {"name": destination_branch},
            "repository": {"full_name": dest_full},
        },
        "close_source_branch": True,
    }
    if reviewers:
        payload["reviewers"] = reviewers

    req = urllib.request.Request(
        url=api_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": _make_auth_header(token, username),
            "Content-Type":  "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            print("PR created successfully!")
            print("  PR #" + str(data["id"]) + ": " + data["title"])
            print("  URL: " + data["links"]["html"]["href"])
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        if exc.code == 401:
            print("ERROR: HTTP 401 — Token 無效或已過期。", file=sys.stderr)
            print("  請重新建立 Token: https://id.atlassian.com/manage-profile/security/api-tokens", file=sys.stderr)
            print("  建立時務必選擇 App: Bitbucket（非 Jira / Confluence）", file=sys.stderr)
        elif exc.code == 403:
            print("ERROR: HTTP 403 — Token scope 不足。", file=sys.stderr)
            print("  請確認 BB_TOKEN 建立時已勾選以下 scopes:", file=sys.stderr)
            print("    read:project:bitbucket", file=sys.stderr)
            print("    read:pullrequest:bitbucket", file=sys.stderr)
            print("    read:repository:bitbucket", file=sys.stderr)
            print("    write:pullrequest:bitbucket", file=sys.stderr)
            print("  重新建立 Token: https://id.atlassian.com/manage-profile/security/api-tokens", file=sys.stderr)
        else:
            print("ERROR: Bitbucket API (HTTP " + str(exc.code) + "): " + body, file=sys.stderr)
        sys.exit(1)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Push current branch and create a Bitbucket PR."
    )
    parser.add_argument(
        "--token", default="",
        help="Bitbucket API Token (overrides BB_TOKEN env var)",
    )
    args = parser.parse_args()

    token, username, project_key = require_credentials(args.token)
    push_remote, pr_destination  = resolve_remotes()
    destination_branch           = prompt_destination_branch(pr_destination, token, username)

    create_pr(push_remote, pr_destination, destination_branch, token, username, project_key)


if __name__ == "__main__":
    main()

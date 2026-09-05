#!/usr/bin/env python3
"""
Pre-flight environment check for pr-bitbucket skill.

Checks:
  1. BB_TOKEN is set in environment
  2. BB_USERNAME is set in environment
  3. BB_PROJECT_KEY is set in environment (optional)
  4. Current directory is inside a git repository
  5. Current branch is not detached HEAD
  6. At least one Bitbucket remote (origin / upstream) exists

Exit codes:
  0  All checks passed
  1  One or more checks failed
"""

import os
import re
import subprocess
import sys


PASS = "[PASS]"
FAIL = "[FAIL]"
INFO = "[INFO]"
WARN = "[WARN]"


def run_silent(cmd: list) -> tuple:
    """Run command, return (returncode, stdout, stderr)."""
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.returncode, result.stdout.strip(), result.stderr.strip()


def check_token() -> bool:
    token = os.environ.get("BB_TOKEN", "")
    if token:
        masked = token[:4] + "*" * (len(token) - 8) + token[-4:] if len(token) > 8 else "****"
        print(f"{PASS} BB_TOKEN is set  ({masked})")
        return True

    print(f"{FAIL} BB_TOKEN is not set.\n")
    print("  ── Step 1: Create a Bitbucket API Token (with scopes) ────")
    print("  1. Go to: https://id.atlassian.com/manage-profile/security/api-tokens")
    print("  2. Click 'Create API token WITH SCOPES' (NOT the plain 'Create API token')")
    print("  3. Enter a name and expiry date -> Next")
    print("  4. Select App: [Bitbucket] -> Next  ⚠️  Must select Bitbucket, not Jira/Confluence")
    print("  5. Select Scopes:")
    print("       read:project:bitbucket")
    print("       read:pullrequest:bitbucket")
    print("       read:repository:bitbucket")
    print("       write:pullrequest:bitbucket")
    print("  6. Click 'Create token' and copy it")
    print()
    print("  ── Step 2: Set as PERSISTENT USER environment variables ──")
    print()
    print("  Windows (PowerShell):")
    print('    [System.Environment]::SetEnvironmentVariable("BB_TOKEN", "paste-your-token-here", "User")')
    print('    [System.Environment]::SetEnvironmentVariable("BB_USERNAME", "your@email.com", "User")')
    print("    # Restart your terminal / IDE after running this")
    print()
    print("  macOS / Linux (bash):")
    print('    echo \'export BB_TOKEN="paste-your-token-here"\' >> ~/.bashrc')
    print('    echo \'export BB_USERNAME="your@email.com"\' >> ~/.bashrc')
    print("    source ~/.bashrc")
    print()
    print("  macOS / Linux (zsh):")
    print('    echo \'export BB_TOKEN="paste-your-token-here"\' >> ~/.zshrc')
    print('    echo \'export BB_USERNAME="your@email.com"\' >> ~/.zshrc')
    print("    source ~/.zshrc")
    print()
    return False


def check_username() -> bool:
    username = os.environ.get("BB_USERNAME", "")
    if username:
        print(f"{PASS} BB_USERNAME is set  ({username})")
        return True

    print(f"{FAIL} BB_USERNAME is not set.\n")
    print("  BB_USERNAME must be your Atlassian account email (used for Basic Auth with BB_TOKEN).")
    print()
    print("  Windows (PowerShell):")
    print('    [System.Environment]::SetEnvironmentVariable("BB_USERNAME", "your@email.com", "User")')
    print("    # Restart your terminal / IDE after running this")
    print()
    print("  macOS / Linux:")
    print('    echo \'export BB_USERNAME="your@email.com"\' >> ~/.bashrc  # or ~/.zshrc')
    print()
    return False


def check_project_key() -> bool:
    project_key = os.environ.get("BB_PROJECT_KEY", "")
    if project_key:
        print(f"{PASS} BB_PROJECT_KEY is set  ({project_key})")
        return True

    print(f"{WARN} BB_PROJECT_KEY is not set — default reviewers will be skipped.\n")
    print("  BB_PROJECT_KEY is the Bitbucket project key (e.g. 'YOUR_PROJECT_KEY').")
    print("  Find it in: Bitbucket -> Your Project -> Settings -> Project details -> Key")
    print()
    print("  Windows (PowerShell):")
    print('    [System.Environment]::SetEnvironmentVariable("BB_PROJECT_KEY", "YOUR_KEY", "User")')
    print("    # Restart your terminal / IDE after running this")
    print()
    print("  macOS / Linux:")
    print('    echo \'export BB_PROJECT_KEY="YOUR_KEY"\' >> ~/.bashrc  # or ~/.zshrc')
    print()
    return True  # Optional — does not block PR creation


def check_git_repo() -> bool:
    code, _, _ = run_silent(["git", "rev-parse", "--git-dir"])
    if code == 0:
        code2, root, _ = run_silent(["git", "rev-parse", "--show-toplevel"])
        print(f"{PASS} Git repository found: {root}")
        return True
    print(f"{FAIL} Current directory is not inside a git repository.")
    return False


def check_branch() -> bool:
    code, branch, _ = run_silent(["git", "rev-parse", "--abbrev-ref", "HEAD"])
    if code != 0:
        print(f"{FAIL} Could not determine current branch.")
        return False
    if branch == "HEAD":
        print(f"{FAIL} Detached HEAD state — cannot create PR. Please checkout a named branch.")
        return False
    print(f"{PASS} Current branch: {branch}")
    return True


def check_remotes() -> bool:
    code, output, _ = run_silent(["git", "remote", "-v"])
    if code != 0 or not output:
        print(f"{FAIL} No git remotes configured.")
        return False

    found = []
    for remote in ["origin", "upstream"]:
        c, url, _ = run_silent(["git", "remote", "get-url", remote])
        if c == 0 and re.search(r"bitbucket\.org", url):
            found.append(remote)
            print(f"{PASS} Remote '{remote}': {url}")

    if not found:
        print(f"{FAIL} No Bitbucket remote (origin/upstream) found.")
        return False

    if len(found) == 1:
        print(f"{INFO} Only '{found[0]}' detected — PR will be created within this remote.")

    return True


def main():
    print("=" * 55)
    print("  pr-bitbucket  /  Environment Check")
    print("=" * 55 + "\n")

    results = [
        check_token(),
        check_username(),
        check_project_key(),
        check_git_repo(),
        check_branch(),
        check_remotes(),
    ]

    print("\n" + "=" * 55)
    passed = sum(results)
    total  = len(results)

    if all(results):
        print(f"  All {total} checks passed. Ready to run create_pr.py")
        print("=" * 55)
        sys.exit(0)
    else:
        print(f"  {passed}/{total} checks passed. Please fix the issues above.")
        print("=" * 55)
        sys.exit(1)


if __name__ == "__main__":
    main()

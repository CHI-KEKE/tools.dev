#!/usr/bin/env python3
"""
Pre-flight environment check for pr-gitlab skill.

Checks:
  1. GL_TOKEN is set in environment
  2. GL_HOST is valid (optional, defaults to https://gitlab.com)
  3. Current directory is inside a git repository
  4. Current branch is not detached HEAD
  5. At least one GitLab remote (origin / upstream) exists

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


def get_gitlab_host():
    """Return the GitLab host URL (from GL_HOST or default)."""
    return os.environ.get("GL_HOST", "https://gitlab.com").rstrip("/")


def get_gitlab_domain():
    """Extract domain from GL_HOST for remote URL matching."""
    host = get_gitlab_host()
    # Remove protocol
    domain = re.sub(r"^https?://", "", host)
    return domain


def check_token() -> bool:
    token = os.environ.get("GL_TOKEN", "")
    if token:
        masked = token[:4] + "*" * (len(token) - 8) + token[-4:] if len(token) > 8 else "****"
        print(f"{PASS} GL_TOKEN is set  ({masked})")
        return True

    print(f"{FAIL} GL_TOKEN is not set.\n")
    host = get_gitlab_host()
    print("  ── Step 1: Create a GitLab Personal Access Token ────")
    print(f"  1. Go to: {host}/-/user_settings/personal_access_tokens")
    print("  2. Click 'Add new token'")
    print("  3. Enter a name (e.g., 'copilot-mr') and expiry date")
    print("  4. Select scopes: [api] (full API access)")
    print("  5. Click 'Create personal access token' and copy it")
    print()
    print("  ── Step 2: Set as PERSISTENT USER environment variables ──")
    print()
    print("  Windows (PowerShell):")
    print('    [System.Environment]::SetEnvironmentVariable("GL_TOKEN", "paste-your-token-here", "User")')
    print("    # Restart your terminal / IDE after running this")
    print()
    print("  macOS / Linux (bash):")
    print('    echo \'export GL_TOKEN="paste-your-token-here"\' >> ~/.bashrc')
    print("    source ~/.bashrc")
    print()
    print("  macOS / Linux (zsh):")
    print('    echo \'export GL_TOKEN="paste-your-token-here"\' >> ~/.zshrc')
    print("    source ~/.zshrc")
    print()
    return False


def check_host() -> bool:
    host = get_gitlab_host()
    if host == "https://gitlab.com":
        print(f"{PASS} GL_HOST: {host} (default)")
    else:
        print(f"{PASS} GL_HOST: {host} (custom)")
    return True


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
        print(f"{FAIL} Detached HEAD state — cannot create MR. Please checkout a named branch.")
        return False
    print(f"{PASS} Current branch: {branch}")
    return True


def check_remotes() -> bool:
    code, output, _ = run_silent(["git", "remote", "-v"])
    if code != 0 or not output:
        print(f"{FAIL} No git remotes configured.")
        return False

    domain = get_gitlab_domain()
    found = []
    for remote in ["origin", "upstream"]:
        c, url, _ = run_silent(["git", "remote", "get-url", remote])
        if c == 0 and domain in url:
            found.append(remote)
            print(f"{PASS} Remote '{remote}': {url}")

    if not found:
        print(f"{FAIL} No GitLab remote (origin/upstream) found matching '{domain}'.")
        return False

    if len(found) == 1:
        print(f"{INFO} Only '{found[0]}' detected — MR will be created within this remote.")

    return True


def main():
    print("=" * 55)
    print("  pr-gitlab  /  Environment Check")
    print("=" * 55 + "\n")

    results = [
        check_token(),
        check_host(),
        check_git_repo(),
        check_branch(),
        check_remotes(),
    ]

    print("\n" + "=" * 55)
    passed = sum(results)
    total = len(results)

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

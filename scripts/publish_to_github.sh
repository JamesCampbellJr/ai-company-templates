#!/usr/bin/env bash
#
# publish_to_github.sh <org-name>
#
# Creates one GitHub repo per template under the given org and pushes it.
# Requires `gh` authenticated against github.com (run `gh auth login` first).
#
# The org must already exist (created in github.com/organizations/new) OR be
# your personal namespace (pass your username instead of an org).
set -euo pipefail

ORG="${1:-}"
if [[ -z "$ORG" ]]; then
  echo "Usage: $0 <github-org-or-username>" >&2
  exit 2
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI not found. Install from https://cli.github.com/" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: gh is not authenticated. Run: gh auth login" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATES_DIR="$ROOT/templates"

for tpl in "$TEMPLATES_DIR"/*/; do
  name="$(basename "$tpl")"
  repo="$ORG/$name"
  echo "==> Publishing $name -> $repo"

  # Initialize a throwaway git repo for the template subtree
  tmp="$(mktemp -d)"
  cp -r "$tpl/." "$tmp/"
  ( cd "$tmp"
    git init -q
    git config user.email "delivery@ai-company.local"
    git config user.name "AI-Company Delivery Bot"
    git add -A
    git commit -qm "Initial template: $name"
  )

  if gh repo view "$repo" >/dev/null 2>&1; then
    echo "    repo $repo already exists — pushing to default branch"
    default_branch="$(gh repo view "$repo" --json defaultBranchRef -q .defaultBranchRef.name)"
    ( cd "$tmp"
      git remote add origin "https://github.com/$repo.git"
      git push -q -u origin "HEAD:$default_branch"
    )
  else
    echo "    creating repo $repo"
    gh repo create "$repo" --private --source "$tmp" --push --description "AI-Company delivery template: $name" >/dev/null
  fi

  rm -rf "$tmp"
  echo "    done: https://github.com/$repo"
done

echo "All templates published under https://github.com/$ORG"

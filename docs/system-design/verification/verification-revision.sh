#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"

excluded='release-manifest.md|release-approval.md|release-scope.md|release-scope-approval.md|design-approval.md|system-design-fix-approval.md'
if test "$#" -eq 0; then
  {
    find docs/system-design/verification -maxdepth 1 -type f \
      \( -name '*.sh' -o -name '*.md' -o -name '*.tsv' \) -print0
    find docs/system-design/verification/approvals -maxdepth 1 -type f \
      -name '*.tsv' -print0
  } \
    | sort -z \
    | while IFS= read -r -d '' path; do
        if ! printf '%s\n' "${path##*/}" | rg -q "^(${excluded})$"; then sha256sum "$path"; fi
      done \
    | sha256sum | awk '{ print "sha256:" $1 }'
else
  revision="$1"
  git ls-tree -r --name-only "$revision" -- docs/system-design/verification \
    | awk -F/ '
        NF == 4 && ($0 ~ /\.sh$/ || $0 ~ /\.md$/ || $0 ~ /\.tsv$/) { print; next }
        NF == 5 && $4 == "approvals" && $0 ~ /\.tsv$/ { print }
      ' | sort \
    | while IFS= read -r path; do
        if ! printf '%s\n' "${path##*/}" | rg -q "^(${excluded})$"; then
          digest="$(git show "${revision}:${path}" | sha256sum | awk '{print $1}')"
          printf '%s  %s\n' "$digest" "$path"
        fi
      done \
    | sha256sum | awk '{ print "sha256:" $1 }'
fi

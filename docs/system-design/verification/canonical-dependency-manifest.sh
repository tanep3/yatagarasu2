#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"

if test "$#" -lt 1 || test "$#" -gt 2; then
  echo "usage: $0 CLOSED_DESIGN_IDS_FILE [SOURCE_COMMIT]" >&2
  exit 2
fi

ids="$1"
source_revision="${2:-WORKTREE}"
check_tmp="$(mktemp -d)"
trap 'rm -r "$check_tmp"' EXIT

if test "$source_revision" = WORKTREE; then
  cp docs/system-design/00-design-authority.md "$check_tmp/authority"
else
  git cat-file -e "$source_revision^{commit}"
  git show "$source_revision:docs/system-design/00-design-authority.md" > "$check_tmp/authority"
fi
sort -u "$ids" > "$check_tmp/ids"
diff -u "$ids" "$check_tmp/ids" >/dev/null

printf 'Design ID\tDirect dependency Design IDs\n'
while IFS= read -r design_id; do
  authority_row="$(awk -F '|' -v id="$design_id" '
    /^\| SD-/ { for(i=2;i<=10;i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i); if($2==id) print $4 "\t" $5 "\t" $10 }
  ' "$check_tmp/authority")"
  test "$(printf '%s\n' "$authority_row" | wc -l)" -eq 1
  IFS=$'\t' read -r ref state_owner supersedes <<< "$authority_row"
  target="${ref#*](}"; target="${target%)}"; canonical_path="${target%%#*}"
  if test "$source_revision" = WORKTREE; then
    source="docs/system-design/$canonical_path"
  else
    source="$check_tmp/source"
    git show "$source_revision:docs/system-design/$canonical_path" > "$source"
  fi
  {
    awk -v id="$design_id" '
      $0 ~ "^### " id "( | —)" { found=1 }
      found && emitted && /^##/ { exit }
      found { print; emitted=1 }
      END { if(!found) exit 1 }
    ' "$source"
    printf '%s\n%s\n' "$state_owner" "$supersedes"
  } | rg -o 'SD-[A-Z]+-[A-Z]+-[0-9]+' | rg -vx "$design_id" | sort -u > "$check_tmp/deps" || true
  while IFS= read -r dependency; do
    test -z "$dependency" || rg -qx "$dependency" "$check_tmp/ids"
  done < "$check_tmp/deps"
  if test -s "$check_tmp/deps"; then
    dependencies="$(paste -sd, "$check_tmp/deps")"
  else
    dependencies=—
  fi
  printf '%s\t%s\n' "$design_id" "$dependencies"
done < "$check_tmp/ids"

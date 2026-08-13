#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"

if test "$#" -lt 1 || test "$#" -gt 2; then
  echo "usage: $0 DESIGN_IDS_FILE [SOURCE_COMMIT]" >&2
  exit 2
fi

design_ids_file="$1"
source_revision="${2:-WORKTREE}"
authority=docs/system-design/00-design-authority.md
test -f "$design_ids_file"

check_tmp="$(mktemp -d)"
trap 'rm -r "$check_tmp"' EXIT

if test "$source_revision" = WORKTREE; then
  authority_source="$authority"
elif git cat-file -e "$source_revision^{commit}" 2>/dev/null; then
  authority_source="$check_tmp/authority"
  git show "$source_revision:$authority" > "$authority_source"
else
  echo "canonical definition source commit is not reachable: $source_revision" >&2
  exit 1
fi

sort "$design_ids_file" > "$check_tmp/ids-sorted"
sort -u "$design_ids_file" > "$check_tmp/ids-unique"
diff -u "$check_tmp/ids-sorted" "$check_tmp/ids-unique" >/dev/null

printf 'Design ID\tVersion\tCanonical ref\tDefinition SHA-256\n'
while IFS= read -r design_id; do
  test -n "$design_id"
  row="$(awk -F '|' -v id="$design_id" '
    /^\| SD-/ {
      for (i = 2; i <= 10; i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
      if ($2 == id) print $4 "\t" $8 "\t" $9
    }
  ' "$authority_source")"
  test "$(printf '%s\n' "$row" | wc -l)" -eq 1
  IFS=$'\t' read -r markdown_ref version status <<< "$row"
  case "$status" in draft|accepted|superseded) ;; *) exit 1 ;; esac

  target="${markdown_ref#*](}"
  target="${target%)}"
  canonical_path="${target%%#*}"
  anchor="${target#*#}"
  test "$canonical_path" != "$target"
  if test "$source_revision" = WORKTREE; then
    definition_source="docs/system-design/$canonical_path"
    test -f "$definition_source"
  else
    definition_source="$check_tmp/definition-source"
    if ! git show "$source_revision:docs/system-design/$canonical_path" > "$definition_source"; then
      echo "canonical definition source path is unavailable: $source_revision:docs/system-design/$canonical_path" >&2
      exit 1
    fi
  fi

  awk -v id="$design_id" '
    $0 ~ "^### " id "( | —)" { found=1 }
    found && emitted && /^##/ { exit }
    found { print; emitted=1 }
    END { if (!found) exit 1 }
  ' "$definition_source" > "$check_tmp/definition"
  test -s "$check_tmp/definition"
  definition_sha="sha256:$(sha256sum "$check_tmp/definition" | awk '{print $1}')"
  printf '%s\t%s\t%s\t%s\n' "$design_id" "$version" "$canonical_path#$anchor" "$definition_sha"
done < "$check_tmp/ids-unique"

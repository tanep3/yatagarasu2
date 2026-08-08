#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"

check_tmp="$(mktemp -d)"
trap 'rm -r "$check_tmp"' EXIT

rg -o --no-filename 'REQ-[A-Z]+-[0-9]+' docs/requirements/*.md | sort -u > "$check_tmp/source-req"
rg -o --no-filename '^[-*] AC-[A-Z]+-[0-9]+:' docs/requirements/*.md \
  | sed -E 's/^[-*] (AC-[A-Z]+-[0-9]+):/\1/' | sort -u > "$check_tmp/source-ac"

test "$(wc -l < "$check_tmp/source-req")" -eq 62
test "$(wc -l < "$check_tmp/source-ac")" -eq 214

rg -o --no-filename '\| AC-[A-Z]+-[0-9]+ \|' docs/system-design/verification/ac-inventory.md \
  | sed -E 's/^\| (AC-[A-Z]+-[0-9]+) \|$/\1/' | sort -u > "$check_tmp/inventory-ac"
diff -u "$check_tmp/source-ac" "$check_tmp/inventory-ac"

rg -o --no-filename '^### (SD-[A-Z]+-[A-Z]+-[0-9]+)' docs/system-design/contracts \
  | sed -E 's/^### //' | sort > "$check_tmp/canonical-all"
sort -u "$check_tmp/canonical-all" > "$check_tmp/canonical-unique"
diff -u "$check_tmp/canonical-all" "$check_tmp/canonical-unique"

rg -o --no-filename '^\| SD-[A-Z]+-[A-Z]+-[0-9]+ \|' docs/system-design/00-design-authority.md \
  | sed -E 's/^\| (SD-[A-Z]+-[A-Z]+-[0-9]+) \|$/\1/' | sort > "$check_tmp/authority-all"
sort -u "$check_tmp/authority-all" > "$check_tmp/authority-unique"
diff -u "$check_tmp/authority-all" "$check_tmp/authority-unique"
diff -u "$check_tmp/canonical-unique" "$check_tmp/authority-unique"

rg -o --no-filename 'SD-[A-Z]+-[A-Z]+-[0-9]+' docs/system-design/slices \
  | sort -u > "$check_tmp/slice-design-refs"
comm -23 "$check_tmp/slice-design-refs" "$check_tmp/canonical-unique" > "$check_tmp/missing-design-refs"
test ! -s "$check_tmp/missing-design-refs"

rg -o --no-filename '\| AC-[A-Z]+-[0-9]+ \|' docs/system-design/slices \
  | sed -E 's/^\| (AC-[A-Z]+-[0-9]+) \|$/\1/' | sort -u > "$check_tmp/slice-parent-ac"
comm -23 "$check_tmp/slice-parent-ac" "$check_tmp/source-ac" > "$check_tmp/missing-parent-ac"
test ! -s "$check_tmp/missing-parent-ac"

if rg -n 'SD-[A-Z]+-[A-Z]+-[0-9]+/[0-9]+|AC-[A-Z]+-[0-9]+[–/][0-9]+' docs/system-design/slices; then
  echo 'shorthand Design ID or non-atomic Parent AC found' >&2
  exit 1
fi

while IFS=: read -r source_file source_line markdown_target; do
  target="${markdown_target#](}"
  case "$target" in
    http://*|https://*|mailto:*|'') continue ;;
  esac
  target="${target%%#*}"
  test -z "$target" && continue
  if ! test -e "$(dirname "$source_file")/$target"; then
    echo "broken relative Markdown link: $source_file:$source_line -> $target" >&2
    exit 1
  fi
done < <(rg -n --no-heading --glob '*.md' -o '\]\([^#)[:space:]]+' docs/system-design || true)

git diff --check

printf 'PASS REQ=%s AC=%s canonical=%s parentAC=%s obligations=%s\n' \
  "$(wc -l < "$check_tmp/source-req")" \
  "$(wc -l < "$check_tmp/source-ac")" \
  "$(wc -l < "$check_tmp/canonical-unique")" \
  "$(wc -l < "$check_tmp/slice-parent-ac")" \
  "$(rg '^\| DO-' docs/system-design/slices/*.md | wc -l)"

#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"

if test "$#" -lt 3 || test "$#" -gt 4; then
  echo "usage: $0 DESIGN_IDS DEFINITIONS MANIFEST [SOURCE_COMMIT]" >&2
  exit 2
fi

ids="$1"; definitions="$2"; manifest="$3"; source_revision="${4:-WORKTREE}"
check_tmp="$(mktemp -d)"
trap 'rm -r "$check_tmp"' EXIT

if test "$source_revision" = WORKTREE; then
  shape_authority=docs/system-design/00-design-authority.md
else
  shape_authority="$check_tmp/shape-authority"
  git show "$source_revision:docs/system-design/00-design-authority.md" > "$shape_authority"
fi
docs/system-design/verification/check-dependency-manifest-shape.sh \
  "$shape_authority" "$ids" "$definitions" "$manifest"

tail -n +2 "$definitions" | cut -f1 > "$check_tmp/definition-ids"
diff -u "$ids" "$check_tmp/definition-ids"
tail -n +2 "$manifest" | cut -f1 > "$check_tmp/manifest-sources"
diff -u "$ids" "$check_tmp/manifest-sources"

docs/system-design/verification/canonical-definition-closure.sh "$ids" "$source_revision" > "$check_tmp/reclosed-ids"
diff -u "$ids" "$check_tmp/reclosed-ids"
docs/system-design/verification/canonical-dependency-manifest.sh "$ids" "$source_revision" > "$check_tmp/rebuilt-manifest"
diff -u "$manifest" "$check_tmp/rebuilt-manifest"

if test "$source_revision" = WORKTREE; then
  authority=docs/system-design/00-design-authority.md
else
  authority="$check_tmp/authority"
  git show "$source_revision:docs/system-design/00-design-authority.md" > "$authority"
fi
while IFS=$'\t' read -r source dependencies; do
  status="$(awk -F '|' -v id="$source" '/^\| SD-/ { for(i=2;i<=10;i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i); if($2==id) print $9 }' "$authority")"
  case "$status" in draft|accepted|superseded) ;; *) echo "invalid closure source status: $source=$status" >&2; exit 1 ;; esac
  test "$dependencies" = — && continue
  printf '%s\n' "$dependencies" | tr ',' '\n' | while IFS= read -r dependency; do
    test "$dependency" != "$source"
    rg -qx "$dependency" "$ids"
  done
done < <(tail -n +2 "$manifest")

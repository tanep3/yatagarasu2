#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"

docs/system-design/verification/check-system-design.sh

for slice in \
  docs/system-design/slices/01-camera-observation.md \
  docs/system-design/slices/02-finite-conversation.md \
  docs/system-design/slices/03-configuration-capability.md; do
  if ! test -f "$slice"; then
    echo "Design Pilot Gate pending: missing $slice" >&2
    exit 1
  fi
done

awk -F '|' '
  /^\| DO-/ {
    for (i = 2; i <= 12; i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
    if ($10 != "accounted-for" || $11 != "designed" ||
        $12 !~ /^(planned|implemented|passing|blocked-by-spike)$/) {
      print "Design Pilot Gate pending: " $2 " -> " $10 "/" $11 "/" $12 > "/dev/stderr"; exit 1
    }
  }
' docs/system-design/slices/*.md

check_tmp="$(mktemp -d)"
trap 'rm -r "$check_tmp"' EXIT

rg -o --no-filename 'SD-[A-Z]+-[A-Z]+-[0-9]+' docs/system-design/slices/*.md \
  | sort -u > "$check_tmp/referenced-design"
awk -F '|' '
  /^\| SD-/ {
    for (i = 2; i <= 10; i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
    if ($9 == "accepted") print $2
  }
' docs/system-design/00-design-authority.md | sort -u > "$check_tmp/accepted-design"
comm -23 "$check_tmp/referenced-design" "$check_tmp/accepted-design" > "$check_tmp/not-accepted"
if test -s "$check_tmp/not-accepted"; then
  echo 'Design Pilot Gate pending: referenced canonical contracts are not accepted' >&2
  exit 1
fi

approval=docs/system-design/verification/design-approval.md
current_revision="$(docs/system-design/verification/system-design-revision.sh)"
field_value() {
  local file="$1" field="$2"
  awk -F '|' -v field="$field" '
    /^\|/ {
      for (i = 2; i <= NF - 1; i++) gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i)
      if ($2 == field) print $3
    }
  ' "$file"
}
recorded_revision="$(field_value "$approval" 'System design revision')"
test "$recorded_revision" = "$current_revision"

> "$check_tmp/approval-refs"
> "$check_tmp/reviewed-design-all"
for pilot in A B C; do
  row="$(awk -F '|' -v pilot="Pilot $pilot" '
    /^\| Pilot/ {
      for (i = 2; i <= 9; i++) gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i)
      if ($2 == pilot) print $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9
    }
  ' "$approval")"
  test "$(printf '%s\n' "$row" | wc -l)" -eq 1
  IFS=$'\t' read -r status design_ids_ref design_ids_sha review_ref review_sha owner_ref owner_sha <<< "$row"
  test "$status" = "accepted"
  case "$design_ids_ref" in docs/system-design/verification/approvals/design-sets/*) ;; *) exit 1 ;; esac
  test -f "$design_ids_ref"
  test "$design_ids_sha" = "sha256:$(sha256sum "$design_ids_ref" | awk '{print $1}')"
  test ! -s <(comm -23 <(sort -u "$design_ids_ref") "$check_tmp/referenced-design")
  cat "$design_ids_ref" >> "$check_tmp/reviewed-design-all"
  for pair in "$review_ref|$review_sha" "$owner_ref|$owner_sha"; do
    ref="${pair%%|*}"; expected="${pair#*|}"
    case "$ref" in docs/system-design/verification/approvals/*) ;; *) exit 1 ;; esac
    test -f "$ref"
    test "$expected" = "sha256:$(sha256sum "$ref" | awk '{print $1}')"
    test "$(field_value "$ref" 'Pilot')" = "Pilot $pilot"
    test "$(field_value "$ref" 'System design revision')" = "$current_revision"
    printf '%s\n' "$ref" >> "$check_tmp/approval-refs"
  done
  test "$(field_value "$review_ref" 'Artifact type')" = "architecture-review"
  test "$(field_value "$review_ref" 'Design IDs Ref')" = "$design_ids_ref"
  test "$(field_value "$review_ref" 'Design IDs SHA-256')" = "$design_ids_sha"
  test "$(field_value "$review_ref" 'Verdict')" = "PASS"
  test "$(field_value "$review_ref" 'Unresolved Critical / High')" = "0"
  test "$(field_value "$owner_ref" 'Artifact type')" = "primary-approval"
  test "$(field_value "$owner_ref" 'Design IDs Ref')" = "$design_ids_ref"
  test "$(field_value "$owner_ref" 'Design IDs SHA-256')" = "$design_ids_sha"
  test "$(field_value "$owner_ref" 'Primary approval')" = "accepted"
done

sort "$check_tmp/approval-refs" > "$check_tmp/approval-refs-all"
sort -u "$check_tmp/approval-refs-all" > "$check_tmp/approval-refs-unique"
diff -u "$check_tmp/approval-refs-all" "$check_tmp/approval-refs-unique"
sort -u "$check_tmp/reviewed-design-all" > "$check_tmp/reviewed-design-union"
diff -u "$check_tmp/referenced-design" "$check_tmp/reviewed-design-union"

printf 'PASS(design-pilot-gate) revision=%s\n' \
  "$current_revision"

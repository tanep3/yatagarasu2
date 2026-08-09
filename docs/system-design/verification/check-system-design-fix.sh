#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"

docs/system-design/verification/check-design-pilot-gate.sh

field_value() {
  local file="$1" field="$2"
  awk -F '|' -v field="$field" '
    /^\|/ {
      for (i = 2; i <= NF - 1; i++) gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i)
      if ($2 == field) print $3
    }
  ' "$file"
}

test -f docs/system-design/system-design-guide.md
rg -q '\]\([^)]*contracts/[^#)]+#sd-[a-z]+-[a-z]+-[0-9]+' docs/system-design/system-design-guide.md

awk -F '|' '
  /^\| REQ-/ {
    for (i = 2; i <= 7; i++) gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i)
    rows++
    if ($6 != "accounted-for" || $7 != "covered") {
      print "AC inventory is not fully covered: " $3 " -> " $6 "/" $7 > "/dev/stderr"; exit 1
    }
  }
  END { if (rows != 214) exit 1 }
' docs/system-design/verification/ac-inventory.md

if rg -q '\| (draft|blocked-by-spike|blocked-by-owner) \|' docs/system-design/00-design-authority.md; then
  echo 'canonical contracts are not all accepted' >&2
  exit 1
fi

check_tmp="$(mktemp -d)"
trap 'rm -r "$check_tmp"' EXIT
awk -F '|' '
  /^\| SD-/ {
    for (i = 2; i <= 10; i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
    if ($9 == "accepted") print $2
  }
' docs/system-design/00-design-authority.md | sort -u > "$check_tmp/accepted-design"

fix_approval=docs/system-design/verification/system-design-fix-approval.md
test "$(field_value "$fix_approval" 'Artifact type')" = "system-design-fix-approval"
test "$(field_value "$fix_approval" 'System design revision')" = "$(docs/system-design/verification/system-design-revision.sh)"
test "$(field_value "$fix_approval" 'Status')" = "accepted"
design_ids_ref="$(field_value "$fix_approval" 'Accepted Design IDs Ref')"
design_ids_sha="$(field_value "$fix_approval" 'Accepted Design IDs SHA-256')"
case "$design_ids_ref" in docs/system-design/verification/approvals/design-sets/*) ;; *) exit 1 ;; esac
test -f "$design_ids_ref"
test "$design_ids_sha" = "sha256:$(sha256sum "$design_ids_ref" | awk '{print $1}')"
sort -u "$design_ids_ref" > "$check_tmp/approved-design"
diff -u "$check_tmp/accepted-design" "$check_tmp/approved-design"

for role in Review Primary; do
  if test "$role" = Review; then
    ref="$(field_value "$fix_approval" 'Architecture review Ref')"
    expected="$(field_value "$fix_approval" 'Review SHA-256')"
    artifact_type=system-design-review
    decision_field=Verdict
    decision_value=PASS
  else
    ref="$(field_value "$fix_approval" 'Primary approval Ref')"
    expected="$(field_value "$fix_approval" 'Approval SHA-256')"
    artifact_type=system-design-primary-approval
    decision_field='Primary approval'
    decision_value=accepted
  fi
  case "$ref" in docs/system-design/verification/approvals/*) ;; *) exit 1 ;; esac
  test -f "$ref"
  test "$expected" = "sha256:$(sha256sum "$ref" | awk '{print $1}')"
  test "$(field_value "$ref" 'Artifact type')" = "$artifact_type"
  test "$(field_value "$ref" 'System design revision')" = "$(docs/system-design/verification/system-design-revision.sh)"
  test "$(field_value "$ref" 'Accepted Design IDs Ref')" = "$design_ids_ref"
  test "$(field_value "$ref" 'Accepted Design IDs SHA-256')" = "$design_ids_sha"
  test "$(field_value "$ref" "$decision_field")" = "$decision_value"
done
test "$(field_value "$(field_value "$fix_approval" 'Architecture review Ref')" 'Unresolved Critical / High')" = "0"

printf 'PASS(system-design-fix) revision=%s\n' \
  "$(docs/system-design/verification/system-design-revision.sh)"

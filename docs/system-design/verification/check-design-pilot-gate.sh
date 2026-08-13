#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"

pilot_set=APR-PILOT-ABC-EE8F532A
pilot_tranche=TR-PILOT-ABC
pilot_ids=docs/system-design/verification/approvals/SD-REV-PILOT-C-001-design-ids.txt
pilot_definitions=docs/system-design/verification/approvals/SD-REV-PILOT-C-001-definitions.tsv
pilot_obligations=docs/system-design/verification/approvals/SD-REV-PILOT-C-001-obligations.tsv
pilot_obligations_sha=sha256:8019edd384e1fdbaa78072f05f3a4465ff4bed54e48cbdc103a8efe37ed9fc50
pilot_scope=docs/system-design/verification/approvals/TR-PILOT-ABC-scope.tsv
pilot_scope_sha=sha256:0c48ae0bb74a06f90de4986884c1965e45b4a697f16f8f573c37c63eea24cf43
assignments=docs/system-design/verification/obligation-assignments.tsv
tranches=docs/system-design/verification/expansion-tranches.tsv

docs/system-design/verification/check-design-approvals.sh
docs/system-design/verification/check-system-design.sh

check_tmp="$(mktemp -d)"
trap 'rm -r "$check_tmp"' EXIT

test "sha256:$(sha256sum "$pilot_obligations" | awk '{print $1}')" = "$pilot_obligations_sha"
test "sha256:$(sha256sum "$pilot_scope" | awk '{print $1}')" = "$pilot_scope_sha"
test "$(tail -n +2 "$pilot_obligations" | wc -l)" -eq 184
tail -n +2 "$pilot_obligations" | cut -f1 | sort > "$check_tmp/pilot-obligation-ids"
sort -u "$check_tmp/pilot-obligation-ids" > "$check_tmp/pilot-obligation-ids-unique"
diff -u "$check_tmp/pilot-obligation-ids" "$check_tmp/pilot-obligation-ids-unique"

# Future tranche/slice rows are outside this Gate. Review-time and current meaning must both match
# the immutable 184-row Pilot snapshot, including routing, obligation semantics and proof design.
pilot_source_commit=1eafd3deab687e29c3d81609ae0959823e246165
docs/system-design/verification/obligation-review-set.sh \
  "$assignments" "$pilot_tranche" "$pilot_source_commit" > "$check_tmp/reviewed-pilot-obligations"
diff -u "$pilot_obligations" "$check_tmp/reviewed-pilot-obligations"
docs/system-design/verification/obligation-review-set.sh \
  "$assignments" "$pilot_tranche" WORKTREE > "$check_tmp/current-pilot-obligations"
diff -u "$pilot_obligations" "$check_tmp/current-pilot-obligations"

> "$check_tmp/pilot-design-refs-all"
while IFS=$'\t' read -r obligation_id parent_ac package_id tranche_id storage_ref meaning_sha joint_group contribution design_refs proof_type negative_case target_scope accounting design proof blocker; do
  test "$tranche_id" = "$pilot_tranche"
  storage_file="${storage_ref%%::*}"
  storage_id="${storage_ref##*::}"
  test "$storage_id" = "$obligation_id"
  test -f "$storage_file"
  if test "$accounting" != accounted-for || test "$design" != designed || \
     ! printf '%s\n' "$proof" | rg -q '^(planned|implemented|passing|blocked-by-spike)$'; then
    echo "Design Pilot Gate pending: $obligation_id -> $accounting/$design/$proof" >&2
    exit 1
  fi
  printf '%s\n' "$design_refs" | tr ',' '\n' | sed 's/^[[:space:]]*//' \
    >> "$check_tmp/pilot-design-refs-all"
done < <(tail -n +2 "$pilot_obligations")

sort -u "$check_tmp/pilot-design-refs-all" > "$check_tmp/pilot-design-refs"
sort -u "$pilot_ids" > "$check_tmp/pilot-approved-design"
comm -23 "$check_tmp/pilot-design-refs" "$check_tmp/pilot-approved-design" \
  > "$check_tmp/unapproved-pilot-refs"
if test -s "$check_tmp/unapproved-pilot-refs"; then
  echo 'Pilot obligation references outside immutable approval set:' >&2
  cat "$check_tmp/unapproved-pilot-refs" >&2
  exit 1
fi

tranche_row="$(awk -F '\t' -v id="$pilot_tranche" 'NR > 1 && $1 == id { print }' "$tranches")"
test "$(printf '%s\n' "$tranche_row" | wc -l)" -eq 1
IFS=$'\t' read -r tranche_id package_ids parent_count obligation_count parent_limit obligation_limit dependencies review_status approval_set limit_exception reviewed_revision provenance <<< "$tranche_row"
test "$parent_count" -eq 128
test "$obligation_count" -eq 184
test "$review_status" = accepted
test "$approval_set" = "$pilot_set"
test "$limit_exception" = design-pilot-baseline

docs/system-design/verification/tranche-review-set.sh \
  "$assignments" "$tranches" "$pilot_tranche" "$pilot_definitions" "$pilot_obligations" \
  > "$check_tmp/current-pilot-scope"
diff -u "$pilot_scope" "$check_tmp/current-pilot-scope"

printf 'PASS(design-pilot-gate) approval_set=%s definitions=%s obligations=%s\n' \
  "$pilot_set" "sha256:89c749815303b3aa6ca9e2bcf914dc36fa411c27fbb18f057ab84fb3cfea1fd9" \
  "$(wc -l < "$check_tmp/pilot-obligation-ids")"

#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"

require_all=false
if test "${1:-}" = --require-all-accepted; then
  require_all=true
elif test "$#" -ne 0; then
  echo "usage: $0 [--require-all-accepted]" >&2
  exit 2
fi

manifest=docs/system-design/verification/design-approval.md
authority=docs/system-design/00-design-authority.md
check_tmp="$(mktemp -d)"
trap 'rm -r "$check_tmp"' EXIT

field_value() {
  local file="$1" field="$2"
  awk -F '|' -v field="$field" '
    /^\|/ {
      for (i = 2; i <= NF - 1; i++) gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i)
      if ($2 == field) print $3
    }
  ' "$file"
}

bullet_value() {
  local file="$1" field="$2"
  awk -v field="$field" '
    index($0, "- " field ": `") == 1 {
      value=$0
      sub("^- " field ": `", "", value)
      sub("`$", "", value)
      print value
    }
  ' "$file"
}

test "$(field_value "$manifest" 'Manifest version')" = 1
test "$(field_value "$manifest" 'Status')" = active
test "$(field_value "$manifest" 'Aggregation')" = append-only-content-addressed-approval-sets

# Once an Approval set is committed, its Manifest row and every referenced Artifact are immutable.
# New work appends a new content-addressed row; it never rewrites prior approval history.
if git cat-file -e "HEAD:$manifest" 2>/dev/null; then
  git show "HEAD:$manifest" > "$check_tmp/prior-manifest"
  awk '/^\| APR-/ { print }' "$check_tmp/prior-manifest" > "$check_tmp/prior-approval-rows"
  while IFS= read -r prior_row; do
    approval_id="$(printf '%s\n' "$prior_row" | awk -F '|' '{x=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", x); print x}')"
    current_row="$(awk -F '|' -v id="$approval_id" '
      /^\| APR-/ { x=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", x); if (x == id) print }
    ' "$manifest")"
    if test "$current_row" != "$prior_row"; then
      echo "committed approval row changed or was removed: $approval_id" >&2
      exit 1
    fi
    printf '%s\n' "$prior_row" | awk -F '|' '{ print $5 "\n" $7 "\n" $9 "\n" $11 }' \
      | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
      | while IFS= read -r prior_ref; do
          test -n "$prior_ref"
          if ! git cat-file -e "HEAD:$prior_ref" 2>/dev/null; then
            echo "committed approval artifact missing from base: $approval_id -> $prior_ref" >&2
            exit 1
          fi
          if ! test -f "$prior_ref" || \
             test "$(sha256sum "$prior_ref" | awk '{print $1}')" != "$(git show "HEAD:$prior_ref" | sha256sum | awk '{print $1}')"; then
            echo "committed approval artifact changed or was removed: $approval_id -> $prior_ref" >&2
            exit 1
          fi
        done
  done < "$check_tmp/prior-approval-rows"
fi

> "$check_tmp/approval-sets"
> "$check_tmp/approved-definitions-all"
approval_rows=0
while IFS=$'\t' read -r approval_set status ids_ref ids_sha definitions_ref definitions_sha review_ref review_sha owner_ref owner_sha; do
  approval_rows=$((approval_rows + 1))
  test "$status" = accepted
  printf '%s\n' "$approval_set" >> "$check_tmp/approval-sets"

  for ref in "$ids_ref" "$definitions_ref" "$review_ref" "$owner_ref"; do
    case "$ref" in docs/system-design/verification/approvals/*) ;; *) echo "approval ref outside approvals/: $ref" >&2; exit 1 ;; esac
    test -f "$ref"
  done
  test "$ids_sha" = "sha256:$(sha256sum "$ids_ref" | awk '{print $1}')"
  test "$definitions_sha" = "sha256:$(sha256sum "$definitions_ref" | awk '{print $1}')"
  test "$review_sha" = "sha256:$(sha256sum "$review_ref" | awk '{print $1}')"
  test "$owner_sha" = "sha256:$(sha256sum "$owner_ref" | awk '{print $1}')"

  combined_identity="$({ cat "$ids_ref"; cat "$definitions_ref"; } | sha256sum | awk '{print $1}')"
  expected_suffix="$(printf '%s' "${combined_identity:0:8}" | tr '[:lower:]' '[:upper:]')"
  case "$approval_set" in *-"$expected_suffix") ;; *) echo "approval set is not content-addressed: $approval_set" >&2; exit 1 ;; esac

  sort "$ids_ref" > "$check_tmp/ids-sorted"
  sort -u "$ids_ref" > "$check_tmp/ids-unique"
  diff -u "$check_tmp/ids-sorted" "$check_tmp/ids-unique"
  awk '/^SD-[A-Z]+-[A-Z]+-[0-9]+$/ { next } { exit 1 }' "$check_tmp/ids-unique"

  source_commit="$(field_value "$review_ref" 'Source commit')"
  if ! git cat-file -e "$source_commit^{commit}" 2>/dev/null; then
    echo "approval source commit is not reachable: $approval_set -> $source_commit" >&2
    exit 1
  fi
  docs/system-design/verification/canonical-definition-set.sh "$ids_ref" "$source_commit" \
    > "$check_tmp/reviewed-definitions"
  diff -u "$definitions_ref" "$check_tmp/reviewed-definitions"
  docs/system-design/verification/canonical-definition-set.sh "$ids_ref" > "$check_tmp/current-definitions"
  diff -u "$definitions_ref" "$check_tmp/current-definitions"
  tail -n +2 "$definitions_ref" | cut -f1 | sort > "$check_tmp/definition-ids"
  diff -u "$check_tmp/ids-unique" "$check_tmp/definition-ids"

  tail -n +2 "$definitions_ref" \
    | awk -F '\t' '{ print $1 "@" $2 "\t" $3 "\t" $4 }' \
    >> "$check_tmp/approved-definitions-all"

  for artifact in "$review_ref" "$owner_ref"; do
    test "$(field_value "$artifact" 'Approval set')" = "$approval_set"
    test "$(field_value "$artifact" 'Design IDs Ref')" = "$ids_ref"
    test "$(field_value "$artifact" 'Design IDs SHA-256')" = "$ids_sha"
    test "$(field_value "$artifact" 'Definitions Ref')" = "$definitions_ref"
    test "$(field_value "$artifact" 'Definitions SHA-256')" = "$definitions_sha"
    source_commit="$(field_value "$artifact" 'Source commit')"
    reviewed_revision="$(field_value "$artifact" 'System design revision')"
    test -n "$source_commit"
    test -n "$reviewed_revision"
    test "$reviewed_revision" = "$(docs/system-design/verification/system-design-revision.sh "$source_commit")"
  done
  test "$(field_value "$review_ref" 'Artifact type')" = architecture-review
  test "$(field_value "$review_ref" 'Verdict')" = PASS
  test "$(field_value "$review_ref" 'Unresolved Critical / High')" = 0
  test "$(field_value "$owner_ref" 'Artifact type')" = primary-approval
  test "$(field_value "$owner_ref" 'Primary approval')" = accepted
done < <(awk -F '|' '
  /^\| APR-/ {
    for (i = 2; i <= 12; i++) gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i)
    print $2 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" $11 "\t" $12
  }
' "$manifest")
test "$approval_rows" -gt 0
sort "$check_tmp/approval-sets" > "$check_tmp/approval-sets-sorted"
sort -u "$check_tmp/approval-sets" > "$check_tmp/approval-sets-unique"
diff -u "$check_tmp/approval-sets-sorted" "$check_tmp/approval-sets-unique"

# 同じID/versionを複数trancheが再審査してもよいが、異なるref/hashは承認できない。
awk -F '\t' '
  { value=$2 "\t" $3 }
  seen[$1] && prior[$1] != value { print "conflicting approved definition: " $1 > "/dev/stderr"; exit 1 }
  { seen[$1]=1; prior[$1]=value }
' "$check_tmp/approved-definitions-all"
sort -u "$check_tmp/approved-definitions-all" > "$check_tmp/approved-definitions"

# Pilot approval setは既知の審査集合から拡張不能にする。
pilot_set=APR-PILOT-ABC-EE8F532A
pilot_ids_sha=sha256:bb9634eedb025fe747e4e03829896861f8d2e94974431de2b5b5246d9cafd7b3
pilot_definitions_sha=sha256:89c749815303b3aa6ca9e2bcf914dc36fa411c27fbb18f057ab84fb3cfea1fd9
pilot_obligations_sha=sha256:8019edd384e1fdbaa78072f05f3a4465ff4bed54e48cbdc103a8efe37ed9fc50
pilot_scope_sha=sha256:0c48ae0bb74a06f90de4986884c1965e45b4a697f16f8f573c37c63eea24cf43
pilot_change_set=docs/system-design/verification/change-sets/SD-REV-PILOT-C-001.md
test "$(rg -c "^\\| $pilot_set \\|" "$manifest")" -eq 1
test "$(bullet_value "$pilot_change_set" 'approval set')" = "$pilot_set"
test "$(bullet_value "$pilot_change_set" 'Design IDs SHA-256')" = "$pilot_ids_sha"
test "$(bullet_value "$pilot_change_set" 'Definitions SHA-256')" = "$pilot_definitions_sha"
pilot_ids_ref="$(bullet_value "$pilot_change_set" 'Design IDs Ref')"
pilot_definitions_ref="$(bullet_value "$pilot_change_set" 'Definitions Ref')"
pilot_obligations_ref="$(bullet_value "$pilot_change_set" 'Pilot Obligations Ref')"
pilot_scope_ref="$(bullet_value "$pilot_change_set" 'Tranche Scope Ref')"
test "sha256:$(sha256sum "$pilot_ids_ref" | awk '{print $1}')" = "$pilot_ids_sha"
test "sha256:$(sha256sum "$pilot_definitions_ref" | awk '{print $1}')" = "$pilot_definitions_sha"
test "$(bullet_value "$pilot_change_set" 'Pilot Obligations SHA-256')" = "$pilot_obligations_sha"
test "sha256:$(sha256sum "$pilot_obligations_ref" | awk '{print $1}')" = "$pilot_obligations_sha"
test "$(bullet_value "$pilot_change_set" 'Tranche Scope SHA-256')" = "$pilot_scope_sha"
test "sha256:$(sha256sum "$pilot_scope_ref" | awk '{print $1}')" = "$pilot_scope_sha"
sed -n '/^## 集合の境界/,/^## 受理記録/p' "$pilot_change_set" \
  | rg -o --no-filename 'SD-[A-Z]+-[A-Z]+-[0-9]+' | sort -u > "$check_tmp/change-set-ids"
diff -u "$pilot_ids_ref" "$check_tmp/change-set-ids"

pilot_review_ref="$(awk -F '|' -v id="$pilot_set" '
  /^\| APR-/ { for (i=2;i<=12;i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i); if ($2 == id) print $9 }
' "$manifest")"
pilot_owner_ref="$(awk -F '|' -v id="$pilot_set" '
  /^\| APR-/ { for (i=2;i<=12;i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i); if ($2 == id) print $11 }
' "$manifest")"
for pilot_artifact in "$pilot_review_ref" "$pilot_owner_ref"; do
  test "$(field_value "$pilot_artifact" 'Obligation Review Ref')" = "$pilot_obligations_ref"
  test "$(field_value "$pilot_artifact" 'Obligation Review SHA-256')" = "$pilot_obligations_sha"
  test "$(field_value "$pilot_artifact" 'Tranche ID')" = TR-PILOT-ABC
  test "$(field_value "$pilot_artifact" 'Tranche Scope Ref')" = "$pilot_scope_ref"
  test "$(field_value "$pilot_artifact" 'Tranche Scope SHA-256')" = "$pilot_scope_sha"
done

if $require_all; then
  awk -F '|' '
    /^\| SD-/ {
      for (i = 2; i <= 10; i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
      if ($9 == "accepted") print $2
    }
  ' "$authority" | sort -u > "$check_tmp/current-accepted-ids"
  docs/system-design/verification/canonical-definition-set.sh "$check_tmp/current-accepted-ids" \
    | tail -n +2 | awk -F '\t' '{ print $1 "@" $2 "\t" $3 "\t" $4 }' \
    | sort -u > "$check_tmp/current-accepted-definitions"
  comm -23 "$check_tmp/current-accepted-definitions" "$check_tmp/approved-definitions" \
    > "$check_tmp/unapproved-current-definitions"
  if test -s "$check_tmp/unapproved-current-definitions"; then
    echo 'accepted canonical definitions missing approval coverage:' >&2
    cat "$check_tmp/unapproved-current-definitions" >&2
    exit 1
  fi
fi

printf 'PASS(design-approvals) sets=%s definitions=%s require_all=%s\n' \
  "$approval_rows" "$(wc -l < "$check_tmp/approved-definitions")" "$require_all"

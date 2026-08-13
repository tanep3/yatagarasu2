#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"

baseline=docs/system-design/verification/requirements-baseline.tsv
inventory=docs/system-design/verification/ac-inventory.md
packages=docs/system-design/verification/expansion-packages.tsv
ac_packages=docs/system-design/verification/ac-work-packages.tsv
obligations=docs/system-design/verification/obligation-assignments.tsv
tranches=docs/system-design/verification/expansion-tranches.tsv
check_tmp="$(mktemp -d)"
trap 'rm -r "$check_tmp"' EXIT
authoritative_parent_limit=12
authoritative_obligation_limit=30

docs/system-design/verification/check-ac-expansion-negative-fixtures.sh
docs/system-design/verification/check-tranche-dependency-dag.sh "$tranches"

field_value() {
  local file="$1" field="$2"
  awk -F '|' -v field="$field" '
    /^\|/ {
      for (i = 2; i <= NF - 1; i++) gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i)
      if ($2 == field) print $3
    }
  ' "$file"
}

table_cell() {
  local file="$1" row="$2" column="$3"
  awk -F '|' -v row="$row" -v column="$column" '
    /^\|/ {
      for (i = 2; i <= NF - 1; i++) gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i)
      if ($2 == row) print $column
    }
  ' "$file"
}

docs/system-design/verification/rebuild-requirements-baseline.sh 4df6fb1 > "$check_tmp/rebuilt-baseline"
diff -u "$baseline" "$check_tmp/rebuilt-baseline"
test "$(tail -n +2 "$baseline" | wc -l)" -eq 214
test "$(tail -n +2 "$baseline" | cut -f1 | sort -u | wc -l)" -eq 62
tail -n +2 "$baseline" | cut -f2 | sort > "$check_tmp/baseline-ac"
sort -u "$check_tmp/baseline-ac" > "$check_tmp/baseline-ac-unique"
diff -u "$check_tmp/baseline-ac" "$check_tmp/baseline-ac-unique"

awk -F '|' '
  /^\| REQ-/ {
    for (i = 2; i <= 7; i++) gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i)
    print $2 "\t" $3 "\t" $4
  }
' "$inventory" | sort -k2,2 > "$check_tmp/inventory-core"
tail -n +2 "$baseline" | cut -f1-3 | sort -k2,2 > "$check_tmp/baseline-core"
diff -u "$check_tmp/baseline-core" "$check_tmp/inventory-core"

# Package prefix ownership is exclusive and covers every baseline prefix.
tail -n +2 "$packages" | cut -f1 | sort > "$check_tmp/package-ids"
sort -u "$check_tmp/package-ids" > "$check_tmp/package-ids-unique"
diff -u "$check_tmp/package-ids" "$check_tmp/package-ids-unique"
test "$(wc -l < "$check_tmp/package-ids")" -eq 8
awk -F '\t' '
  NR == 1 { next }
  {
    n=split($2, prefix, ",")
    for (i=1; i<=n; i++) print prefix[i] "\t" $1
  }
' "$packages" | sort > "$check_tmp/prefix-owner"
cut -f1 "$check_tmp/prefix-owner" | sort -u > "$check_tmp/package-prefixes"
tail -n +2 "$baseline" | cut -f2 | sed -E 's/^AC-([A-Z]+)-.*/\1/' | sort -u > "$check_tmp/baseline-prefixes"
diff -u "$check_tmp/baseline-prefixes" "$check_tmp/package-prefixes"
if test "$(cut -f1 "$check_tmp/prefix-owner" | wc -l)" -ne "$(cut -f1 "$check_tmp/prefix-owner" | sort -u | wc -l)"; then
  echo 'AC prefix assigned to multiple packages' >&2
  exit 1
fi

# AC mapping is exact-one and agrees with prefix ownership.
tail -n +2 "$ac_packages" | sort -k1,1 > "$check_tmp/ac-package-rows"
cut -f1 "$check_tmp/ac-package-rows" > "$check_tmp/mapped-ac"
diff -u "$check_tmp/baseline-ac" "$check_tmp/mapped-ac"
while IFS=$'\t' read -r ac package_id; do
  prefix="$(printf '%s' "$ac" | sed -E 's/^AC-([A-Z]+)-.*/\1/')"
  expected="$(awk -F '\t' -v prefix="$prefix" '$1 == prefix { print $2 }' "$check_tmp/prefix-owner")"
  test "$package_id" = "$expected"
done < "$check_tmp/ac-package-rows"

# Dependency references, limits, and review status are typed.
while IFS=$'\t' read -r package_id prefixes dependencies parent_limit obligation_limit review_status; do
  test "$parent_limit" -eq "$authoritative_parent_limit"
  test "$obligation_limit" -eq "$authoritative_obligation_limit"
  test "$review_status" = pilot-partial -o "$review_status" = pending -o "$review_status" = accepted
  if test "$dependencies" != —; then
    printf '%s\n' "$dependencies" | tr ',' '\n' | while IFS= read -r dependency; do
      rg -qx "$dependency" "$check_tmp/package-ids"
      test "$dependency" != "$package_id"
      if test "$review_status" = accepted; then
        dependency_status="$(awk -F '\t' -v id="$dependency" 'NR > 1 && $1 == id { print $6 }' "$packages")"
        dependency_line="$(awk -F '\t' -v id="$dependency" 'NR > 1 && $1 == id { print NR }' "$packages")"
        package_line="$(awk -F '\t' -v id="$package_id" 'NR > 1 && $1 == id { print NR }' "$packages")"
        test "$dependency_status" = accepted
        test "$dependency_line" -lt "$package_line"
      fi
    done
  fi
done < <(tail -n +2 "$packages")

# Package dependency graph must remain acyclic independently of file ordering.
while IFS=$'\t' read -r package_id prefixes dependencies parent_limit obligation_limit review_status; do
  printf '%s %s\n' "$package_id" "$package_id" >> "$check_tmp/package-edges"
  if test "$dependencies" != —; then
    printf '%s\n' "$dependencies" | tr ',' '\n' | while IFS= read -r dependency; do
      printf '%s %s\n' "$dependency" "$package_id"
    done >> "$check_tmp/package-edges"
  fi
done < <(tail -n +2 "$packages")
if ! tsort "$check_tmp/package-edges" > "$check_tmp/package-topology" 2> "$check_tmp/package-cycle"; then
  echo 'package dependency cycle detected:' >&2
  cat "$check_tmp/package-cycle" >&2
  exit 1
fi

# Every canonical pilot obligation has exactly one stable storage row and one package.
rg -o --no-filename '^\| DO-[A-Z]+-[0-9]+[A-Z]? \|' docs/system-design/slices/*.md \
  | sed -E 's/^\| (DO-[A-Z]+-[0-9]+[A-Z]?) \|$/\1/' | sort > "$check_tmp/slice-obligations"
tail -n +2 "$obligations" | cut -f1 | sort > "$check_tmp/assigned-obligations"
diff -u "$check_tmp/slice-obligations" "$check_tmp/assigned-obligations"
sort -u "$check_tmp/assigned-obligations" > "$check_tmp/assigned-obligations-unique"
diff -u "$check_tmp/assigned-obligations" "$check_tmp/assigned-obligations-unique"

while IFS=$'\t' read -r obligation_id parent_ac package_id tranche_id storage_ref; do
  expected_package="$(awk -F '\t' -v ac="$parent_ac" 'NR > 1 && $1 == ac { print $2 }' "$ac_packages")"
  test "$package_id" = "$expected_package"
  case "$storage_ref" in docs/system-design/slices/*.md::"$obligation_id") ;; *) echo "invalid obligation storage ref: $storage_ref" >&2; exit 1 ;; esac
  storage_file="${storage_ref%%::*}"
  test "$(rg -c "^\\| $obligation_id \\|" "$storage_file")" -eq 1
  canonical_parent="$(awk -F '|' -v id="$obligation_id" '
    /^\| DO-/ {
      for (i=2;i<=12;i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
      if ($2 == id) print $3
    }
  ' "$storage_file")"
  test "$parent_ac" = "$canonical_parent"
  test "$(awk -F '\t' -v id="$tranche_id" 'NR > 1 && $1 == id { n++ } END { print n+0 }' "$tranches")" -eq 1
  tranche_packages="$(awk -F '\t' -v id="$tranche_id" 'NR > 1 && $1 == id { print $2 }' "$tranches")"
  if ! printf '%s\n' "$tranche_packages" | tr ',' '\n' | rg -qx "$package_id"; then
    echo "assignment package is outside tranche: $obligation_id -> $package_id / $tranche_id" >&2
    exit 1
  fi
done < <(tail -n +2 "$obligations")

# Tranches may span packages only when explicitly listed. Limits require an explicit exception.
tail -n +2 "$tranches" | cut -f1 | sort > "$check_tmp/tranche-ids"
sort -u "$check_tmp/tranche-ids" > "$check_tmp/tranche-ids-unique"
diff -u "$check_tmp/tranche-ids" "$check_tmp/tranche-ids-unique"

# Review tranche dependencies form their own DAG. Every review-ready dependency is already accepted;
# same-package dependencies are valid semantic dependencies and remain distinct from package edges.
: > "$check_tmp/tranche-edges"
while IFS=$'\t' read -r tranche_id package_ids parent_count obligation_count parent_limit obligation_limit dependencies review_status approval_set limit_exception reviewed_revision provenance; do
  if test "$dependencies" != pilot-baseline && test "$dependencies" != —; then
    printf '%s\n' "$dependencies" | tr ',' '\n' | while IFS= read -r dependency; do
      test "$dependency" != "$tranche_id"
      rg -qx "$dependency" "$check_tmp/tranche-ids"
      test "$(awk -F '\t' -v id="$dependency" 'NR > 1 && $1 == id { print $8 }' "$tranches")" = accepted
      dependency_line="$(awk -F '\t' -v id="$dependency" 'NR > 1 && $1 == id { print NR }' "$tranches")"
      tranche_line="$(awk -F '\t' -v id="$tranche_id" 'NR > 1 && $1 == id { print NR }' "$tranches")"
      test "$dependency_line" -lt "$tranche_line"
      printf '%s %s\n' "$dependency" "$tranche_id" >> "$check_tmp/tranche-edges"
    done
  fi
done < <(tail -n +2 "$tranches")
cp "$check_tmp/tranche-edges" "$check_tmp/tranche-graph"
if ! tsort "$check_tmp/tranche-graph" > "$check_tmp/tranche-topology" 2> "$check_tmp/tranche-cycle"; then
  echo 'tranche dependency cycle detected:' >&2
  cat "$check_tmp/tranche-cycle" >&2
  exit 1
fi
# The self-edge path above is an explicit identity rejection; this fixture proves multi-node cycles fail.
if printf 'A B\nB A\n' | tsort >/dev/null 2>&1; then exit 1; fi

while IFS=$'\t' read -r tranche_id package_ids parent_count obligation_count parent_limit obligation_limit dependencies review_status approval_set limit_exception reviewed_revision provenance; do
  printf '%s\n' "$package_ids" | tr ',' '\n' | while IFS= read -r package_id; do rg -qx "$package_id" "$check_tmp/package-ids"; done

  # Package dependencies outside this joint tranche must be represented exactly by dependency tranches.
  : > "$check_tmp/$tranche_id-expected-package-dependencies"
  printf '%s\n' "$package_ids" | tr ',' '\n' | while IFS= read -r package_id; do
    package_dependencies="$(awk -F '\t' -v id="$package_id" 'NR > 1 && $1 == id { print $3 }' "$packages")"
    if test "$package_dependencies" != —; then
      printf '%s\n' "$package_dependencies" | tr ',' '\n'
    fi
  done | sort -u | while IFS= read -r dependency_package; do
    if ! printf '%s\n' "$package_ids" | tr ',' '\n' | rg -qx "$dependency_package"; then
      printf '%s\n' "$dependency_package" >> "$check_tmp/$tranche_id-expected-package-dependencies"
    fi
  done
  sort -u "$check_tmp/$tranche_id-expected-package-dependencies" \
    > "$check_tmp/$tranche_id-expected-package-dependencies-sorted"
  : > "$check_tmp/$tranche_id-actual-package-dependencies"
  if test "$dependencies" != — && test "$dependencies" != pilot-baseline; then
    printf '%s\n' "$dependencies" | tr ',' '\n' | while IFS= read -r dependency_tranche; do
      if test "$dependency_tranche" != TR-PILOT-ABC; then
        awk -F '\t' -v id="$dependency_tranche" 'NR > 1 && $1 == id { print $2 }' "$tranches" | tr ',' '\n'
      fi
    done | sort -u | while IFS= read -r dependency_package; do
      # A later tranche may depend on an accepted contract from the same package.
      # It is a semantic tranche dependency, not an additional package dependency.
      if ! printf '%s\n' "$package_ids" | tr ',' '\n' | rg -qx "$dependency_package"; then
        printf '%s\n' "$dependency_package"
      fi
    done > "$check_tmp/$tranche_id-actual-package-dependencies"
  fi
  if test "$tranche_id" = TR-PILOT-ABC; then
    test "$dependencies" = pilot-baseline
    test ! -s "$check_tmp/$tranche_id-expected-package-dependencies-sorted"
  else
    if ! printf '%s\n' "$dependencies" | tr ',' '\n' | rg -qx TR-PILOT-ABC; then
      echo "expansion tranche does not bind the accepted pilot basis: $tranche_id" >&2
      exit 1
    fi
    diff -u "$check_tmp/$tranche_id-expected-package-dependencies-sorted" \
      "$check_tmp/$tranche_id-actual-package-dependencies"
  fi
  actual_obligations="$(awk -F '\t' -v id="$tranche_id" 'NR > 1 && $4 == id { n++ } END { print n+0 }' "$obligations")"
  actual_parents="$(awk -F '\t' -v id="$tranche_id" 'NR > 1 && $4 == id { print $2 }' "$obligations" | sort -u | wc -l)"
  test "$obligation_count" -eq "$actual_obligations"
  test "$parent_count" -eq "$actual_parents"
  test "$parent_limit" -eq "$authoritative_parent_limit"
  test "$obligation_limit" -eq "$authoritative_obligation_limit"
  case "$review_status" in review-pending|challenge-pending|owner-pending|accepted) ;; *) echo "invalid tranche review status: $review_status" >&2; exit 1 ;; esac
  if test "$parent_count" -gt "$parent_limit" || test "$obligation_count" -gt "$obligation_limit"; then
    test "$tranche_id" = TR-PILOT-ABC
    test "$limit_exception" = design-pilot-baseline
  else
    test "$limit_exception" = —
  fi
  if test "$review_status" != accepted; then
    candidate_id="${provenance%%@*}"
    source_revision="${provenance##*@}"
    case "$candidate_id" in SD-REV-*) ;; *) echo "invalid pending tranche provenance: $tranche_id" >&2; exit 1 ;; esac
    if test "$source_revision" != WORKTREE && ! git cat-file -e "$source_revision^{commit}" 2>/dev/null; then
      echo "pending tranche source revision is unreachable: $tranche_id" >&2
      exit 1
    fi
    candidate_change_set="docs/system-design/verification/change-sets/$candidate_id.md"
    candidate_ids_ref="docs/system-design/verification/approvals/$candidate_id-design-ids.txt"
    candidate_definitions_ref="docs/system-design/verification/approvals/$candidate_id-definitions.tsv"
    candidate_obligations_ref="docs/system-design/verification/approvals/$candidate_id-obligations.tsv"
    candidate_scope_ref="docs/system-design/verification/approvals/$tranche_id-scope.tsv"
    candidate_dependencies_ref="docs/system-design/verification/approvals/$candidate_id-dependencies.tsv"
    for candidate_input in "$candidate_change_set" "$candidate_ids_ref" "$candidate_definitions_ref" "$candidate_obligations_ref" "$candidate_scope_ref" "$candidate_dependencies_ref"; do
      test -f "$candidate_input"
    done

    # Pending lifecycle validates review-input integrity only; it grants no approval.
    test "$(table_cell "$candidate_change_set" 'Design IDs' 3)" = "$candidate_ids_ref"
    test "$(table_cell "$candidate_change_set" 'Definitions' 3)" = "$candidate_definitions_ref"
    test "$(table_cell "$candidate_change_set" 'Obligation review' 3)" = "$candidate_obligations_ref"
    test "$(table_cell "$candidate_change_set" 'Tranche scope' 3)" = "$candidate_scope_ref"
    test "$(table_cell "$candidate_change_set" 'Dependency manifest' 3)" = "$candidate_dependencies_ref"
    test "$(table_cell "$candidate_change_set" 'Design IDs' 4)" = "sha256:$(sha256sum "$candidate_ids_ref" | awk '{print $1}')"
    test "$(table_cell "$candidate_change_set" 'Definitions' 4)" = "sha256:$(sha256sum "$candidate_definitions_ref" | awk '{print $1}')"
    test "$(table_cell "$candidate_change_set" 'Obligation review' 4)" = "sha256:$(sha256sum "$candidate_obligations_ref" | awk '{print $1}')"
    test "$(table_cell "$candidate_change_set" 'Tranche scope' 4)" = "sha256:$(sha256sum "$candidate_scope_ref" | awk '{print $1}')"
    test "$(table_cell "$candidate_change_set" 'Dependency manifest' 4)" = "sha256:$(sha256sum "$candidate_dependencies_ref" | awk '{print $1}')"

    # A pending review includes every canonical definition from every accepted dependency tranche,
    # plus every draft definition owned by this canonical contract. This deliberately conservative
    # complete closure prevents a second-hop accepted dependency or sibling row from disappearing.
    : > "$check_tmp/$tranche_id-expected-review-ids"
    printf '%s\n' "$dependencies" | tr ',' '\n' | while IFS= read -r dependency_tranche; do
      test "$dependency_tranche" = pilot-baseline && continue
      dependency_approval="$(awk -F '\t' -v id="$dependency_tranche" 'NR>1 && $1==id {print $9}' "$tranches")"
      test -n "$dependency_approval" && test "$dependency_approval" != —
      dependency_ids_ref="$(awk -F '|' -v id="$dependency_approval" '
        /^\| APR-/ { for(i=2;i<=12;i++) gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i); if($2==id) print $5 }
      ' docs/system-design/verification/design-approval.md)"
      test -f "$dependency_ids_ref"
      cat "$dependency_ids_ref"
    done >> "$check_tmp/$tranche_id-expected-review-ids"
    awk -F '|' '/^\| SD-/ {
      for(i=2;i<=10;i++) gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i)
      if($4 ~ /contracts\/execution-revision-3.md#/ && $9=="draft") print $2
    }' docs/system-design/00-design-authority.md >> "$check_tmp/$tranche_id-expected-review-ids"
    sort -u "$check_tmp/$tranche_id-expected-review-ids" > "$check_tmp/$tranche_id-expected-review-ids-sorted"
    diff -u "$check_tmp/$tranche_id-expected-review-ids-sorted" "$candidate_ids_ref"
    docs/system-design/verification/check-canonical-dependency-closure.sh \
      "$candidate_ids_ref" "$candidate_definitions_ref" "$candidate_dependencies_ref" "$source_revision"

    docs/system-design/verification/canonical-definition-set.sh \
      "$candidate_ids_ref" "$source_revision" > "$check_tmp/$tranche_id-source-definitions"
    diff -u "$candidate_definitions_ref" "$check_tmp/$tranche_id-source-definitions"
    docs/system-design/verification/canonical-definition-set.sh \
      "$candidate_ids_ref" WORKTREE > "$check_tmp/$tranche_id-current-definitions"
    diff -u "$candidate_definitions_ref" "$check_tmp/$tranche_id-current-definitions"
    docs/system-design/verification/obligation-review-set.sh \
      "$obligations" "$tranche_id" "$source_revision" > "$check_tmp/$tranche_id-source-obligations"
    diff -u "$candidate_obligations_ref" "$check_tmp/$tranche_id-source-obligations"
    docs/system-design/verification/obligation-review-set.sh \
      "$obligations" "$tranche_id" WORKTREE > "$check_tmp/$tranche_id-current-obligations"
    diff -u "$candidate_obligations_ref" "$check_tmp/$tranche_id-current-obligations"
    docs/system-design/verification/tranche-review-set.sh \
      "$obligations" "$tranches" "$tranche_id" "$candidate_definitions_ref" "$candidate_obligations_ref" \
      > "$check_tmp/$tranche_id-current-scope"
    diff -u "$candidate_scope_ref" "$check_tmp/$tranche_id-current-scope"

    tail -n +2 "$candidate_definitions_ref" | cut -f1 | sort -u > "$check_tmp/$tranche_id-candidate-design-ids"
    tail -n +2 "$candidate_obligations_ref" | cut -f9 | tr ',' '\n' \
      | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | rg '^SD-' | sort -u \
      > "$check_tmp/$tranche_id-obligation-design-ids"
    comm -23 "$check_tmp/$tranche_id-obligation-design-ids" "$check_tmp/$tranche_id-candidate-design-ids" \
      > "$check_tmp/$tranche_id-missing-design-ids"
    if test -s "$check_tmp/$tranche_id-missing-design-ids"; then
      echo "pending tranche obligations reference definitions outside review input: $tranche_id" >&2
      cat "$check_tmp/$tranche_id-missing-design-ids" >&2
      exit 1
    fi
  fi
  if test "$review_status" = accepted; then
    test "$approval_set" != —
    approval_manifest_row="$(awk -F '|' -v id="$approval_set" '
      /^\| APR-/ { for(i=2;i<=12;i++) gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i); if($2==id) print $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $11 }
    ' docs/system-design/verification/design-approval.md)"
    test -n "$approval_manifest_row"
    IFS=$'\t' read -r approval_ids_ref approval_ids_sha approval_definitions_ref approval_definitions_sha approval_review_ref approval_owner_ref <<< "$approval_manifest_row"
    review_source_commit="$(field_value "$approval_review_ref" 'Source commit')"
    review_revision="$(field_value "$approval_review_ref" 'System design revision')"
    test "$reviewed_revision" = "$review_revision"
    case "$provenance" in *@"$review_source_commit") ;; *) echo "tranche provenance does not bind review source: $tranche_id" >&2; exit 1 ;; esac
    test "$reviewed_revision" != —

    test "$approval_ids_sha" = "sha256:$(sha256sum "$approval_ids_ref" | awk '{print $1}')"
    test "$approval_definitions_sha" = "sha256:$(sha256sum "$approval_definitions_ref" | awk '{print $1}')"
    docs/system-design/verification/canonical-definition-set.sh \
      "$approval_ids_ref" "$review_source_commit" > "$check_tmp/$tranche_id-reviewed-definitions"
    diff -u "$approval_definitions_ref" "$check_tmp/$tranche_id-reviewed-definitions"
    docs/system-design/verification/canonical-definition-set.sh \
      "$approval_ids_ref" WORKTREE > "$check_tmp/$tranche_id-current-definitions"
    diff -u "$approval_definitions_ref" "$check_tmp/$tranche_id-current-definitions"

    dependency_manifest_ref="$(field_value "$approval_review_ref" 'Dependency Manifest Ref')"
    dependency_manifest_sha="$(field_value "$approval_review_ref" 'Dependency Manifest SHA-256')"
    if test -n "$dependency_manifest_ref"; then
      case "$dependency_manifest_ref" in docs/system-design/verification/approvals/*-dependencies.tsv) ;; *) exit 1 ;; esac
      test -f "$dependency_manifest_ref"
      test "$dependency_manifest_sha" = "sha256:$(sha256sum "$dependency_manifest_ref" | awk '{print $1}')"
      docs/system-design/verification/check-canonical-dependency-closure.sh \
        "$approval_ids_ref" "$approval_definitions_ref" "$dependency_manifest_ref" "$review_source_commit"
    fi

    tranche_scope_ref="$(field_value "$approval_review_ref" 'Tranche Scope Ref')"
    tranche_scope_sha="$(field_value "$approval_review_ref" 'Tranche Scope SHA-256')"
    obligation_review_ref="$(field_value "$approval_review_ref" 'Obligation Review Ref')"
    obligation_review_sha="$(field_value "$approval_review_ref" 'Obligation Review SHA-256')"
    case "$obligation_review_ref" in docs/system-design/verification/approvals/*.tsv) ;; *) echo "invalid obligation review ref: $tranche_id" >&2; exit 1 ;; esac
    test "$obligation_review_sha" = "sha256:$(sha256sum "$obligation_review_ref" | awk '{print $1}')"
    test "$(field_value "$approval_owner_ref" 'Obligation Review Ref')" = "$obligation_review_ref"
    test "$(field_value "$approval_owner_ref" 'Obligation Review SHA-256')" = "$obligation_review_sha"
    docs/system-design/verification/obligation-review-set.sh \
      "$obligations" "$tranche_id" "$review_source_commit" \
      > "$check_tmp/$tranche_id-reviewed-obligations"
    diff -u "$obligation_review_ref" "$check_tmp/$tranche_id-reviewed-obligations"
    docs/system-design/verification/obligation-review-set.sh \
      "$obligations" "$tranche_id" WORKTREE \
      > "$check_tmp/$tranche_id-current-obligations"
    diff -u "$obligation_review_ref" "$check_tmp/$tranche_id-current-obligations"

    # Obligation closure is subset-complete: every referenced Design ID must be in the Approval set.
    # Extra approved definitions are permitted for integrated/common laws reviewed by the same tranche.
    tail -n +2 "$approval_definitions_ref" | cut -f1 | sort -u \
      > "$check_tmp/$tranche_id-approved-design-ids"
    tail -n +2 "$obligation_review_ref" | cut -f9 | tr ',' '\n' \
      | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | rg '^SD-' | sort -u \
      > "$check_tmp/$tranche_id-obligation-design-ids"
    comm -23 "$check_tmp/$tranche_id-obligation-design-ids" \
      "$check_tmp/$tranche_id-approved-design-ids" \
      > "$check_tmp/$tranche_id-missing-design-ids"
    if test -s "$check_tmp/$tranche_id-missing-design-ids"; then
      echo "accepted tranche obligations reference definitions outside Approval set: $tranche_id" >&2
      cat "$check_tmp/$tranche_id-missing-design-ids" >&2
      exit 1
    fi

    case "$tranche_scope_ref" in docs/system-design/verification/approvals/*.tsv) ;; *) echo "invalid tranche scope ref: $tranche_id" >&2; exit 1 ;; esac
    test "$(field_value "$approval_review_ref" 'Tranche ID')" = "$tranche_id"
    test "$(field_value "$approval_review_ref" 'Tranche Package IDs')" = "$package_ids"
    test "$tranche_scope_sha" = "sha256:$(sha256sum "$tranche_scope_ref" | awk '{print $1}')"
    test "$(field_value "$approval_owner_ref" 'Tranche ID')" = "$tranche_id"
    test "$(field_value "$approval_owner_ref" 'Tranche Package IDs')" = "$package_ids"
    test "$(field_value "$approval_owner_ref" 'Tranche Scope Ref')" = "$tranche_scope_ref"
    test "$(field_value "$approval_owner_ref" 'Tranche Scope SHA-256')" = "$tranche_scope_sha"
    docs/system-design/verification/tranche-review-set.sh \
      "$obligations" "$tranches" "$tranche_id" "$approval_definitions_ref" "$obligation_review_ref" \
      > "$check_tmp/$tranche_id-current-scope"
    diff -u "$tranche_scope_ref" "$check_tmp/$tranche_id-current-scope"
  fi
  test -n "$provenance" && test "$provenance" != —
done < <(tail -n +2 "$tranches")

# A covered flag alone is insufficient: every obligation must be designed and assigned to an
# accepted tranche, and an accepted non-pilot expansion tranche must contribute a full completion.
# Historical partial contributions remain immutable review evidence but are never sufficient alone.
awk -F '|' '
  /^\| REQ-/ {
    for (i = 2; i <= 7; i++) gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i)
    if ($7 == "covered" && $6 != "accounted-for") {
      print "covered AC is not accounted-for: " $3 > "/dev/stderr"; exit 1
    }
    if ($7 == "covered") print $3
  }
' "$inventory" | sort -u > "$check_tmp/covered-ac"
while IFS= read -r covered_ac; do
  test -n "$covered_ac"
done < "$check_tmp/covered-ac"
docs/system-design/verification/check-covered-completion-set.sh \
  "$inventory" "$obligations" "$tranches" docs/system-design/slices/*.md

printf 'PASS(ac-expansion) requirements=62 ac=214 packages=8 obligations=%s tranches=%s covered=%s\n' \
  "$(wc -l < "$check_tmp/assigned-obligations")" "$(( $(wc -l < "$tranches") - 1 ))" "$(wc -l < "$check_tmp/covered-ac")"

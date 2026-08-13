#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"

if test "$#" -ne 3; then
  echo "usage: $0 ASSIGNMENTS_FILE TRANCHE_ID SOURCE_COMMIT|WORKTREE" >&2
  exit 2
fi

assignments="$1"
tranche_id="$2"
source_revision="$3"
test -f "$assignments"

if test "$source_revision" != WORKTREE && ! git cat-file -e "$source_revision^{commit}" 2>/dev/null; then
  echo "obligation review source commit is not reachable: $source_revision" >&2
  exit 1
fi

check_tmp="$(mktemp -d)"
trap 'rm -r "$check_tmp"' EXIT

printf 'Obligation ID\tParent AC\tPackage ID\tTranche ID\tCanonical storage ref\tObligation meaning SHA-256\tJoint group\tParent contribution\tDesign IDs\tProof type\tNegative case\tTarget scope\tAccounting\tDesign\tProof\tBlocker\n'

awk -F '\t' -v tranche="$tranche_id" 'NR > 1 && $4 == tranche' "$assignments" \
  | sort -t $'\t' -k1,1 \
  | while IFS=$'\t' read -r obligation_id parent_ac package_id assigned_tranche storage_ref; do
      storage_file="${storage_ref%%::*}"
      storage_id="${storage_ref##*::}"
      test "$storage_id" = "$obligation_id"

      cache_key="$(printf '%s' "$storage_file" | sha256sum | awk '{print $1}')"
      source_file="$check_tmp/$cache_key"
      if ! test -f "$source_file"; then
        if test "$source_revision" = WORKTREE; then
          test -f "$storage_file"
          cp "$storage_file" "$source_file"
        elif ! git show "$source_revision:$storage_file" > "$source_file"; then
          echo "obligation review source path is unavailable: $source_revision:$storage_file" >&2
          exit 1
        fi
      fi

      row="$(awk -F '|' -v id="$obligation_id" '
        /^\| DO-/ {
          for (i=2;i<=12;i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
          if ($2 == id) print $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $10 "\t" $11 "\t" $12
        }
      ' "$source_file")"
      if test "$(printf '%s\n' "$row" | awk 'NF { n++ } END { print n+0 }')" -ne 1; then
        echo "obligation review source row is missing or duplicated: $source_revision:$storage_file::$obligation_id" >&2
        exit 1
      fi
      IFS=$'\t' read -r canonical_parent joint_group contribution design_ids proof_type negative_case target_scope accounting design proof <<< "$row"
      test "$canonical_parent" = "$parent_ac"
      meaning_sha="sha256:$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$canonical_parent" "$joint_group" "$contribution" "$design_ids" "$proof_type" \
        "$negative_case" "$target_scope" "$accounting" "$design" "$proof" | sha256sum | awk '{print $1}')"
      blocker=—
      case "$design" in
        blocked-by-spike|blocked-by-owner) blocker="design-status:$design" ;;
      esac
      case "$proof" in
        blocked-by-spike|blocked-by-owner)
          if test "$blocker" = —; then blocker="proof-status:$proof"; else blocker="$blocker,proof-status:$proof"; fi
          ;;
      esac
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$obligation_id" "$parent_ac" "$package_id" "$assigned_tranche" "$storage_ref" \
        "$meaning_sha" "$joint_group" "$contribution" "$design_ids" "$proof_type" \
        "$negative_case" "$target_scope" "$accounting" "$design" "$proof" "$blocker"
    done

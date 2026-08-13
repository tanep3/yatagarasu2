#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"

if test "$#" -ne 5; then
  echo "usage: $0 ASSIGNMENTS_FILE TRANCHES_FILE TRANCHE_ID DEFINITIONS_FILE OBLIGATION_REVIEW_FILE" >&2
  exit 2
fi

assignments="$1"
tranches="$2"
tranche_id="$3"
definitions="$4"
obligation_review="$5"
for input in "$assignments" "$tranches" "$definitions" "$obligation_review"; do test -f "$input"; done

tranche_row="$(awk -F '\t' -v id="$tranche_id" 'NR > 1 && $1 == id { print }' "$tranches")"
if test "$(printf '%s\n' "$tranche_row" | awk 'NF { n++ } END { print n+0 }')" -ne 1; then
  echo "tranche review set requires exactly one tranche row: $tranche_id" >&2
  exit 1
fi
package_ids="$(printf '%s\n' "$tranche_row" | cut -f2)"

printf 'Record type\tIdentity\tValue\n'
printf 'tranche\t%s\t%s\n' "$tranche_id" "$package_ids"
printf '%s\n' "$package_ids" | tr ',' '\n' | sort -u \
  | while IFS= read -r package_id; do printf 'package\t%s\t%s\n' "$package_id" "$tranche_id"; done
awk -F '\t' -v id="$tranche_id" 'NR > 1 && $4 == id { print $2 }' "$assignments" | sort -u \
  | while IFS= read -r parent_ac; do printf 'parent-ac\t%s\t%s\n' "$parent_ac" "$tranche_id"; done
awk -F '\t' -v id="$tranche_id" 'NR > 1 && $4 == id { print $1 "\t" $6 }' "$obligation_review" \
  | sort -t $'\t' -k1,1 \
  | while IFS=$'\t' read -r obligation_id semantic_sha; do
      printf 'obligation\t%s\t%s\t%s\n' "$obligation_id" "$tranche_id" "$semantic_sha"
    done
tail -n +2 "$definitions" | sort -t $'\t' -k1,1 -k2,2 \
  | while IFS=$'\t' read -r design_id version canonical_ref definition_sha; do
      printf 'definition\t%s@%s\t%s\t%s\n' "$design_id" "$version" "$canonical_ref" "$definition_sha"
    done

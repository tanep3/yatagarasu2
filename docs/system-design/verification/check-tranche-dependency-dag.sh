#!/usr/bin/env bash
set -euo pipefail

if test "$#" -ne 1; then echo "usage: $0 EXPANSION_TRANCHES" >&2; exit 2; fi
tranches="$1"
check_tmp="$(mktemp -d)"
trap 'rm -r "$check_tmp"' EXIT
tail -n +2 "$tranches" | cut -f1 | sort > "$check_tmp/ids"
test "$(wc -l < "$check_tmp/ids")" -eq "$(sort -u "$check_tmp/ids" | wc -l)"
: > "$check_tmp/edges"
while IFS=$'\t' read -r tranche_id _ _ _ _ _ dependencies review_status _; do
  case "$review_status" in review-pending|challenge-pending|owner-pending|accepted) ;; *) exit 1 ;; esac
  test "$dependencies" = pilot-baseline -o "$dependencies" = — && continue
  printf '%s\n' "$dependencies" | tr ',' '\n' | while IFS= read -r dependency; do
    test "$dependency" != "$tranche_id"
    rg -qx "$dependency" "$check_tmp/ids"
    printf '%s %s\n' "$dependency" "$tranche_id" >> "$check_tmp/edges"
  done
done < <(tail -n +2 "$tranches")
if ! tsort "$check_tmp/edges" >/dev/null 2> "$check_tmp/cycle"; then
  echo 'tranche dependency cycle detected' >&2
  cat "$check_tmp/cycle" >&2
  exit 1
fi

# Status and stable ledger order are checked only after the graph is proven acyclic, so a cycle
# fixture reaches the actual cycle branch instead of being rejected incidentally by row order.
while IFS=$'\t' read -r tranche_id _ _ _ _ _ dependencies _ _; do
  test "$dependencies" = pilot-baseline -o "$dependencies" = — && continue
  printf '%s\n' "$dependencies" | tr ',' '\n' | while IFS= read -r dependency; do
    test "$(awk -F '\t' -v id="$dependency" 'NR>1 && $1==id {print $8}' "$tranches")" = accepted
    dependency_line="$(awk -F '\t' -v id="$dependency" 'NR>1 && $1==id {print NR}' "$tranches")"
    tranche_line="$(awk -F '\t' -v id="$tranche_id" 'NR>1 && $1==id {print NR}' "$tranches")"
    test "$dependency_line" -lt "$tranche_line"
  done
done < <(tail -n +2 "$tranches")

#!/usr/bin/env bash
set -euo pipefail

if test "$#" -lt 4; then
  echo "usage: $0 INVENTORY OBLIGATIONS TRANCHES SLICE..." >&2
  exit 2
fi
inventory="$1"; obligations="$2"; tranches="$3"; shift 3
check_tmp="$(mktemp -d)"
trap 'rm -r "$check_tmp"' EXIT

awk -F '|' '
  /^\| REQ-/ {
    for(i=2;i<=7;i++) gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i)
    if($7=="covered" && $6!="accounted-for") exit 1
    if($7=="covered") print $3
  }
' "$inventory" | sort -u > "$check_tmp/covered-ac"

while IFS= read -r covered_ac; do
  test -n "$covered_ac"
  rows="$(awk -F '|' -v ac="$covered_ac" '
    /^\| DO-/ {
      for(i=2;i<=12;i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
      if($3==ac) print $2 "\t" $5 "\t" $10 "\t" $11 "\t" $12
    }
  ' "$@")"
  test -n "$rows"
  has_expansion_full=false
  while IFS=$'\t' read -r obligation_id contribution accounting design proof; do
    test "$contribution" = full -o "$contribution" = partial
    test "$accounting" = accounted-for
    test "$design" = designed
    case "$proof" in planned|implemented|passing|blocked-by-spike) ;; *) exit 1 ;; esac
    tranche_id="$(awk -F '\t' -v id="$obligation_id" 'NR>1 && $1==id {print $4}' "$obligations")"
    test "$(awk -F '\t' -v id="$tranche_id" 'NR>1 && $1==id {print $8}' "$tranches")" = accepted
    if test "$tranche_id" != TR-PILOT-ABC; then
      test "$contribution" = full
      has_expansion_full=true
    fi
  done <<< "$rows"
  test "$has_expansion_full" = true
done < "$check_tmp/covered-ac"

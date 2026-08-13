#!/usr/bin/env bash
set -euo pipefail

if test "$#" -ne 4; then
  echo "usage: $0 AUTHORITY DESIGN_IDS DEFINITIONS MANIFEST" >&2
  exit 2
fi
authority="$1"; ids="$2"; definitions="$3"; manifest="$4"
check_tmp="$(mktemp -d)"
trap 'rm -r "$check_tmp"' EXIT

sort -u "$ids" > "$check_tmp/ids"
diff -u "$ids" "$check_tmp/ids" >/dev/null
tail -n +2 "$definitions" | cut -f1 > "$check_tmp/definition-ids"
tail -n +2 "$manifest" | cut -f1 > "$check_tmp/manifest-ids"
diff -u "$ids" "$check_tmp/definition-ids" >/dev/null
diff -u "$ids" "$check_tmp/manifest-ids" >/dev/null

awk -F '|' '/^\| SD-/ {
  for(i=2;i<=10;i++) gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i)
  if($9=="accepted" || $9=="draft" || $9=="superseded") print $2
}' "$authority" | sort -u > "$check_tmp/allowed-status-ids"
comm -23 "$check_tmp/ids" "$check_tmp/allowed-status-ids" > "$check_tmp/invalid-status-ids"
test ! -s "$check_tmp/invalid-status-ids"
awk -F '\t' 'NR>1 && $2!="—" {
  n=split($2, deps, ",")
  for(i=1;i<=n;i++) {
    if(deps[i]==$1 || deps[i]=="") exit 1
    print deps[i]
  }
}' "$manifest" | sort -u > "$check_tmp/targets"
comm -23 "$check_tmp/targets" "$check_tmp/ids" > "$check_tmp/missing-targets"
test ! -s "$check_tmp/missing-targets"

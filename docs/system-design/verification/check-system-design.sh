#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"

check_tmp="$(mktemp -d)"
trap 'rm -r "$check_tmp"' EXIT

rg -o --no-filename 'REQ-[A-Z]+-[0-9]+' docs/requirements/*.md | sort -u > "$check_tmp/source-req"
rg -o --no-filename '^[-*] AC-[A-Z]+-[0-9]+:' docs/requirements/*.md \
  | sed -E 's/^[-*] (AC-[A-Z]+-[0-9]+):/\1/' | sort -u > "$check_tmp/source-ac"

test "$(wc -l < "$check_tmp/source-req")" -eq 62
test "$(wc -l < "$check_tmp/source-ac")" -eq 214

rg -o --no-filename '\| AC-[A-Z]+-[0-9]+ \|' docs/system-design/verification/ac-inventory.md \
  | sed -E 's/^\| (AC-[A-Z]+-[0-9]+) \|$/\1/' | sort -u > "$check_tmp/inventory-ac"
diff -u "$check_tmp/source-ac" "$check_tmp/inventory-ac"

rg -o --no-filename '^### (SD-[A-Z]+-[A-Z]+-[0-9]+)' docs/system-design/contracts \
  | sed -E 's/^### //' | sort > "$check_tmp/canonical-all"
sort -u "$check_tmp/canonical-all" > "$check_tmp/canonical-unique"
diff -u "$check_tmp/canonical-all" "$check_tmp/canonical-unique"

rg -o --no-filename '^\| SD-[A-Z]+-[A-Z]+-[0-9]+ \|' docs/system-design/00-design-authority.md \
  | sed -E 's/^\| (SD-[A-Z]+-[A-Z]+-[0-9]+) \|$/\1/' | sort > "$check_tmp/authority-all"
sort -u "$check_tmp/authority-all" > "$check_tmp/authority-unique"
diff -u "$check_tmp/authority-all" "$check_tmp/authority-unique"
diff -u "$check_tmp/canonical-unique" "$check_tmp/authority-unique"

# Authority表を列単位で検査する。これはStateの意味が同一かを証明する検査ではなく、
# owner／mutation境界の索引構造が単一で、参照先が実在することを保証する検査である。
awk -F '|' '
  /^\| SD-/ {
    for (i = 2; i <= 10; i++) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
    }
    print $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $10
  }
' docs/system-design/00-design-authority.md > "$check_tmp/authority-rows"

awk -F '\t' '$2 == "Context" { print $1 }' "$check_tmp/authority-rows" \
  | sort -u > "$check_tmp/authority-contexts"
awk -F '\t' '$2 == "Transition" { print $1 }' "$check_tmp/authority-rows" \
  | sort -u > "$check_tmp/authority-transitions"

state_count=0
state_owner_count=0
while IFS=$'\t' read -r design_id kind canonical write_authority state_owner mutation_authority version status supersedes; do
  design_id_lower="$(printf '%s' "$design_id" | tr '[:upper:]' '[:lower:]')"
  case "$canonical" in
    *"(contracts/"*"#${design_id_lower}--"*) ;;
    *) echo "invalid canonical anchor for $design_id: $canonical" >&2; exit 1 ;;
  esac
  canonical_file="$(printf '%s' "$canonical" | sed -nE 's/.*\((contracts\/[^#)]+)#.*\).*/\1/p')"
  test -n "$canonical_file"
  test -f "docs/system-design/$canonical_file"
  rg -q "^### ${design_id} — " "docs/system-design/$canonical_file"

  if test "$kind" = "State"; then
    state_count=$((state_count + 1))
    case "$state_owner" in
      SD-CTX-[A-Z]*-[0-9][0-9][0-9]) ;;
      *) echo "State owner must be exactly one Context ID: $design_id -> $state_owner" >&2; exit 1 ;;
    esac
    test "$(awk -v id="$state_owner" '$0 == id { n++ } END { print n + 0 }' "$check_tmp/authority-contexts")" -eq 1
    state_owner_count=$((state_owner_count + 1))

    test -n "$mutation_authority"
    test "$mutation_authority" != "N/A"
    if printf '%s' "$mutation_authority" | rg -qi 'Adapter|Projection|Port|Python worker'; then
      echo "forbidden State mutation authority: $design_id -> $mutation_authority" >&2
      exit 1
    fi

    if printf '%s' "$mutation_authority" | rg -q '^SD-TRN-[A-Z]+-[0-9]{3}(, SD-TRN-[A-Z]+-[0-9]{3})*$'; then
      transition_refs="$(printf '%s' "$mutation_authority" | rg -o 'SD-TRN-[A-Z]+-[0-9]+')"
      while IFS= read -r transition_id; do
        test "$(awk -v id="$transition_id" '$0 == id { n++ } END { print n + 0 }' "$check_tmp/authority-transitions")" -eq 1
        transition_context="$(awk -F '\t' -v id="$transition_id" '$1 == id { print $6 }' "$check_tmp/authority-rows")"
        test "$transition_context" = "$state_owner only"
      done <<< "$transition_refs"
    else
      case "$mutation_authority" in
        "Policy configuration transition（Pilot Cで定義）")
          if test -f docs/system-design/slices/03-configuration-capability.md; then
            echo "Pilot C is present but mutation authority is still provisional: $design_id" >&2
            exit 1
          fi
          ;;
        *) echo "State mutation authority has no Transition ID: $design_id -> $mutation_authority" >&2; exit 1 ;;
      esac
    fi
  else
    test "$state_owner" = "N/A"
    if test "$kind" = "Transition"; then
      case "$mutation_authority" in
        SD-CTX-[A-Z]*-[0-9][0-9][0-9]" only") ;;
        *) echo "Transition mutation authority must be exactly one Context: $design_id -> $mutation_authority" >&2; exit 1 ;;
      esac
      transition_owner="${mutation_authority% only}"
      test "$(awk -v id="$transition_owner" '$0 == id { n++ } END { print n + 0 }' "$check_tmp/authority-contexts")" -eq 1
    fi
  fi
done < "$check_tmp/authority-rows"

test "$state_count" -eq "$state_owner_count"

awk -F '\t' '
  $8 !~ /^(draft|accepted|blocked-by-spike|blocked-by-owner|superseded)$/ {
    print "invalid canonical lifecycle status: " $1 " -> " $8 > "/dev/stderr"; exit 1
  }
' "$check_tmp/authority-rows"

awk -F '\t' '$2 == "State" { print $3 }' "$check_tmp/authority-rows" | sort > "$check_tmp/state-anchors"
sort -u "$check_tmp/state-anchors" > "$check_tmp/state-anchors-unique"
diff -u "$check_tmp/state-anchors" "$check_tmp/state-anchors-unique"

rg -o --no-filename 'SD-[A-Z]+-[A-Z]+-[0-9]+' docs/system-design/slices \
  | sort -u > "$check_tmp/slice-design-refs"
comm -23 "$check_tmp/slice-design-refs" "$check_tmp/canonical-unique" > "$check_tmp/missing-design-refs"
test ! -s "$check_tmp/missing-design-refs"

rg -o --no-filename '\| AC-[A-Z]+-[0-9]+ \|' docs/system-design/slices \
  | sed -E 's/^\| (AC-[A-Z]+-[0-9]+) \|$/\1/' | sort -u > "$check_tmp/slice-parent-ac"
comm -23 "$check_tmp/slice-parent-ac" "$check_tmp/source-ac" > "$check_tmp/missing-parent-ac"
test ! -s "$check_tmp/missing-parent-ac"

awk -F '|' '
  /^\| REQ-/ {
    for (i = 2; i <= 7; i++) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
    }
    if ($6 == "`accounted-for`") print $3
  }
' docs/system-design/verification/ac-inventory.md | sort -u > "$check_tmp/inventory-accounted-ac"
diff -u "$check_tmp/inventory-accounted-ac" "$check_tmp/slice-parent-ac"
test -s "$check_tmp/slice-parent-ac"

# Design Pilot Gateで使う三軸のうち、現在のpilot sliceに登録された義務を検査する。
# 実機証拠待ちのProof=blocked-by-spikeは設計横展開を止めない。
rg -o --no-filename '^\| DO-[A-Z]+-[0-9]+[A-Z]? \|' docs/system-design/slices/*.md \
  | sed -E 's/^\| (DO-[A-Z]+-[0-9]+[A-Z]?) \|$/\1/' | sort > "$check_tmp/obligations-all"
sort -u "$check_tmp/obligations-all" > "$check_tmp/obligations-unique"
diff -u "$check_tmp/obligations-all" "$check_tmp/obligations-unique"

awk -F '|' '
  /^\| DO-/ {
    for (i = 2; i <= 12; i++) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
    }
    if ($2 !~ /^DO-[A-Z]+-[0-9][0-9][0-9][A-Z]?$/) { print "invalid obligation ID: " $2 > "/dev/stderr"; exit 1 }
    if ($3 !~ /^AC-[A-Z]+-[0-9]+$/) { print "invalid parent AC: " $2 " -> " $3 > "/dev/stderr"; exit 1 }
    if ($4 !~ /^JG-[A-Z0-9-]+$/) { print "missing joint group: " $2 > "/dev/stderr"; exit 1 }
    if ($5 !~ /^(full|partial)$/) { print "invalid parent contribution: " $2 " -> " $5 > "/dev/stderr"; exit 1 }
    if ($6 !~ /^SD-[A-Z]+-[A-Z]+-[0-9]+(, SD-[A-Z]+-[A-Z]+-[0-9]+)*$/) {
      print "invalid canonical Design ID list: " $2 " -> " $6 > "/dev/stderr"; exit 1
    }
    n = split($7, proof_types, "/")
    if (n < 1) { print "missing proof design: " $2 > "/dev/stderr"; exit 1 }
    for (j = 1; j <= n; j++) {
      if (proof_types[j] !~ /^(pure|architecture|contract|integration|concurrency|crash-recovery|projection|real-device|measurement|spike|owner-gate)$/) {
        print "invalid proof type: " $2 " -> " proof_types[j] > "/dev/stderr"; exit 1
      }
    }
    if ($8 == "" || $8 == "—" || $8 == "N/A") { print "missing negative case: " $2 > "/dev/stderr"; exit 1 }
    if ($9 == "" || $9 == "—" || $9 == "N/A") { print "missing target scope: " $2 > "/dev/stderr"; exit 1 }
    if ($10 !~ /^(unaccounted|accounted-for)$/) { print "invalid Accounting status: " $2 " -> " $10 > "/dev/stderr"; exit 1 }
    if ($11 !~ /^(undesigned|designed|blocked-by-spike|blocked-by-owner|deferred)$/) {
      print "invalid Design status: " $2 " -> " $11 > "/dev/stderr"; exit 1
    }
    if ($12 !~ /^(unplanned|planned|implemented|passing|blocked-by-spike|blocked-by-owner|not-applicable)$/) {
      print "invalid Proof status: " $2 " -> " $12 > "/dev/stderr"; exit 1
    }
  }
' docs/system-design/slices/*.md

# 各Obligationのcanonical Design IDが実在することを、列grammar検査とは別に確認する。
awk -F '|' '
  /^\| DO-/ {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $6)
    gsub(/, /, "\n", $6)
    print $6
  }
' docs/system-design/slices/*.md | sort -u > "$check_tmp/obligation-design-refs"
comm -23 "$check_tmp/obligation-design-refs" "$check_tmp/canonical-unique" > "$check_tmp/missing-obligation-design-refs"
test ! -s "$check_tmp/missing-obligation-design-refs"

if rg -n 'SD-[A-Z]+-[A-Z]+-[0-9]+/[0-9]+|AC-[A-Z]+-[0-9]+[–/][0-9]+' docs/system-design/slices; then
  echo 'shorthand Design ID or non-atomic Parent AC found' >&2
  exit 1
fi

while IFS=: read -r source_file source_line markdown_target; do
  target="${markdown_target#](}"
  case "$target" in
    http://*|https://*|mailto:*|'') continue ;;
  esac
  target="${target%%#*}"
  test -z "$target" && continue
  if ! test -e "$(dirname "$source_file")/$target"; then
    echo "broken relative Markdown link: $source_file:$source_line -> $target" >&2
    exit 1
  fi
done < <(rg -n --no-heading --glob '*.md' -o '\]\([^#)[:space:]]+' docs/system-design || true)

git diff --check

printf 'PASS(structural-index) REQ=%s AC=%s canonical=%s states=%s stateOwners=%s parentAC=%s obligations=%s revision=%s\n' \
  "$(wc -l < "$check_tmp/source-req")" \
  "$(wc -l < "$check_tmp/source-ac")" \
  "$(wc -l < "$check_tmp/canonical-unique")" \
  "$state_count" \
  "$state_owner_count" \
  "$(wc -l < "$check_tmp/slice-parent-ac")" \
  "$(wc -l < "$check_tmp/obligations-unique")" \
  "$(docs/system-design/verification/system-design-revision.sh)"

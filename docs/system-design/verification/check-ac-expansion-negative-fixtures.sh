#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"
fixture_tmp="$(mktemp -d)"
trap 'rm -r "$fixture_tmp"' EXIT

tranches=docs/system-design/verification/expansion-tranches.tsv
authority=docs/system-design/00-design-authority.md
ids=docs/system-design/verification/approvals/SD-REV-WP01-PER-GRAPH-001-design-ids.txt
definitions=docs/system-design/verification/approvals/SD-REV-WP01-PER-GRAPH-001-definitions.tsv
manifest=docs/system-design/verification/approvals/SD-REV-WP01-PER-GRAPH-001-dependencies.tsv

expect_failure() {
  if "$@" >/dev/null 2>&1; then
    echo "negative fixture unexpectedly passed: $*" >&2
    exit 1
  fi
}

# Exercise the same tranche checker against copies of the real ledger.
docs/system-design/verification/check-tranche-dependency-dag.sh "$tranches"
awk -F '\t' 'BEGIN{OFS="\t"} $1=="TR-WP01-PER-GRAPH-001" {$7=$1} {print}' \
  "$tranches" > "$fixture_tmp/tranche-self.tsv"
expect_failure docs/system-design/verification/check-tranche-dependency-dag.sh "$fixture_tmp/tranche-self.tsv"
awk -F '\t' 'BEGIN{OFS="\t"} $1=="TR-WP01-ACOU-001" {$8="review-pending"} {print}' \
  "$tranches" > "$fixture_tmp/tranche-unaccepted.tsv"
expect_failure docs/system-design/verification/check-tranche-dependency-dag.sh "$fixture_tmp/tranche-unaccepted.tsv"
awk -F '\t' 'BEGIN{OFS="\t"} $1=="TR-PILOT-ABC" {$7="TR-WP01-PER-GRAPH-001"} {print}' \
  "$tranches" > "$fixture_tmp/tranche-cycle.tsv"
if docs/system-design/verification/check-tranche-dependency-dag.sh "$fixture_tmp/tranche-cycle.tsv" \
  > /dev/null 2> "$fixture_tmp/tranche-cycle-error"; then exit 1; fi
rg -q 'tranche dependency cycle detected' "$fixture_tmp/tranche-cycle-error"

# Exercise the same dependency-manifest shape checker against real review inputs.
docs/system-design/verification/check-dependency-manifest-shape.sh "$authority" "$ids" "$definitions" "$manifest"
awk 'NR!=2' "$manifest" > "$fixture_tmp/manifest-row-deleted.tsv"
expect_failure docs/system-design/verification/check-dependency-manifest-shape.sh \
  "$authority" "$ids" "$definitions" "$fixture_tmp/manifest-row-deleted.tsv"
awk -F '|' 'BEGIN{OFS="|"} {
  if($0 ~ /^\| SD-MOD-EXE-006 /) $9=" blocked-by-owner "
  print
}' "$authority" > "$fixture_tmp/authority-invalid-status.md"
expect_failure docs/system-design/verification/check-dependency-manifest-shape.sh \
  "$fixture_tmp/authority-invalid-status.md" "$ids" "$definitions" "$manifest"
awk -F '\t' 'BEGIN{OFS="\t"} $1=="SD-MOD-EXE-006" {$2="SD-MISSING-001"} {print}' \
  "$manifest" > "$fixture_tmp/manifest-missing-target.tsv"
expect_failure docs/system-design/verification/check-dependency-manifest-shape.sh \
  "$authority" "$ids" "$definitions" "$fixture_tmp/manifest-missing-target.tsv"
awk -F '\t' 'BEGIN{OFS="\t"} $1=="SD-MOD-EXE-006" {$2=$1} {print}' \
  "$manifest" > "$fixture_tmp/manifest-self.tsv"
expect_failure docs/system-design/verification/check-dependency-manifest-shape.sh \
  "$authority" "$ids" "$definitions" "$fixture_tmp/manifest-self.tsv"

# Exercise the production covered-completion checker with a copied real slice whose accepted
# non-Pilot full obligation is mutated to partial.
mapfile -t production_slices < <(printf '%s\n' docs/system-design/slices/*.md)
docs/system-design/verification/check-covered-completion-set.sh \
  docs/system-design/verification/ac-inventory.md \
  docs/system-design/verification/obligation-assignments.tsv "$tranches" "${production_slices[@]}"
acoustic_slice=docs/system-design/slices/04-acoustic-one-wake-one-command.md
awk 'BEGIN{changed=0} {
  if(!changed && /^\| DO-/ && $0 ~ /\| full \|/) {sub(/\| full \|/, "| partial |"); changed=1}
  print
} END{if(!changed) exit 1}' "$acoustic_slice" > "$fixture_tmp/acoustic-partial.md"
mutated_slices=()
for slice in "${production_slices[@]}"; do
  test "$slice" = "$acoustic_slice" || mutated_slices+=("$slice")
done
mutated_slices+=("$fixture_tmp/acoustic-partial.md")
expect_failure docs/system-design/verification/check-covered-completion-set.sh \
  docs/system-design/verification/ac-inventory.md \
  docs/system-design/verification/obligation-assignments.tsv "$tranches" "${mutated_slices[@]}"

printf 'PASS(ac-expansion-negative-fixtures) self=reject cycle=reject unaccepted=reject same-wp=allow row-delete=reject status=reject missing=reject manifest-self=reject partial-sibling=reject\n'

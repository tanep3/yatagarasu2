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

# Runtime Bindingの7 Effectはgeneric operation DTOへ畳まず、同名dispatch型を
# closed payloadへ直接登録する。表の欠落、重複、planned/dispatch名のずれを検出する。
rbi_contract='docs/system-design/contracts/runtime-binding.md'
rg --no-filename '^### SD-EFX-RBI-[0-9]+ — ' "$rbi_contract" \
  | sed -E 's/^### (SD-EFX-RBI-[0-9]+) — (.*)$/\1\t\2/' \
  | sort > "$check_tmp/rbi-effects"

awk -F '|' '
  /^\| `SD-EFX-RBI-[0-9]+` / {
    for (i = 2; i <= 5; i++) {
      gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i)
    }
    print $2 "\t" $3 "\t" $4 "\t" $5
  }
' "$rbi_contract" | sort > "$check_tmp/rbi-payload-map"

cut -f1 "$check_tmp/rbi-effects" > "$check_tmp/rbi-effect-ids"
cut -f1 "$check_tmp/rbi-payload-map" > "$check_tmp/rbi-map-ids"
diff -u "$check_tmp/rbi-effect-ids" "$check_tmp/rbi-map-ids"
test "$(wc -l < "$check_tmp/rbi-effect-ids")" -eq 8

while IFS=$'\t' read -r design_id effect_type; do
  mapping="$(awk -F '\t' -v id="$design_id" '$1 == id { print $2 "\t" $3 "\t" $4 }' "$check_tmp/rbi-payload-map")"
  test -n "$mapping"
  IFS=$'\t' read -r planned_type dispatch_type result_type <<< "$mapping"
  test "$planned_type" = "${effect_type}Plan"
  test "$dispatch_type" = "$effect_type"
  test -n "$result_type"
  rg -q "planned: ${effect_type}Plan" "$rbi_contract"
  test "$(awk -F '\t' -v id="$design_id" '$1 == id { n++ } END { print n + 0 }' "$check_tmp/rbi-payload-map")" -eq 1
done < "$check_tmp/rbi-effects"

if rg -q 'CapabilityBindingOperation(Plan|Dispatch)' "$rbi_contract"; then
  echo 'generic Runtime Binding operation payload found' >&2
  exit 1
fi

# Recovery custodyの出口がActiveから直接Releasedにならず、Reconciledを経由し、
# StillUnknownをReleasedへ変換しない構造を固定する。
execution_contract='docs/system-design/contracts/execution.md'
rg -q '^\| `Active` \| `Reconciled` \|' "$execution_contract"
rg -q '^\| `Reconciled` \| `Released` \| `DefinitelyApplied`または`DefinitelyNotApplied` \|$' "$execution_contract"
rg -q '^\| `Reconciled` \| `Quarantined` \| `StillUnknown` \+ Owner Quarantine Decision \|$' "$execution_contract"
test "$(rg -c '^\| `(Active|Reconciled)` \| `(Reconciled|Released|Quarantined)` \|' "$execution_contract")" -eq 3
rg -q '^### SD-TRN-EXE-011 — ApplyRecoveryCustodyResolution$' "$execution_contract"
rg -q '^### SD-TRN-EXE-012 — FinalizeRecoveryCustody$' "$execution_contract"
rg -q '^### SD-PER-EXE-005 — RecoveryCustodyResolutionUoW$' "$execution_contract"

# 初期Recoveryは再試行loopを持たない。各custodyのQuery/Cancel/Reconcileは
# 最大一Occurrence・一attemptで、最終的に不明ならQuarantineへ閉じる。
if rg -q 'ContinueRecovery|ContinueQuery|ContinueReconcile' docs/system-design/contracts; then
  echo 'continuing Recovery decision found in one-shot recovery release' >&2
  exit 1
fi
rg -q '各最大一Occurrence、各最大一attempt' "$execution_contract"
rg -q 'StillUnknown.*必ずQuarantined' "$execution_contract"
rg -q '各最大一Occurrence・一attempt' docs/system-design/contracts/runtime-binding.md
rg -q '各最大一Occurrence・一attempt' docs/system-design/contracts/configuration-application.md
test "$(rg -c '各最大一Occurrence・一attempt' docs/system-design/contracts/finite-conversation.md)" -ge 3
rg -q '各最大一Occurrence・一attempt' docs/system-design/contracts/migration-and-restart.md

# Codex runtime queryはProbe専用であり、Agent turn queryとはPort/Effect/Eventを共有しない。
conversation_contract='docs/system-design/contracts/finite-conversation.md'
runtime_contract='docs/system-design/contracts/runtime-binding.md'
rg -q 'ProbeOperationQueryObserved' "$conversation_contract"
rg -q '^### SD-EFX-AGT-009 — QueryAgentTurnOperation$' "$conversation_contract"
rg -q '^### SD-EVT-AGT-009 — AgentTurnQueryObserved$' "$conversation_contract"
if rg -n 'target_kind: Probe \| AgentTurn|probeまたはturn dispatch' "$runtime_contract" "$conversation_contract"; then
  echo 'AgentTurn target leaked into Codex runtime probe query' >&2
  exit 1
fi

# Recovery resolutionはowner State、owner use、custody/leaseを同時に終端できる
# closed lifecycleを持つ。
rg -U -q 'AgentRuntimeBindingUseRecord \{[\s\S]*lifecycle: Acquired \| ReleasePending \| Released \| Recovery \| Quarantined' "$conversation_contract"
rg -U -q 'AgentTurnBinding \{[\s\S]*Terminal \| Interrupted \| Recovery \| Quarantined' "$conversation_contract"
rg -q '^### SD-EVT-AGT-014 — AgentTurnRecoveryResolved$' "$conversation_contract"
rg -q '^### SD-TRN-AGT-011 — ApplyAgentTurnRecoveryResolution$' "$conversation_contract"
rg -q '^### SD-EVT-AGT-015 — ThreadResetRecoveryResolved$' "$conversation_contract"
rg -q '^### SD-TRN-AGT-012 — ApplyThreadResetRecoveryResolution$' "$conversation_contract"
rg -U -q 'ToolRecoveryRecord \{[\s\S]*lifecycle: Recovering \| Resolved \| Quarantined' "$conversation_contract"
rg -q '^### SD-EVT-TOL-006 — ToolOperationRecoveryResolved$' "$conversation_contract"
rg -q '^### SD-TRN-CNV-006 — ApplyToolRecoveryResolution$' "$conversation_contract"
migration_contract='docs/system-design/contracts/migration-and-restart.md'
rg -U -q 'RuntimeRestartRecord \{[\s\S]*Completed \| Failed \|[\s\S]*OutcomeUnknown \| Recovery \| Quarantined' "$migration_contract"
rg -U -q 'MigrationPlanRecord \{[\s\S]*Completed \|[\s\S]*Failed \| Restored \| OutcomeUnknown \| Recovering \| Quarantined' "$migration_contract"
rg -q '^### SD-EVT-MIG-003 — MigrationRecoveryResolved$' "$migration_contract"
rg -q '^### SD-TRN-MIG-003 — RecordMigrationRecoveryResolution$' "$migration_contract"
rg -U -q 'BindingGenerationRecord \{[\s\S]*Rejected \| OutcomeUnknown \| Recovery \| Quarantined' "$runtime_contract"

# Migrationの五Effectはplanned valueをdispatchへ丸ごと埋め込み、Query/Cancel/
# Reconcileを別Result variantへ全域写像する。Query variantへのcancel field混入も拒否する。
rg --no-filename '^### SD-EFX-MIG-[0-9]+ — ' "$migration_contract" \
  | sed -E 's/^### (SD-EFX-MIG-[0-9]+) — (.*)$/\1\t\2/' \
  | sort > "$check_tmp/mig-effects"
awk -F '|' '
  /^\| `SD-EFX-MIG-[0-9]+` / {
    for (i = 2; i <= 5; i++) gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i)
    print $2 "\t" $3 "\t" $4 "\t" $5
  }
' "$migration_contract" | sort > "$check_tmp/mig-payload-map"
cut -f1 "$check_tmp/mig-effects" > "$check_tmp/mig-effect-ids"
cut -f1 "$check_tmp/mig-payload-map" | sort -u > "$check_tmp/mig-map-ids"
diff -u "$check_tmp/mig-effect-ids" "$check_tmp/mig-map-ids"
test "$(wc -l < "$check_tmp/mig-effect-ids")" -eq 5
test "$(wc -l < "$check_tmp/mig-payload-map")" -eq 10
test "$(awk -F '\t' '$1 == "SD-EFX-MIG-001" { n++ } END { print n + 0 }' "$check_tmp/mig-payload-map")" -eq 6
for effect_id in SD-EFX-MIG-002 SD-EFX-MIG-003 SD-EFX-MIG-004 SD-EFX-MIG-005; do
  test "$(awk -F '\t' -v id="$effect_id" '$1 == id { n++ } END { print n + 0 }' "$check_tmp/mig-payload-map")" -eq 1
done
while IFS=$'\t' read -r design_id planned_type dispatch_type result_type; do
  test -n "$design_id"
  test -n "$planned_type"
  test -n "$dispatch_type"
  test -n "$result_type"
  rg -q "planned: ${planned_type}" "$migration_contract"
  rg -q "$dispatch_type" "$migration_contract"
  rg -q "$result_type" "$migration_contract"
done < "$check_tmp/mig-payload-map"

# operation固有Plan/Dispatchのfield closure。generic operation_kind/payloadへ畳まず、
# ApplyStepだけがpayload/dependencyを、Verify/Restoreだけが各検証契約を持つ。
for planned_type in \
  InspectMigrationPlan CreateMigrationRecoveryPointPlan \
  VerifyMigrationRecoveryPointPlan ApplyMigrationStepPlan \
  VerifyMigrationTargetPlan RestoreMigrationRecoveryPointPlan; do
  rg -q "planned: ${planned_type}" "$migration_contract"
done
rg -U -q 'ApplyMigrationStepPlan \{[\s\S]*step_id, step_payload_ref,[\s\S]*dependency_stage_refs, stable_operation_id' "$migration_contract"
rg -U -q 'ApplyMigrationStep \{[\s\S]*exact_step_id, exact_step_payload_ref,[\s\S]*exact_dependency_event_refs' "$migration_contract"
rg -U -q 'VerifyMigrationTargetPlan \{[\s\S]*target_version, verification_contract' "$migration_contract"
rg -U -q 'RestoreMigrationRecoveryPointPlan \{[\s\S]*recovery_point_ref, restore_contract' "$migration_contract"
if rg -q 'MigrationOperationPlan|operation_kind, logical_refs' "$migration_contract"; then
  echo 'generic Migration operation payload found' >&2
  exit 1
fi
awk '/^### SD-EVT-MIG-002 /,/^### SD-EVT-MIG-003 /' "$migration_contract" \
  | awk '/  QueryObserved \{/,/^  \}/' > "$check_tmp/mig-query-event"
test -s "$check_tmp/mig-query-event"
if rg -qi 'cancel' "$check_tmp/mig-query-event"; then
  echo 'cancel field leaked into Migration QueryObserved variant' >&2
  exit 1
fi
rg -U -q 'MigrationQueryObserved \{[\s\S]*plan_id, stage_ref, original_stable_operation_id,[\s\S]*stable_query_operation_id, observed_state, certainty' "$migration_contract"
rg -U -q 'MigrationCancelObserved \{[\s\S]*plan_id, stage_ref, original_stable_operation_id,[\s\S]*stable_cancel_operation_id, cancel_result, certainty' "$migration_contract"
rg -U -q 'MigrationReconcileObserved \{[\s\S]*plan_id, stage_ref, original_stable_operation_id,[\s\S]*stable_reconcile_operation_id, query_evidence_ref,[\s\S]*observed_state, certainty' "$migration_contract"

# Migration owner lifecycleは中間DefinitelyAppliedを一段だけ進め、final verify以外を
# Completed/Restoredへ写像しない。
rg -U -q 'MigrationPlanRecord \{[\s\S]*stages: MigrationStageLedger,[\s\S]*next_stage: MigrationNextStage' "$migration_contract"
rg -U -q 'MigrationStepRecord \{[\s\S]*step_payload_ref[\s\S]*dependencies:[\s\S]*lifecycle:[\s\S]*result_event_ref' "$migration_contract"
rg -q '^### SD-RUL-MIG-003 — DecideMigrationStageAdvance$' "$migration_contract"
rg -q '^### SD-TRN-MIG-004 — AdvanceMigrationStage$' "$migration_contract"
rg -q '^### SD-PER-MIG-003 — MigrationStageAdvanceUoW$' "$migration_contract"
rg -q '中間DefinitelyAppliedは一stageだけApplied' "$migration_contract"
rg -q 'final target verificationだけをCompleted、restore verificationだけをRestored' "$migration_contract"
rg -F -q '| `Planned` | `InspectResolved.DefinitelyApplied` | `Preflighted` | `CreateRecoveryPoint` |' "$migration_contract"
rg -F -q '| `Preflighted` | `RecoveryPointVerified.DefinitelyApplied` | `BackupVerified` | `ApplyStep(first)` |' "$migration_contract"
rg -F -q '| `BackupVerified \| Applying` | final `ApplyStepResolved.DefinitelyApplied` | `Verifying` | `VerifyTarget` |' "$migration_contract"
rg -F -q '| `Verifying` | `TargetVerified.DefinitelyApplied` | `Completed` | `None` |' "$migration_contract"
rg -F -q '| `Recovering` | `RecoveryPointRestored.DefinitelyApplied` | `Restored` | `None` |' "$migration_contract"
rg -F -q '| `Recovering \| OutcomeUnknown` | `StillUnknown` | `Quarantined` | `None` |' "$migration_contract"
test "$(awk '
  /Migration planの許可lifecycle\/next-stage edgeは次だけです。/ { in_table=1; next }
  in_table && /^\| / && !/^\| From plan lifecycle / && !/^\| --- / { rows++ }
  in_table && /^Completed、Restored、Quarantinedはterminal/ { print rows + 0; exit }
' "$migration_contract")" -eq 10
rg -q '上表にないskip、二段advance、Completed/Restoredからの遷移、intermediate resultからのCompletedを拒否' "$migration_contract"

# RST ReconcileはQuery、またはQuery+Cancelのterminal dependencyとowner-issued
# evidence factの双方を必要とする。
rg -q 'dependencies: V<-C terminal, R<-V terminal' "$migration_contract"
rg -q 'dependencies: Z<-Q terminal' "$migration_contract"
rg -q 'Z<-Q terminal, Z<-X terminal' "$migration_contract"
rg -q 'QueryRecovery.Z requires RuntimeRestartQueryObserved owner fact' "$migration_contract"
rg -q 'CancelAndQueryRecovery.Z requires RuntimeRestartQueryObserved and' "$migration_contract"
rg -q 'RuntimeRestartCancellationObserved owner facts' "$migration_contract"

# Thread reset DefinitelyNotAppliedとactive-work handoff/Qualia四値Decisionの出口。
rg -q 'NotAppliedAwaitingExplicitRestart' "$conversation_contract"
rg -q '^### SD-RUL-AGT-011 — AdmitExplicitContinuityRestart$' "$conversation_contract"
rg -q '^### SD-TRN-AGT-013 — BeginExplicitContinuityRestart$' "$conversation_contract"
for decision in ResumeFromCheckpoint AwaitOwnerDecision TerminateToHome QuarantineResource; do
  rg -q "$decision" "$conversation_contract"
done
rg -q '^### SD-RUL-QLI-001 — DecideQualiaRecovery$' "$conversation_contract"
rg -q '^### SD-TRN-QLI-002 — ApplyQualiaRecoveryDecision$' "$conversation_contract"
rg -q '^### SD-RUL-RST-004 — DecideActiveWorkHandoffRelease$' "$migration_contract"
rg -q '^### SD-PER-RST-004 — ActiveWorkHandoffReleaseUoW$' "$migration_contract"

# 非Codex BindingUseもcustody quarantineと同じterminalへ進む。
rg -U -q 'BindingUseRecord \{[\s\S]*Released \| Recovery \| Quarantined,[\s\S]*recovery_custody_ref: RequiredWhen<Recovery \| Quarantined, RecoveryCustodyId>' "$runtime_contract"

# ResumeFromCheckpointはQLIだけをActiveにせず、閉じたBehavior
# Contribution、checkpoint owner Transition、EXE resume planをcross-owner UoWで同時commitする。
rg -q '^### SD-MOD-EXE-002 — ResumeContributionContract$' "$execution_contract"
rg -U -q 'ResumeContribution<C> \{[\s\S]*checkpoint_digest,[\s\S]*pinned_revisions,[\s\S]*behavior_resume_rule_ref:[\s\S]*behavior_resume_transition_ref:[\s\S]*execution_resume_plan: ExecutionResumePlan' "$execution_contract"
rg -q '^### SD-RUL-EXE-004 — ValidateExecutionResumePlan$' "$execution_contract"
rg -q '^### SD-TRN-EXE-013 — ApplyExecutionResumePlan$' "$execution_contract"
rg -U -q 'ResumeReplacementPlan \{[\s\S]*replacement_occurrence_id,[\s\S]*planned_effect_spec: PlannedEffectSpec<P>,[\s\S]*dependencies, guard, resource_claims' "$execution_contract"
rg -q '新しいOccurrenceを`AwaitingClaim`として登録' "$execution_contract"
if awk '/^### SD-TRN-EXE-013 /,/^### SD-TRN-EXE-002 /' "$execution_contract" \
  | rg -q 'DispatchIntentCommittedへ進め|durable dispatch intent/outboxを登録|不変dispatch effect、lease'; then
  echo 'checkpoint resume transition bypasses normal dispatch claim' >&2
  exit 1
fi
rg -q '必ず後続のBehavior固有normal dispatch UoW' "$execution_contract"
rg -q '^### SD-RUL-CNV-005 — BuildFiniteConversationResumeContribution$' "$conversation_contract"
rg -q '^### SD-TRN-CNV-007 — ApplyFiniteConversationResumeCheckpoint$' "$conversation_contract"
rg -U -q 'ResumeFromCheckpoint \{[\s\S]*safe_checkpoint_ref,[\s\S]*resume_contribution: BehaviorResumeContribution' "$conversation_contract"
awk '/^### SD-PER-RST-004 /,/^### SD-REC-RST-001 /' "$migration_contract" > "$check_tmp/handoff-release-uow"
for required in \
  'Behavior ownerのexpected revision' \
  'SD-TRN-EXE-013' \
  'SD-TRN-QLI-002' \
  'checkpoint owner Stateのresume' \
  '新しいplanned Occurrenceの`AwaitingClaim`登録' \
  'attempt、BindingUse、resource lease、dispatch Effect、dispatch intent/outboxを作りません' \
  'Behavior固有normal dispatch UoW' \
  'Behavior checkpointだけConsumed' \
  'attempt/intent/outboxだけを残しません'; do
  rg -q "$required" "$check_tmp/handoff-release-uow"
done
rg -q 'Behavior ContributionなしResume' docs/system-design/slices/02-finite-conversation.md
rg -q 'QLIだけActive' docs/system-design/slices/02-finite-conversation.md

# Resumeは世代付きlineageとnormal claimの同一commitを必須とし、Qualia一件keyや
# Resume専用dispatchで二回目以降を塞がない。
rg -q '^### SD-MOD-EXE-003 — ExecutionLineageAndResumeProvenance$' "$execution_contract"
rg -U -q 'InteractionExecutionSubject \{[\s\S]*lineage_id, generation,[\s\S]*interaction_id, qualia_session_id' "$execution_contract"
rg -U -q 'OccurrenceRecord<P> \{[\s\S]*execution_subject: ExecutionSubjectRef,[\s\S]*occurrence_origin: OccurrenceOrigin' "$execution_contract"
rg -q 'resume_commits: Map<ExecutionResumeCommitId' "$execution_contract"
if rg -q 'resume_commits: Map<QualiaSessionId' "$execution_contract"; then
  echo 'single Qualia-keyed resume commit registry found' >&2
  exit 1
fi
rg -q '^### SD-RUL-EXE-005 — DecideCheckpointResumeClaimOutcome$' "$execution_contract"
rg -q '^### SD-EVT-EXE-007 — CheckpointResumeClaimResolved$' "$execution_contract"
rg -q '^### SD-TRN-EXE-014 — ApplyCheckpointResumeClaimOutcome$' "$execution_contract"
rg -q '^### SD-PER-EXE-006 — ResumeAwareNormalDispatchClaimComposition$' "$execution_contract"
rg -q 'Resume provenanceがあるOccurrenceではさらに`SD-RUL-EXE-005`を必須評価' "$execution_contract"
rg -q 'requestだけClaimed、またはattemptだけを残しません' "$execution_contract"
rg -q 'InteractionLineage.*Revoked' "$execution_contract"
rg -q '将来generationの登録とclaimを拒否' "$execution_contract"

# 初期Interaction仕事はgeneration 0のlineage/subject、Behavior State、Graphを
# 同じadmission UoWで一度だけ登録する。
rg -q '^### SD-EVT-EXE-008 — InitialExecutionLineageAdmitted$' "$execution_contract"
rg -q '^### SD-RUL-EXE-006 — ValidateInitialExecutionLineageAdmission$' "$execution_contract"
rg -q '^### SD-TRN-EXE-015 — InitializeExecutionLineage$' "$execution_contract"
rg -q '^### SD-PER-EXE-007 — InitialInteractionExecutionAdmissionComposition$' "$execution_contract"
rg -U -q 'ExecutionSubjectRecord \{[\s\S]*origin:[\s\S]*InitialAdmission' "$execution_contract"
rg -q 'generation `0`の`ExecutionLineageRecord\(Active\)`' "$execution_contract"
rg -q '同じadmission identityと同じ全payloadの再送' "$execution_contract"
rg -q 'SD-PER-EXE-007.*SD-RUL-EXE-006.*SD-TRN-EXE-015' "$conversation_contract"
rg -q 'SD-PER-EXE-007.*SD-RUL-EXE-006.*SD-EVT-EXE-008.*SD-TRN-EXE-015' docs/system-design/contracts/camera-observation.md
rg -q 'CFG useだけ、BRP/IRP useだけ、INT/QLIだけ、lineage/Graphだけの部分commit' docs/system-design/slices/01-camera-observation.md
rg -q 'CFG useだけ、BRP/IRP useだけ、INT/QLI/CNVだけ、lineage/Graphだけの部分commit' docs/system-design/slices/02-finite-conversation.md

# EXEの恒久claim拒否はBehavior ownerの閉じたmappingへ渡し、有限Conversationを
# typed Failure/Projection/Interaction terminal/Qualia Home経路へ原子収束させる。
rg -U -q 'ResumeContribution<C> \{[\s\S]*behavior_claim_rejection_rule_ref:[\s\S]*behavior_claim_rejection_transition_ref:' "$execution_contract"
rg -q '^### SD-EVT-CNV-005 — FiniteConversationResumeClaimRejected$' "$conversation_contract"
rg -q '^### SD-RUL-CNV-007 — MapFiniteConversationResumeClaimRejection$' "$conversation_contract"
rg -q '^### SD-TRN-CNV-009 — ApplyFiniteConversationResumeClaimRejection$' "$conversation_contract"
rg -q '^### SD-TRN-INT-002 — ApplyInteractionTerminalResult$' "$conversation_contract"
rg -q '^### SD-PER-CNV-003 — FiniteConversationResumeClaimRejectionUoW$' "$conversation_contract"
rg -F -q '`Qualia Active + Conversation Open/ResponseAccepted`' "$conversation_contract"
rg -q 'source EXE rejection Eventとterminal result identityからUoW全体を再開' "$conversation_contract"
rg -F -q 'EXE Rejected後にQualia Active+turn Open' docs/system-design/slices/02-finite-conversation.md

# 同じ有限Qualiaの次resumeは、current subject上の明示safe progressから新しい
# checkpoint generationを作った場合だけ可能である。
rg -q '^### SD-EVT-CNV-004 — FiniteConversationSafeProgressReached$' "$conversation_contract"
rg -q '^### SD-RUL-CNV-006 — BuildNextFiniteConversationSafeCheckpoint$' "$conversation_contract"
rg -q '^### SD-TRN-CNV-008 — RegisterNextFiniteConversationSafeCheckpoint$' "$conversation_contract"
rg -q '^### SD-PER-CNV-002 — FiniteConversationSafeProgressCheckpointUoW$' "$conversation_contract"
rg -U -q 'ConversationResumeCheckpointRecord \{[\s\S]*checkpoint_generation,[\s\S]*execution_subject: InteractionExecutionSubject,[\s\S]*completed_node_digests,[\s\S]*resumeable_node_digests' "$conversation_contract"
rg -q 'Resume直後、Adapter受付、clock経過だけでは生成せず' "$conversation_contract"
rg -q '受理済み応答を再生成するcandidateを拒否' "$conversation_contract"

# handoffの作用域はrestart epochとexact source subject generationで閉じる。
rg -q '^### SD-MOD-RST-002 — RestartHandoffEpoch$' "$migration_contract"
rg -U -q 'ActiveWorkHandoffTarget \{[\s\S]*restart_epoch,[\s\S]*exact_execution_subject: InteractionExecutionSubject' "$migration_contract"
rg -q '後続replacement subjectはこのhandoffのtargetへ追加しません' "$migration_contract"
rg -q '旧epochの遅延結果はexact旧handoffへ隔離' "$migration_contract"
rg -U -q 'QualiaState \{[\s\S]*active_recovery_epoch\?: RestartHandoffEpoch,[\s\S]*recovery_history: Map<RestartHandoffEpoch' "$conversation_contract"

# RestartAdapterはcandidate準備とatomic group activationを分離する。通常結果と
# RecoveryはStagedReadyまでで、CFG cross-owner UoWだけがEffectiveを作る。
configuration_contract='docs/system-design/contracts/configuration-application.md'
rg -U -q 'BindingGenerationRecord \{[\s\S]*Candidate \{[\s\S]*StagedReady \{[\s\S]*desired_revision, atomic_group_id' "$runtime_contract"
rg -q '^### SD-RUL-RBI-005 — ValidateRuntimeBindingCandidateStaging$' "$runtime_contract"
rg -q '^### SD-RUL-RBI-006 — ValidateStagedRuntimeCandidateActivation$' "$runtime_contract"
rg -q '^### SD-EVT-RBI-006 — RuntimeBindingCandidateStaged$' "$runtime_contract"
rg -q '^### SD-EVT-RBI-007 — RuntimeBindingGenerationActivated$' "$runtime_contract"
rg -q '^### SD-PER-RBI-004 — RuntimeBindingCandidateStagingUoW$' "$runtime_contract"
rg -q 'Materialize／Probe成功はcandidateを`StagedReady`にするだけ' "$runtime_contract"
rg -q 'materialize RecoveryからEffectiveへ直接進めず' "$runtime_contract"
rg -q '^### SD-RUL-CFG-007 — DecideAtomicGroupActivation$' "$configuration_contract"
rg -q 'CFG、RCP、EXEと宣言された全target ownerのexpected revisionを全CAS' "$configuration_contract"
rg -q 'CFGだけ新snapshot、target AだけEffective、target Bだけ旧generation、candidate slotだけFree、NamedInterval leaseだけReleased、またはAllBindingUsesReleasedだけを構築できません' "$configuration_contract"
rg -q 'target一件だけEffective' docs/system-design/slices/03-configuration-capability.md
rg -q 'A/B両candidateがStagedReady' docs/system-design/slices/03-configuration-capability.md

# activation時点で旧generationがzero-useなら退役Graphを同じcommitで登録する。
# candidate並行probeはCapability/Profileの明示能力とspike証拠を必須にする。
rg -q '^### SD-PRF-RBI-001 — RuntimeCandidateProbeCapabilityProfile$' "$runtime_contract"
for candidate_capability in ParallelCandidateProbeSupported RequiresGlobalRestart; do
  rg -q "$candidate_capability" "$runtime_contract"
done
rg -q '^### SD-RUL-RBI-007 — DecidePostActivationGenerationDrain$' "$runtime_contract"
rg -q '^### SD-RUL-RBI-008 — AuthorizeRuntimeCandidateProbeStrategy$' "$runtime_contract"
rg -q '自動書換えしません' "$runtime_contract"
rg -q 'Useが0件なら、generation-derived identityの`SD-EVT-RBI-003 AllBindingUsesReleased`' "$configuration_contract"
rg -q '並行する最後のUse解放も同じruntime owner/EXE revisionをCAS' "$configuration_contract"
rg -q 'zero-use旧generationが永久Retiring' docs/system-design/slices/03-configuration-capability.md
rg -q 'singleton local-managed旧/candidateを未証明で並行起動' docs/system-design/slices/03-configuration-capability.md

# CFG/BRP/IRP RevisionUse取得は独立admissionではなく、各Behaviorのgeneration 0
# lineage/Graph登録UoWへ合成するcomponentである。
rg -q '^### SD-PER-CFG-005 — ConfigurationRoutingRevisionUseAcquisitionComponent$' "$configuration_contract"
awk '/^### SD-PER-CFG-005 /,/^### SD-PER-CFG-006 /' "$configuration_contract" > "$check_tmp/revision-use-acquisition-component"
rg -q '三つのRevisionUse取得だけを一つのTransition compositionとして返します' "$check_tmp/revision-use-acquisition-component"
rg -q '単独commitを禁止します' "$check_tmp/revision-use-acquisition-component"
rg -q 'SD-PER-EXE-007.*各Behavior初期UoW' "$check_tmp/revision-use-acquisition-component"
rg -q 'CFG useだけ、BRP/IRP useだけ、INT/QLIだけ、lineage/Graphだけ' "$check_tmp/revision-use-acquisition-component"
rg -q 'CFG、BRP、IRP、INT、QLI、Behavior owner、EXEのexpected revision' "$execution_contract"
rg -q 'SD-PER-CFG-005.*SD-PER-EXE-007' "$conversation_contract"
rg -q 'SD-PER-CFG-005.*SD-PER-EXE-007' docs/system-design/contracts/camera-observation.md
rg -q 'PER-CFG-005がINT/QLIを単独admit' docs/system-design/slices/03-configuration-capability.md

# Runtime candidate probe Profileは専用RCP ownerがimmutable revision、proof、
# BindingGeneration use、retention/GCを所有し、Adapterは変更できない。
rg -q '^### SD-CTX-RCP-001 — Runtime Candidate Probe Profile Context$' "$runtime_contract"
rg -q '^### SD-STA-RCP-001 — RuntimeCandidateProbeProfileState$' "$runtime_contract"
rg -U -q 'RuntimeCandidateProbeProfileRevisionRecord \{[\s\S]*immutable_profile: SD-PRF-RBI-001,[\s\S]*proof_status: BlockedBySpike \| Passing,[\s\S]*RegisteredCurrent \| SupersededRetained' "$runtime_contract"
rg -U -q 'RuntimeCandidateProbeProfileRevisionUseRecord \{[\s\S]*binding_generation,[\s\S]*lifecycle: Acquired \| Released,[\s\S]*Retired \| Rejected \| Quarantined' "$runtime_contract"
for rcp_id in \
  SD-EVT-RCP-001 SD-EVT-RCP-002 \
  SD-RUL-RCP-001 SD-RUL-RCP-002 SD-RUL-RCP-003 \
  SD-TRN-RCP-001 SD-TRN-RCP-002 SD-TRN-RCP-003 SD-TRN-RCP-004 \
  SD-PER-RCP-001; do
  rg -q "^### ${rcp_id} — " "$runtime_contract"
done
rg -q 'Adapter、Bootstrap、ProjectionからこのTransitionへ到達しません' "$runtime_contract"
rg -q 'profile missing/Superseded/stale/Blocked、use欠損' "$runtime_contract"
rg -q 'candidate BindingGeneration登録時.*SD-PER-RBI-007.*generation record、candidate slot Held' "$runtime_contract"
rg -q 'BindingGenerationがRetired、Rejected、Quarantinedのいずれかへ終端するときだけ' "$runtime_contract"
rg -q 'AdapterがProfile/proof変更' docs/system-design/slices/03-configuration-capability.md
rg -q 'generationだけ/useだけcommit' docs/system-design/slices/03-configuration-capability.md

# RCP Profile/proof ingressはversion付きrelease/migration seedまたは認証済み
# Linux管理者CLIだけに閉じ、Web/API、Adapter自己申告、暗黙Passingを拒否する。
for rcp_ingress_id in \
  SD-MOD-RCP-001 SD-CMD-RCP-001 SD-CMD-RCP-002 \
  SD-EVT-RCP-003 SD-EVT-RCP-004 \
  SD-RUL-RCP-004 SD-RUL-RCP-005 SD-TRN-RCP-005 \
  SD-PER-RCP-002 SD-PER-RCP-003 SD-PRT-RCP-001; do
  rg -q "^### ${rcp_ingress_id} — " "$runtime_contract"
done
rg -U -q 'RcpProfileSeedArtifactManifest \{[\s\S]*seed_schema_version,[\s\S]*artifact_digest, provenance,[\s\S]*trust_verification_evidence_ref' "$runtime_contract"
rg -U -q 'RcpProofEvidenceBundle \{[\s\S]*exact_profile_revision_ref, evidence_requirement_ref,[\s\S]*measurement_evidence_refs,[\s\S]*failure_injection_evidence_refs,[\s\S]*evidence_bundle_digest' "$runtime_contract"
rg -q '組込みProfileと組込みproofは、version付きrelease/migration seed Artifactからだけ' "$runtime_contract"
rg -q 'ローカルProfileの追加とproof再検証は、認証済みLinux管理者Commandからだけ' "$runtime_contract"
rg -q 'Web/API、runtime Adapter、Skill、LLM' "$runtime_contract"
rg -q 'ローカル追加は必ずBlockedBySpikeで登録' "$runtime_contract"
rg -q 'seed欠落・検証失敗・crash時はRCP未準備' "$runtime_contract"
rg -q '一部Profileや一部Passingを残しません' "$runtime_contract"
rg -q 'Profileだけ、Passingだけ、ingress ledgerだけを残さず' "$runtime_contract"
rg -q 'HTTP/Web/API AdapterをこのPortへwireせず' "$runtime_contract"
rg -q 'Web/API runtime approval' docs/system-design/slices/03-configuration-capability.md
rg -q '同じseed artifact/operation/idempotency/payloadを再送' docs/system-design/slices/03-configuration-capability.md

# normal M/P known failureはCFG step Failedとold effective/snapshot維持を原子化する。
# M applied/P known-negativeは証明済みno-artifact以外をcleanup lifecycleへ移し、
# cleanup/custody確定前にcandidate/RCP use/leaseを解放しない。
for rbi_known_failure_id in \
  SD-RUL-RBI-009 SD-RUL-RBI-010 \
  SD-EVT-RBI-008 SD-EVT-RBI-009 \
  SD-EFX-RBI-008 SD-PER-RBI-005 SD-PER-RBI-006; do
  rg -q "^### ${rbi_known_failure_id} — " "$runtime_contract"
done
rg -U -q 'BindingGenerationRecord \{[\s\S]*RejectingCleanup \{[\s\S]*cleanup_graph_id, cleanup_occurrence_id,[\s\S]*cleanup_operation_id, cleanup_custody_id,[\s\S]*stage: Planned \| InFlight \| Recovery' "$runtime_contract"
rg -U -q 'RuntimeCandidateProbeCapabilityProfile \{[\s\S]*candidate_cleanup:[\s\S]*CleanupRequired[\s\S]*NoCleanupRequiredWhen' "$runtime_contract"
rg -q 'Mが`DefinitelyNotApplied`.*RejectImmediately.NoMaterializedArtifact' "$runtime_contract"
rg -q 'それ以外は`BeginCandidateCleanup`' "$runtime_contract"
rg -q 'Pが失敗した.*事実だけをno-artifact proofにしません' "$runtime_contract"
rg -q 'KがDefinitelyApplied.*DefinitelyNotAppliedと宣言済みno-artifact proof' "$runtime_contract"
rg -q 'candidate_cleanup_graph_id = Hash' "$runtime_contract"
rg -q 'candidate_cleanup_operation_id = Hash' "$runtime_contract"
rg -q 'candidate_cleanup_custody_id = Hash' "$runtime_contract"
rg -q 'RCP RevisionUseをAcquiredのまま保持' "$runtime_contract"
rg -q 'candidate `Rejected`、`SD-EVT-RBI-008`、`ReleaseUse`を生成しません' "$runtime_contract"
rg -F -q 'SD-TRN-RCP-003.ReleaseUse(Rejected)' "$runtime_contract"
rg -q 'SD-TRN-CFG-003.*SD-EVT-CFG-004.Failed' "$runtime_contract"
rg -q 'old effective generationとCFG effective group/snapshotを変更しません' "$runtime_contract"
rg -q 'cleanup DefinitelyNotAppliedは、exact resultとimmutable profileがno artifactを証明する場合だけ' "$runtime_contract"
rg -q 'candidateを`RejectingCleanup.Recovery`、candidate slotをHeld、cleanup custodyをActive、RCP useをAcquiredのまま' "$runtime_contract"
rg -q '一回限りのQ/R後もStillUnknownならcandidate/custody/generation lease/slot lease/slotをQuarantined' "$runtime_contract"
rg -q 'Repeated failed candidateはcandidate generationを含む別cleanup graph/operation/custody identity' "$runtime_contract"
rg -q 'cleanup branchではCFG stepだけFailed、candidateだけRejectingCleanup、Graph/Kだけ、custody/generation leaseだけ、slot/NamedInterval leaseだけ' "$runtime_contract"
rg -q 'MがDefinitelyNotAppliedの確定Failure' docs/system-design/slices/03-configuration-capability.md
rg -q 'M DefinitelyApplied後のPがAuthenticationFailed、cleanup required' docs/system-design/slices/03-configuration-capability.md
rg -q 'cleanup KがCleaned/DefinitelyApplied' docs/system-design/slices/03-configuration-capability.md
rg -q 'cleanup KがNoArtifact/DefinitelyNotApplied' docs/system-design/slices/03-configuration-capability.md
rg -q 'cleanup KがOutcomeUnknown' docs/system-design/slices/03-configuration-capability.md
rg -q 'cleanup Q/R後もStillUnknown' docs/system-design/slices/03-configuration-capability.md
rg -q 'generation G1/G2が連続してP known-negative' docs/system-design/slices/03-configuration-capability.md

# 初期candidate cardinalityはCapability/mode/adapter classごとに1。
# slot、generation、RCP use、Graph、NamedInterval leaseを原子admitし、
# cleanup/Recovery/Quarantine中の二重candidateを拒否する。
for candidate_slot_id in SD-EVT-RBI-010 SD-PER-RBI-007; do
  rg -q "^### ${candidate_slot_id} — " "$runtime_contract"
done
rg -U -q 'SpecificRuntimeState \{[\s\S]*candidate_slots: Map<CapabilityCandidateSlotKey,[\s\S]*candidate_admission_results: Map<CandidateAdmissionIdentity' "$runtime_contract"
rg -U -q 'CapabilityCandidateSlotKey \{[\s\S]*capability_ref, mode, adapter_class' "$runtime_contract"
rg -U -q 'CapabilityCandidateSlotRecord \{[\s\S]*slot_identity,[\s\S]*cardinality_limit: 1,[\s\S]*Free \|[\s\S]*Held \{[\s\S]*holder_generation,[\s\S]*named_interval_lease_id,[\s\S]*Quarantined \{' "$runtime_contract"
rg -U -q 'CandidateAdmissionResultRecord \{[\s\S]*slot_precondition:[\s\S]*Absent \|[\s\S]*Existing \{ expected_slot_revision \}' "$runtime_contract"
rg -U -q 'RuntimeCandidateProbeCapabilityProfile \{[\s\S]*candidate_cardinality:[\s\S]*SingleCandidate \|[\s\S]*ProvenMultiCandidate' "$runtime_contract"
rg -q '初期releaseはProfileが`ProvenMultiCandidate`でもcardinality 1だけ' "$runtime_contract"
rg -F -q 'slot identityは`Hash(owner_context_id, capability_ref, mode, adapter_class)`で決定論的に導出' "$runtime_contract"
rg -q '該当Capabilityのruntime ownerだけがslot mapとrevisionを所有' "$runtime_contract"
rg -q 'そのCapability StateのContextだけがslotの不在確認、初期生成、revision更新、終端を所有' docs/system-design/00-design-authority.md
rg -q 'release seedまたは認証済みLinux管理者CLIがRCP Profileを登録してもslotを先行生成せず' "$runtime_contract"
rg -q 'compare-not-exists CASで`slot_revision = 0`のHeld slotを原子生成' "$runtime_contract"
rg -q 'Capability ownerの全BindingGeneration map、exact `CapabilityCandidateSlotKey`のlookup結果' "$runtime_contract"
rg -q 'typed `CandidateSlotBusy`' "$runtime_contract"
rg -q 'typed `CandidateSlotQuarantined`' "$runtime_contract"
rg -q '明示Owner recovery/replacement Policyなしに後続candidateを許可しません' "$runtime_contract"
rg -q 'lookup結果`Absent | Present(record)`' "$runtime_contract"
rg -q '`AuthorizeSingleCandidateSlotCreationAndAdmission`' "$runtime_contract"
rg -q 'profile missing/Superseded/stale/Blockedは`ProfileNotReady`' "$runtime_contract"
rg -q 'profileとslot keyのcapability/mode/adapter class不一致は`ProfileKeyMismatch`' "$runtime_contract"
rg -q 'runtime ownerの全BindingGeneration map、exact slot keyの`compare-not-exists | existing slot revision`' "$runtime_contract"
rg -q '許可Decisionの場合だけ.*SD-PER-RCP-001.*BindingChange Graph' "$runtime_contract"
rg -q 'CandidateSlotBusy.*CandidateSlotQuarantined.*CandidateSlotStateConflict' "$runtime_contract"
rg -q 'generationだけ、slot Heldだけ、RCP useだけ、Graphだけ、NamedInterval leaseだけ' "$runtime_contract"
rg -q 'exact slot keyの`compare-not-exists | existing slot revision`' "$runtime_contract"
rg -q 'candidate admission resultの同値replayを最初に解決' "$runtime_contract"
rg -q 'slot mapにkeyが存在しないことをcompare-not-exists CAS' "$runtime_contract"
rg -q '決定論的slot identity、`slot_revision = 0`、lifecycle Held' "$runtime_contract"
rg -q 'profile missing/Superseded/stale/Blocked、profile key mismatch、RCP current mapping競合ではAbsent slotを生成しません' "$runtime_contract"
rg -q '同じAbsent slotへの異なる並行admission.*一方だけがslot revision 0を生成' "$runtime_contract"
rg -q 'profile supersedeとadmissionはRCP owner revision/current mappingのCASで一方だけが勝ち' "$runtime_contract"
rg -q 'Quarantined entryをAbsentとしてslot生成Decisionへ進めません' "$runtime_contract"
rg -q 'M/P/Kのnormal dispatch.*同じNamedInterval lease' "$runtime_contract"
rg -q 'Q/Rは同leaseとgeneration leaseを同じRecovery custody' "$runtime_contract"
rg -q 'slot holder終端とadmissionはruntime owner/slot/RCP/EXE revisionをCASし、一方だけが勝ちます' "$runtime_contract"
rg -U -q 'ResourceClaim =[\s\S]*ContinueNamedIntervalLeaseClaim \{[\s\S]*existing_lease_id: ResourceLeaseId,[\s\S]*named_interval_ref:[\s\S]*holder_ref:' "$execution_contract"
rg -q '同じholderの継続claimは既存leaseを再利用' "$execution_contract"
rg -q '通常generation leaseだけ、またはNamedInterval leaseだけを残しません' "$execution_contract"
rg -q 'candidate slot `Held → Free`とNamedInterval slot lease release' "$configuration_contract"
rg -q 'candidate slot `Held → Free`' "$runtime_contract"
rg -q 'candidate slotをHeld、cleanup custodyをActive' "$runtime_contract"
rg -q 'candidate/custody/generation lease/slot lease/slotをQuarantined' "$runtime_contract"
rg -q 'G1がStagedReadyまたはRejectingCleanup Planned/InFlight/Recovery' docs/system-design/slices/03-configuration-capability.md
rg -q 'G1がsafe RejectedとなりRCP use/NamedInterval slot lease解放済み' docs/system-design/slices/03-configuration-capability.md
rg -q 'G1 cleanup RecoveryがStillUnknownでQuarantined' docs/system-design/slices/03-configuration-capability.md
rg -q 'G1 cleanup terminalとG2 admissionが同時にslot CAS' docs/system-design/slices/03-configuration-capability.md
rg -q '将来はversion付きcardinality/resource-isolation proof' docs/system-design/slices/03-configuration-capability.md
rg -q 'release seed適用後、valid current Passing Profileのslot keyが未登録でfirst admission' docs/system-design/slices/03-configuration-capability.md
rg -q '認証済みLinux管理者CLIが新しいkeyのProfileを登録・Passing昇格後にfirst admission' docs/system-design/slices/03-configuration-capability.md
rg -q '異なるadmission identityが同じAbsent slotへ同時到着' docs/system-design/slices/03-configuration-capability.md
rg -q 'Absent branch成功後に同じadmission identity/payloadを再送' docs/system-design/slices/03-configuration-capability.md
rg -q 'profile supersedeとAbsent slot first admissionが競合' docs/system-design/slices/03-configuration-capability.md
rg -q 'Quarantined slot entryが存在するkeyへadmission' docs/system-design/slices/03-configuration-capability.md

# Thread resetはprior terminal recordをMapに保持し、fresh barrier追加とcurrent ref
# 更新を原子commitする。late resultはexact barrier以外へ適用しない。
rg -U -q 'AgentSessionState \{[\s\S]*reset_barriers: Map<ResetBarrierId, ThreadResetBarrier>,[\s\S]*current_reset_barrier_ref: None \| ResetBarrierId' "$conversation_contract"
if rg -U -q 'AgentSessionState \{[\s\S]*reset_barrier\?' "$conversation_contract"; then
  echo 'single optional Thread reset barrier found' >&2
  exit 1
fi
rg -q 'prior barrier map entryをterminalのまま保持' "$conversation_contract"
rg -q 'fresh barrierを別entryのPreparing' "$conversation_contract"
rg -q 'late resultはexact prior IDへ隔離' "$conversation_contract"
rg -q 'prior map entryを保持しfresh barrierを追加' docs/system-design/slices/02-finite-conversation.md

# Migrationのstage/plan mutationは通常/RecoveryともMIG-004一本であり、
# MIG-001/003はledger記録に限定する。
rg -q '^### SD-TRN-MIG-001 — RecordMigrationOperationResult$' "$migration_contract"
rg -q '^### SD-TRN-MIG-003 — RecordMigrationRecoveryResolution$' "$migration_contract"
rg -q 'stage/step lifecycle.*変更できるのは`SD-TRN-MIG-004`だけ' "$migration_contract"
awk '/^### SD-TRN-MIG-001 /,/^### SD-TRN-MIG-002 /' "$migration_contract" > "$check_tmp/mig-normal-record-transition"
awk '/^### SD-TRN-MIG-003 /,/^### SD-TRN-MIG-004 /' "$migration_contract" > "$check_tmp/mig-recovery-record-transition"
rg -q 'stage/step lifecycle.*一切変更しません' "$check_tmp/mig-normal-record-transition"
rg -q 'stage/step lifecycle.*一切変更しません' "$check_tmp/mig-recovery-record-transition"
rg -q 'operation result ledgerだけを記録' "$migration_contract"
rg -q 'Recovery resolution ledgerだけを記録' "$migration_contract"
test "$(rg -c '正確に一回適用' "$migration_contract")" -ge 2
rg -q '`004`の二回適用を構築できません' "$migration_contract"
rg -q 'MIG001/003でstage mutation' docs/system-design/slices/03-configuration-capability.md
rg -q '^### SD-TRN-MIG-005 — RegisterMigrationRecoveryBranch$' "$migration_contract"
awk '/^### SD-TRN-MIG-005 /,/^### SD-EVT-MIG-001 /' "$migration_contract" > "$check_tmp/mig-branch-transition"
rg -q 'stage/step record.*変更しません' "$check_tmp/mig-branch-transition"

# Migration Recovery branchは(stage,custody,generation)ごとに決定論的に一回
# 登録し、別stageのRecoveryを独立に扱う。
rg -U -q 'MigrationRecoveryBranchKey \{[\s\S]*plan_id, stage_ref, custody_id,[\s\S]*recovery_generation: MigrationRecoveryGeneration' "$migration_contract"
rg -q 'recovery_branch\(key: MigrationRecoveryBranchKey\)' "$migration_contract"
rg -q '^### SD-RUL-MIG-004 — PlanMigrationRecoveryBranchRegistration$' "$migration_contract"
rg -q '^### SD-EVT-MIG-005 — MigrationRecoveryBranchRegistered$' "$migration_contract"
rg -q '^### SD-PER-MIG-004 — MigrationRecoveryBranchRegistrationUoW$' "$migration_contract"
rg -q '同じoriginal occurrence/attempt/stageのduplicateは同じkey' "$migration_contract"
rg -q '別stageはそのstage固有generation' "$migration_contract"
rg -q 'S1 Recovery終端後にS2がOutcomeUnknown' docs/system-design/slices/03-configuration-capability.md
rg -q 'S2の同OutcomeUnknownをduplicate取込' docs/system-design/slices/03-configuration-capability.md

# accepted Pilot inputは固定したPilot canonical集合と一致し、横展開で追加した
# canonical定義はaccepted／review-pendingを問わず一つ以上のreview inputへ登録する。
pilot_change_set='docs/system-design/verification/change-sets/SD-REV-PILOT-C-001.md'
pilot_design_ids='docs/system-design/verification/approvals/SD-REV-PILOT-C-001-design-ids.txt'
rg -o --no-filename '^- SD-[A-Z]+-[A-Z]+-[0-9]+' "$pilot_change_set" \
  | sed -E 's/^- //' | sort -u > "$check_tmp/pilot-change-set-design-ids"
diff -u "$pilot_design_ids" "$check_tmp/pilot-change-set-design-ids"

for review_ids in docs/system-design/verification/approvals/*-design-ids.txt; do
  sort -u "$review_ids"
done | sort -u > "$check_tmp/review-input-design-ids"
comm -23 "$check_tmp/review-input-design-ids" "$check_tmp/canonical-unique" \
  > "$check_tmp/unknown-review-input-design-ids"
test ! -s "$check_tmp/unknown-review-input-design-ids"
comm -23 "$check_tmp/canonical-unique" "$check_tmp/review-input-design-ids" \
  > "$check_tmp/unregistered-canonical-design-ids"
test ! -s "$check_tmp/unregistered-canonical-design-ids"

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

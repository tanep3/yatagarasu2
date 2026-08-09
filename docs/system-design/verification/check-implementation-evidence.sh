#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"

docs/system-design/verification/check-system-design-fix.sh

scope=docs/system-design/verification/release-scope.md
scope_approval=docs/system-design/verification/release-scope-approval.md
manifest=docs/system-design/verification/release-manifest.md
manifest_approval=docs/system-design/verification/release-approval.md

field_value() {
  local file="$1" field="$2"
  awk -F '|' -v field="$field" '
    /^\|/ {
      for (i = 2; i <= NF - 1; i++) gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i)
      if ($2 == field) print $3
    }
  ' "$file"
}

for file in "$scope" "$scope_approval" "$manifest" "$manifest_approval"; do
  if rg -q '`unfixed`|`draft-not-runnable`|`pending`' "$file"; then
    echo "release Gate artifact is not fixed: $file" >&2
    exit 1
  fi
done

# Gateはversion管理済みの同一treeだけを評価する。repo全体のstaged/unstaged/untrackedを拒否する。
test -z "$(git status --porcelain --untracked-files=all)"
for file in "$scope" "$scope_approval" "$manifest" "$manifest_approval"; do
  git ls-files --error-unmatch "$file" >/dev/null
done

design_revision="$(docs/system-design/verification/system-design-revision.sh)"
verification_revision="$(docs/system-design/verification/verification-revision.sh)"
requirements_revision="$(field_value "$scope" 'Requirements revision')"
git rev-parse --verify "${requirements_revision}^{commit}" >/dev/null
release_source_revision="$(docs/system-design/verification/release-source-revision.sh)"

scope_version="$(field_value "$scope" 'Scope version')"
target_release="$(field_value "$scope" 'Target release')"
scope_sha="sha256:$(sha256sum "$scope" | awk '{print $1}')"
test "$(field_value "$scope" 'System design revision')" = "$design_revision"
test "$(field_value "$scope" 'Verification revision')" = "$verification_revision"
test "$(field_value "$scope" 'Release source revision')" = "$release_source_revision"
test "$(field_value "$scope" 'Status')" = "fixed"

test "$(field_value "$scope_approval" 'Artifact type')" = "release-scope-approval"
test "$(field_value "$scope_approval" 'Scope version')" = "$scope_version"
test "$(field_value "$scope_approval" 'Target release')" = "$target_release"
test "$(field_value "$scope_approval" 'Scope SHA-256')" = "$scope_sha"
test "$(field_value "$scope_approval" 'Requirements revision')" = "$requirements_revision"
test "$(field_value "$scope_approval" 'System design revision')" = "$design_revision"
test "$(field_value "$scope_approval" 'Verification revision')" = "$verification_revision"
test "$(field_value "$scope_approval" 'Release source revision')" = "$release_source_revision"
test "$(field_value "$scope_approval" 'Owner approval')" = "accepted"

# Scope承認をcommitした後にEvidenceを取得したことを検査する。
git diff --quiet -- "$scope" "$scope_approval"
scope_approval_commit="$(git log -1 --format=%H -- "$scope_approval")"
test -n "$scope_approval_commit"
git merge-base --is-ancestor "$scope_approval_commit" HEAD
git diff --quiet "$scope_approval_commit" -- "$scope" "$scope_approval"
test "$(field_value "$scope_approval" 'System design revision')" = \
  "$(docs/system-design/verification/system-design-revision.sh "$scope_approval_commit")"
test "$(field_value "$scope_approval" 'Verification revision')" = \
  "$(docs/system-design/verification/verification-revision.sh "$scope_approval_commit")"
test "$(field_value "$scope_approval" 'Release source revision')" = \
  "$(docs/system-design/verification/release-source-revision.sh "$scope_approval_commit")"

test "$(field_value "$manifest" 'Scope version')" = "$scope_version"
test "$(field_value "$manifest" 'Scope SHA-256')" = "$scope_sha"
test "$(field_value "$manifest" 'Target release')" = "$target_release"
test "$(field_value "$manifest" 'Requirements revision')" = "$requirements_revision"
test "$(field_value "$manifest" 'System design revision')" = "$design_revision"
test "$(field_value "$manifest" 'Verification revision')" = "$verification_revision"
test "$(field_value "$manifest" 'Release source revision')" = "$release_source_revision"
test "$(field_value "$manifest" 'Status')" = "fixed"

manifest_sha="sha256:$(sha256sum "$manifest" | awk '{print $1}')"
test "$(field_value "$manifest_approval" 'Artifact type')" = "release-manifest-approval"
test "$(field_value "$manifest_approval" 'Manifest version')" = "$(field_value "$manifest" 'Manifest version')"
test "$(field_value "$manifest_approval" 'Target release')" = "$target_release"
test "$(field_value "$manifest_approval" 'Scope version')" = "$scope_version"
test "$(field_value "$manifest_approval" 'Scope SHA-256')" = "$scope_sha"
test "$(field_value "$manifest_approval" 'Manifest SHA-256')" = "$manifest_sha"
test "$(field_value "$manifest_approval" 'Requirements revision')" = "$requirements_revision"
test "$(field_value "$manifest_approval" 'System design revision')" = "$design_revision"
test "$(field_value "$manifest_approval" 'Verification revision')" = "$verification_revision"
test "$(field_value "$manifest_approval" 'Release source revision')" = "$release_source_revision"
test "$(field_value "$manifest_approval" 'Owner approval')" = "accepted"

check_tmp="$(mktemp -d)"
trap 'rm -r "$check_tmp"' EXIT

awk -F '|' '/^\| DO-/ { for(i=2;i<=12;i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i); print $2 "\t" $3 }' \
  docs/system-design/slices/*.md | sort > "$check_tmp/all-obligation-parent"
awk -F '|' '/^\| DO-/ { for(i=2;i<=12;i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i); print $2 "\t" $6 "\t" $7 }' \
  docs/system-design/slices/*.md | sort > "$check_tmp/obligation-proof-contracts"

awk -F '|' '/^\| DO-/ { for(i=2;i<=10;i++) gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i); print $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $10 }' \
  "$scope" | sort > "$check_tmp/scope-rows"
cut -f1-2 "$check_tmp/scope-rows" > "$check_tmp/scope-obligation-parent"
diff -u "$check_tmp/all-obligation-parent" "$check_tmp/scope-obligation-parent"

awk -F '|' '/^\| DO-/ { for(i=2;i<=9;i++) gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $i); print $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 }' \
  "$manifest" | sort > "$check_tmp/manifest-rows"
cut -f1-3,8-9 "$check_tmp/scope-rows" > "$check_tmp/scope-binding"
cut -f1-5 "$check_tmp/manifest-rows" > "$check_tmp/manifest-binding"
diff -u "$check_tmp/scope-binding" "$check_tmp/manifest-binding"

while IFS=$'\t' read -r obligation parent disposition decision_ref decision_sha approval_ref approval_sha profiles provider_agent; do
  case "$disposition" in
    required)
      test "$decision_ref" = "—"; test "$decision_sha" = "—"
      test "$approval_ref" = "—"; test "$approval_sha" = "—"
      ;;
    excluded-by-owner)
      case "$decision_ref" in docs/system-design/verification/scope-decisions/*) ;; *) exit 1 ;; esac
      case "$approval_ref" in docs/system-design/verification/scope-approvals/*) ;; *) exit 1 ;; esac
      test -f "$decision_ref"; test -f "$approval_ref"
      test "$decision_sha" = "sha256:$(sha256sum "$decision_ref" | awk '{print $1}')"
      test "$approval_sha" = "sha256:$(sha256sum "$approval_ref" | awk '{print $1}')"
      for f in "$decision_ref" "$approval_ref"; do
        test "$(field_value "$f" 'Obligation ID')" = "$obligation"
        test "$(field_value "$f" 'Parent AC')" = "$parent"
        test "$(field_value "$f" 'Disposition')" = "$disposition"
        test "$(field_value "$f" 'System design revision')" = "$design_revision"
        test "$(field_value "$f" 'Requirements revision')" = "$requirements_revision"
      done
      test "$(field_value "$approval_ref" 'Artifact type')" = "scope-approval"
      test "$(field_value "$approval_ref" 'Scope Decision Ref')" = "$decision_ref"
      test "$(field_value "$approval_ref" 'Decision SHA-256')" = "$decision_sha"
      test "$(field_value "$approval_ref" 'Owner approval')" = "accepted"
      ;;
    deferred-by-requirement) echo 'deferred-by-requirement is not machine-authorized by current requirements' >&2; exit 1 ;;
    *) exit 1 ;;
  esac
  test -n "$profiles"; test "$profiles" != "—"
  test -n "$provider_agent"; test "$provider_agent" != "—"
done < "$check_tmp/scope-rows"

while IFS=$'\t' read -r obligation parent disposition profiles provider_agent evidence_ref evidence_sha proof; do
  if test "$disposition" = required; then
    test "$proof" = passing
    case "$evidence_ref" in docs/system-design/verification/evidence/*) ;; *) exit 1 ;; esac
    test -f "$evidence_ref"
    test "$evidence_sha" = "sha256:$(sha256sum "$evidence_ref" | awk '{print $1}')"
    test "$(field_value "$evidence_ref" 'Artifact type')" = implementation-evidence
    test "$(field_value "$evidence_ref" 'Obligation ID')" = "$obligation"
    test "$(field_value "$evidence_ref" 'Parent AC')" = "$parent"
    test "$(field_value "$evidence_ref" 'System design revision')" = "$design_revision"
    test "$(field_value "$evidence_ref" 'Release source revision')" = "$release_source_revision"
    expected_design_ids="$(awk -F '\t' -v id="$obligation" '$1 == id {print $2}' "$check_tmp/obligation-proof-contracts")"
    expected_proof_type="$(awk -F '\t' -v id="$obligation" '$1 == id {print $3}' "$check_tmp/obligation-proof-contracts")"
    test "$(field_value "$evidence_ref" 'Canonical Design IDs')" = "$expected_design_ids"
    test "$(field_value "$evidence_ref" 'Proof type')" = "$expected_proof_type"
    test "$(field_value "$evidence_ref" 'Profiles')" = "$profiles"
    test "$(field_value "$evidence_ref" 'Providers / Agent')" = "$provider_agent"
    test "$(field_value "$evidence_ref" 'Result')" = passing
    execution_procedure="$(field_value "$evidence_ref" 'Execution command / procedure')"
    hardware="$(field_value "$evidence_ref" 'Hardware')"
    config_snapshot="$(field_value "$evidence_ref" 'Configuration snapshot')"
    result_summary="$(field_value "$evidence_ref" 'Result summary')"
    for value in "$execution_procedure" "$hardware" "$config_snapshot" "$result_summary"; do
      test -n "$value"; test "$value" != "—"
    done
    execution_revision="$(field_value "$evidence_ref" 'Execution revision')"
    git rev-parse --verify "${execution_revision}^{commit}" >/dev/null
    git merge-base --is-ancestor "$scope_approval_commit" "$execution_revision"
    git merge-base --is-ancestor "$execution_revision" HEAD
    test "$(docs/system-design/verification/release-source-revision.sh "$execution_revision")" = "$release_source_revision"
    test "$(docs/system-design/verification/verification-revision.sh "$execution_revision")" = "$verification_revision"
    test "$(field_value "$evidence_ref" 'Verification revision')" = "$verification_revision"

    IFS='/' read -r -a proof_types <<< "$expected_proof_type"
    for proof_type in "${proof_types[@]}"; do
      artifact_ref="$(field_value "$evidence_ref" "Proof ${proof_type} Artifact")"
      artifact_sha="$(field_value "$evidence_ref" "Proof ${proof_type} SHA-256")"
      case "$artifact_ref" in docs/system-design/verification/evidence/artifacts/*) ;; *) exit 1 ;; esac
      test -f "$artifact_ref"; test -s "$artifact_ref"
      test "$artifact_sha" = "sha256:$(sha256sum "$artifact_ref" | awk '{print $1}')"
      case "$proof_type" in
        pure)
          expected_type=pure-result; required_fields='Test cases|Negative cases' ;;
        architecture)
          expected_type=architecture-result; required_fields='Inspected boundaries|Violations|Execution command / procedure' ;;
        contract)
          expected_type=contract-result; required_fields='Contract cases|Failure cases|OutcomeUnknown cases' ;;
        integration)
          expected_type=integration-result; required_fields='Components|Scenario|Failure cases' ;;
        concurrency)
          expected_type=concurrency-result; required_fields='Interleavings|Winner rules|Race results' ;;
        crash-recovery)
          expected_type=crash-recovery-result; required_fields='Crash windows|Recovery outcomes|Duplicate / late results' ;;
        projection)
          expected_type=projection-result; required_fields='Source revisions|Resync cases|Leakage cases' ;;
        real-device)
          expected_type=real-device-result; required_fields='Device profile|Test procedure|Observed result|Failure cases|Missing observations' ;;
        measurement)
          expected_type=measurement-result; required_fields='Hardware|Configuration snapshot|Sample count|Metrics|Missing samples' ;;
        spike)
          expected_type=spike-result; required_fields='Hypothesis|Candidates|Observed result|Decision' ;;
        owner-gate)
          expected_type=owner-gate-result; required_fields='Owner decision|Decision basis|Approval reference' ;;
        *) exit 1 ;;
      esac
      test "$(field_value "$artifact_ref" 'Artifact type')" = "$expected_type"
      test "$(field_value "$artifact_ref" 'Obligation ID')" = "$obligation"
      test "$(field_value "$artifact_ref" 'Parent AC')" = "$parent"
      test "$(field_value "$artifact_ref" 'Release source revision')" = "$release_source_revision"
      test "$(field_value "$artifact_ref" 'Verification revision')" = "$verification_revision"
      test "$(field_value "$artifact_ref" 'Execution revision')" = "$execution_revision"
      test "$(field_value "$artifact_ref" 'Profiles')" = "$profiles"
      test "$(field_value "$artifact_ref" 'Providers / Agent')" = "$provider_agent"
      test "$(field_value "$artifact_ref" 'Execution command / procedure')" = "$execution_procedure"
      IFS='|' read -r -a fields <<< "$required_fields"
      for field in "${fields[@]}"; do
        value="$(field_value "$artifact_ref" "$field")"; test -n "$value"; test "$value" != "—"
      done
      if test "$proof_type" = measurement; then
        test "$(field_value "$artifact_ref" 'Sample count')" -gt 0
        test "$(field_value "$artifact_ref" 'Hardware')" = "$hardware"
        test "$(field_value "$artifact_ref" 'Configuration snapshot')" = "$config_snapshot"
      elif test "$proof_type" = real-device; then
        test "$(field_value "$artifact_ref" 'Device profile')" = "$profiles"
        test "$(field_value "$artifact_ref" 'Test procedure')" = "$execution_procedure"
      fi
    done
  else
    test "$proof" = not-applicable
    test "$evidence_ref" = "—"; test "$evidence_sha" = "—"
  fi
done < "$check_tmp/manifest-rows"

printf 'PASS(implementation-evidence-gate) revision=%s scope=%s\n' "$design_revision" "$scope_sha"

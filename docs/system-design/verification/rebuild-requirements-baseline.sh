#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"

baseline_revision="${1:-4df6fb1}"
check_tmp="$(mktemp -d)"
trap 'rm -r "$check_tmp"' EXIT

printf 'Requirement\tAC\tSource locator\tRequirement title\tAC text\tRequirement SHA-256\tAC SHA-256\n'

git ls-tree -r --name-only "$baseline_revision" -- docs/requirements \
  | sort \
  | while IFS= read -r source_path; do
      git show "$baseline_revision:$source_path" > "$check_tmp/source"
      awk -v req_index="$check_tmp/requirements" -v ac_index="$check_tmp/acs" '
        function close_ac(end_line) {
          if (ac != "") print req "\t" ac "\t" ac_start "\t" end_line >> ac_index
          ac=""
        }
        function close_req(end_line) {
          close_ac(end_line)
          if (req != "") print req "\t" req_start "\t" end_line "\t" req_title >> req_index
          req=""
        }
        /^##+ REQ-[A-Z0-9-]+/ {
          close_req(NR - 1)
          req=$2
          req_start=NR
          req_title=$0
          next
        }
        req != "" && /^- AC-[A-Z0-9-]+:/ {
          close_ac(NR - 1)
          ac=$2
          sub(/:$/, "", ac)
          ac_start=NR
          next
        }
        req != "" && /^##+ / { close_req(NR - 1) }
        END { close_req(NR) }
      ' "$check_tmp/source"

      if ! test -s "$check_tmp/acs"; then
        rm -f "$check_tmp/requirements" "$check_tmp/acs"
        continue
      fi

      while IFS=$'\t' read -r requirement start_line end_line requirement_title; do
        sed -n "${start_line},${end_line}p" "$check_tmp/source" > "$check_tmp/requirement-block"
        requirement_sha="sha256:$(sha256sum "$check_tmp/requirement-block" | awk '{print $1}')"
        printf '%s\t%s\t%s\n' "$requirement" "$requirement_sha" "$requirement_title" >> "$check_tmp/requirement-hashes"
      done < "$check_tmp/requirements"

      source_name="${source_path#docs/requirements/}"
      while IFS=$'\t' read -r requirement ac start_line end_line; do
        requirement_sha="$(awk -F '\t' -v req="$requirement" '$1 == req { print $2 }' "$check_tmp/requirement-hashes")"
        requirement_title="$(awk -F '\t' -v req="$requirement" '$1 == req { print $3 }' "$check_tmp/requirement-hashes")"
        test -n "$requirement_sha"
        sed -n "${start_line},${end_line}p" "$check_tmp/source" > "$check_tmp/ac-block"
        ac_sha="sha256:$(sha256sum "$check_tmp/ac-block" | awk '{print $1}')"
        ac_text="$(sed -n "${start_line}p" "$check_tmp/source")"
        printf '%s\t%s\t%s:%s:%s\t%s\t%s\t%s\t%s\n' \
          "$requirement" "$ac" "$baseline_revision" "$source_name" "$start_line" \
          "$requirement_title" "$ac_text" "$requirement_sha" "$ac_sha"
      done < "$check_tmp/acs"

      rm -f "$check_tmp/requirements" "$check_tmp/acs" "$check_tmp/requirement-hashes"
    done

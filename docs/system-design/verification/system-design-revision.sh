#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"

# 承認、release scope、Evidenceを設計payloadへ含めると自己参照になるため、
# canonical design本体だけをhashする。pathと内容の双方を入力にする。
if test "$#" -eq 0; then
  find \
    docs/system-design/00-design-authority.md \
    docs/system-design/README.md \
    docs/system-design/contracts \
    docs/system-design/slices \
    -type f -print0 \
    | sort -z | xargs -0 sha256sum | sha256sum \
    | awk '{ print "sha256:" $1 }'
else
  revision="$1"
  git ls-tree -r --name-only "$revision" -- \
    docs/system-design/00-design-authority.md \
    docs/system-design/README.md \
    docs/system-design/contracts \
    docs/system-design/slices \
    | sort \
    | while IFS= read -r path; do
        digest="$(git show "${revision}:${path}" | sha256sum | awk '{print $1}')"
        printf '%s  %s\n' "$digest" "$path"
      done \
    | sha256sum | awk '{ print "sha256:" $1 }'
fi

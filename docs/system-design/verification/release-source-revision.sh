#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"

# Evidence/approvalを除くtracked tree entryをhashする。mode、object type、OID、pathを含むため、
# executable bit、symlink、gitlinkの変更も別revisionになる。Gateはclean treeでだけ実行する。
revision="${1:-HEAD}"
git ls-tree -r "$revision" \
  | rg -v $'\tdocs/system-design/verification/' \
  | sort \
  | sha256sum \
  | awk '{print "sha256:" $1}'

#!/usr/bin/env bash
# Copies the canonical fixture.sh into every case directory.
#
# `context.scaffold_script` must name a file inside the case directory - a path with
# `..` is rejected at run time - so each of the cases carries its own copy. Run this
# after editing the canonical copy, and after adding a case.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
n=0
while IFS= read -r case_dir; do
  cp "$root/_fixture/fixture.sh" "$case_dir/fixture.sh"
  chmod +x "$case_dir/fixture.sh"
  n=$((n + 1))
done < <(find "$root" -mindepth 2 -maxdepth 3 \( -name prompt.md -o -name case.yaml \) \
           -not -path "$root/_fixture/*" -exec dirname {} \; | sort -u)
echo "synced fixture.sh into $n case(s)"

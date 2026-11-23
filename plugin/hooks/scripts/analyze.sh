#!/bin/bash
set -euo pipefail

# Read the hook payload from stdin
input=$(cat)

# Check jq availability
if ! command -v jq &>/dev/null; then
  echo "analyze hook: jq not found, skipping" >&2
  exit 0
fi

# Extract file path from the tool input
file_path=$(jq -r '.tool_input.file_path // empty' <<< "$input")

# Skip if no file path or not a Dart file
if [[ -z "$file_path" || "$file_path" != *.dart ]]; then
  exit 0
fi

# Prints the directory of the package that holds $1 when its dependencies are not
# resolved, and fails otherwise. The package is the nearest directory with a
# pubspec.yaml; it is resolved when it has its own .dart_tool/package_config.json,
# or, for a pub workspace member (resolution: workspace), when a directory above it
# does, which is where the workspace root keeps it. A file with no pubspec.yaml above
# it is not in a package, and pub get cannot help it.
unresolved_package_dir() {
  local dir package_dir
  dir=$(CDPATH='' cd -- "$(dirname -- "$1")" 2>/dev/null && pwd) || return 1
  while [[ ! -f "$dir/pubspec.yaml" ]]; do
    [[ "$dir" == "/" ]] && return 1
    dir=$(dirname -- "$dir")
  done
  package_dir="$dir"
  [[ -f "$package_dir/.dart_tool/package_config.json" ]] && return 1
  if grep -Eq '^resolution:[[:space:]]*["'\'']?workspace' "$package_dir/pubspec.yaml"; then
    while [[ "$dir" != "/" ]]; do
      dir=$(dirname -- "$dir")
      [[ -f "$dir/.dart_tool/package_config.json" ]] && return 1
    done
  fi
  echo "$package_dir"
}

# Run dart analyze on the single file
output=$(dart analyze "$file_path" 2>&1) || {
  # Without resolved dependencies every package: import fails with
  # uri_does_not_exist, and the errors that follow from those imports are just as
  # misleading, so the whole output is replaced. Failures with no such error pass
  # through, since pub get would not fix them.
  if [[ "$output" == *uri_does_not_exist* ]] && package_dir=$(unresolved_package_dir "$file_path"); then
    pub="dart"
    grep -Eq '^[^#]*sdk:[[:space:]]*["'\'']?flutter' "$package_dir/pubspec.yaml" && pub="flutter"
    echo "analyze hook: dependencies are not resolved for the package at $package_dir (no .dart_tool/package_config.json)." >&2
    echo "Run \`$pub pub get\` in that directory, then run \`dart analyze\` on $file_path to check it." >&2
    exit 2
  fi
  echo "$output" >&2
  exit 2
}

#!/bin/bash
# Tests for analyze.sh
#
# Usage: bash hooks/scripts/analyze_test.sh
#
# The hook reads a JSON payload from stdin, runs `dart analyze` on the edited file, and
# exits 2 with feedback on stderr when analysis fails. Every case runs against a stubbed
# dart on a PATH holding only that stub, jq and a few core tools, so results do not
# depend on the Dart SDK or on whether it is installed. Each case builds its own
# packages in a temporary directory, so it controls whether pubspec.yaml and
# .dart_tool/package_config.json exist.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/analyze.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to run these tests" >&2
  exit 1
fi

PASSED=0
FAILED=0

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
# Resolve symlinks (macOS /var -> /private/var) so expected paths match what the hook
# prints after its own `cd` and `pwd`.
WORK_DIR="$(cd "$WORK_DIR" && pwd -P)"

# The package walk climbs to /, so a stray pubspec.yaml or .dart_tool above the
# temporary directory would change what the cases test. Say so outright.
ancestor="$WORK_DIR"
while [ "$ancestor" != "/" ]; do
  ancestor=$(dirname "$ancestor")
  if [ -e "$ancestor/pubspec.yaml" ] || [ -e "$ancestor/.dart_tool/package_config.json" ]; then
    echo "$ancestor holds a pubspec.yaml or .dart_tool; the cases cannot run under it" >&2
    exit 1
  fi
done

# The hook runs on a PATH built from symlinks to the few tools it needs, so a test
# machine's own dart (or anything beside it) can never stand in for the stub, and
# leaving jq or dart out of that PATH really does make it missing.
mkdir -p "$WORK_DIR/sys-bin" "$WORK_DIR/jq-bin" "$WORK_DIR/dart-bin"
for tool in bash sh cat dirname grep; do
  ln -s "$(command -v "$tool")" "$WORK_DIR/sys-bin/$tool"
done
ln -s "$(command -v jq)" "$WORK_DIR/jq-bin/jq"
BASE_PATH="$WORK_DIR/sys-bin"
FULL_PATH="$WORK_DIR/dart-bin:$WORK_DIR/jq-bin:$BASE_PATH"

URI_ERROR="uri_does_not_exist"
TYPE_ERROR="return_of_invalid_type"

# Install a stubbed dart that records its arguments in dart-calls.
#   pass        exits 0 with no issues
#   uri-error   prints the error the real analyzer gives for an unresolved dependency
#   type-error  prints an error unrelated to dependencies
# The failing modes exit 3, as `dart analyze` does when it finds errors.
stub_dart() {
  local message="" status=0
  case "$1" in
    pass) message="No issues found!" ;;
    uri-error) message="error - a.dart:1:8 - Target of URI doesn't exist. - $URI_ERROR"; status=3 ;;
    type-error) message="error - a.dart:1:12 - A value of type String cannot be returned. - $TYPE_ERROR"; status=3 ;;
  esac
  printf '#!/bin/sh\necho "$@" >> "%s/dart-calls"\necho "%s"\nexit %s\n' \
    "$WORK_DIR" "$message" "$status" > "$WORK_DIR/dart-bin/dart"
  chmod +x "$WORK_DIR/dart-bin/dart"
}

# Create a package directory holding a pubspec.yaml and lib/a.dart.
# Usage: make_package <dir> <kind>
make_package() {
  local dir="$1" kind="$2"
  mkdir -p "$dir/lib"
  case "$kind" in
    dart)
      printf 'name: pkg\nenvironment:\n  sdk: ^3.6.0\ndependencies:\n  path: ^1.9.0\n' ;;
    # Mentions flutter in a name, a comment and a dependency, none of them an SDK dependency.
    dart-lookalike)
      printf 'name: flutter_tools_helper\n# sdk: flutter is not used here\nenvironment:\n  sdk: ^3.6.0\ndev_dependencies:\n  flutter_lints: ^4.0.0\n' ;;
    flutter)
      printf 'name: app\nenvironment:\n  sdk: ^3.6.0\ndependencies:\n  flutter:\n    sdk: flutter\n' ;;
    flutter-quoted)
      printf 'name: app\nenvironment:\n  sdk: ^3.6.0\ndependencies:\n  flutter:\n    sdk: "flutter"\n' ;;
    flutter-flow)
      printf 'name: app\nenvironment:\n  sdk: ^3.6.0\ndependencies:\n  flutter: {sdk: flutter}\n' ;;
    flutter-dev-only)
      printf 'name: pkg\nenvironment:\n  sdk: ^3.6.0\ndev_dependencies:\n  flutter_test:\n    sdk: flutter\n' ;;
    workspace-member)
      printf 'name: member\nenvironment:\n  sdk: ^3.6.0\nresolution: workspace\ndependencies:\n  path: ^1.9.0\n' ;;
    workspace-root)
      printf 'name: _\nenvironment:\n  sdk: ^3.6.0\nworkspace:\n  - packages/member\n' ;;
  esac > "$dir/pubspec.yaml"
  printf "import 'package:path/path.dart';\n" > "$dir/lib/a.dart"
}

resolve() { mkdir -p "$1/.dart_tool" && echo '{"configVersion":2,"packages":[]}' > "$1/.dart_tool/package_config.json"; }

payload_for() { jq -cn --arg p "$1" '{tool_name:"Edit",tool_input:{file_path:$p}}'; }

# Runs the hook and stores its exit status and stderr in STATUS and STDERR.
# Usage: run_hook <payload> [PATH] [working directory]
# Set HOOK_CDPATH to run the hook with CDPATH exported.
run_hook() {
  local payload="$1" path="${2:-$FULL_PATH}" cwd="${3:-$WORK_DIR}"
  rm -f "$WORK_DIR/dart-calls"
  STATUS=0
  (cd "$cwd" && printf '%s' "$payload" \
    | env -i PATH="$path" HOME="$WORK_DIR" CDPATH="${HOOK_CDPATH:-}" bash "$HOOK" 2>"$WORK_DIR/stderr" >/dev/null) || STATUS=$?
  STDERR=$(cat "$WORK_DIR/stderr")
}

dart_ran() { [ -e "$WORK_DIR/dart-calls" ]; }
dart_ran_on() { grep -qxF "analyze $1" "$WORK_DIR/dart-calls" 2>/dev/null; }

pass() { printf "  \033[32mPASS\033[0m  %s\n" "$1"; PASSED=$((PASSED + 1)); }
fail() { printf "  \033[31mFAIL\033[0m  %s\n        %s\n" "$1" "$2"; FAILED=$((FAILED + 1)); }

# Checks the last run: exit status, then each check in order. A check is
# `has:<text>` or `lacks:<text>` against stderr.
# Usage: expect <label> <status> [has:<text>|lacks:<text>]...
expect() {
  local label="$1" expected="$2" check
  shift 2
  if [ "$STATUS" != "$expected" ]; then
    fail "$label" "expected exit $expected but got $STATUS; stderr: $STDERR"
    return
  fi
  for check in "$@"; do
    case "$check" in
      has:*)
        if [[ "$STDERR" != *"${check#has:}"* ]]; then
          fail "$label" "stderr lacks '${check#has:}': $STDERR"; return
        fi ;;
      lacks:*)
        if [[ "$STDERR" == *"${check#lacks:}"* ]]; then
          fail "$label" "stderr should not contain '${check#lacks:}': $STDERR"; return
        fi ;;
      *) fail "$label" "unknown check '$check'"; return ;;
    esac
  done
  pass "$label"
}

# The pub get message for a package directory, as the hook prints it.
names_package() { echo "has:package at $1 (no .dart_tool/package_config.json)"; }

echo "=== analyze tests ==="

echo ""
echo "--- Not this hook's business (exit 0, dart not run) ---"
stub_dart uri-error
make_package "$WORK_DIR/skip" dart
run_hook "$(payload_for "$WORK_DIR/skip/pubspec.yaml")"
if [ "$STATUS" = 0 ] && ! dart_ran; then pass "non-Dart file"; else fail "non-Dart file" "status $STATUS"; fi
run_hook '{"tool_name":"Edit","tool_input":{}}'
if [ "$STATUS" = 0 ] && ! dart_ran; then pass "no file_path"; else fail "no file_path" "status $STATUS"; fi
run_hook "$(payload_for "$WORK_DIR/skip/lib/a.dart")" "$WORK_DIR/dart-bin:$BASE_PATH"
if [ "$STATUS" = 0 ] && [[ "$STDERR" == *"jq not found"* ]] && ! dart_ran; then
  pass "jq missing skips"
else
  fail "jq missing skips" "status $STATUS; stderr: $STDERR"
fi

echo ""
echo "--- Analysis passes (exit 0, even without pub get) ---"
stub_dart pass
make_package "$WORK_DIR/clean" dart
run_hook "$(payload_for "$WORK_DIR/clean/lib/a.dart")"
expect "unresolved package, clean file is not blocked" 0
if dart_ran_on "$WORK_DIR/clean/lib/a.dart"; then pass "dart analyze ran on the file"; else fail "dart analyze ran on the file" "calls: $(cat "$WORK_DIR/dart-calls" 2>/dev/null)"; fi

echo ""
echo "--- Dependencies not resolved (exit 2, pub get message) ---"
stub_dart uri-error
make_package "$WORK_DIR/dart_pkg" dart
run_hook "$(payload_for "$WORK_DIR/dart_pkg/lib/a.dart")"
expect "Dart package without pub get" 2 \
  "has:not resolved" "$(names_package "$WORK_DIR/dart_pkg")" "has:\`dart pub get\`" \
  "has:\`dart analyze\` on $WORK_DIR/dart_pkg/lib/a.dart" "lacks:$URI_ERROR"

make_package "$WORK_DIR/lookalike" dart-lookalike
run_hook "$(payload_for "$WORK_DIR/lookalike/lib/a.dart")"
expect "flutter in names and comments still means dart pub get" 2 \
  "has:\`dart pub get\`" "lacks:flutter pub get"

make_package "$WORK_DIR/flutter_pkg" flutter
run_hook "$(payload_for "$WORK_DIR/flutter_pkg/lib/a.dart")"
expect "Flutter package asks for flutter pub get" 2 \
  "has:\`flutter pub get\`" "$(names_package "$WORK_DIR/flutter_pkg")" "lacks:$URI_ERROR"

make_package "$WORK_DIR/flutter_quoted" flutter-quoted
run_hook "$(payload_for "$WORK_DIR/flutter_quoted/lib/a.dart")"
expect "quoted sdk: \"flutter\"" 2 "has:\`flutter pub get\`"

make_package "$WORK_DIR/flutter_flow" flutter-flow
run_hook "$(payload_for "$WORK_DIR/flutter_flow/lib/a.dart")"
expect "flow-style flutter: {sdk: flutter}" 2 "has:\`flutter pub get\`"

make_package "$WORK_DIR/flutter_dev" flutter-dev-only
run_hook "$(payload_for "$WORK_DIR/flutter_dev/lib/a.dart")"
expect "Flutter SDK only in dev_dependencies" 2 "has:\`flutter pub get\`"

make_package "$WORK_DIR/deep_pkg" dart
mkdir -p "$WORK_DIR/deep_pkg/lib/src/deep"
cp "$WORK_DIR/deep_pkg/lib/a.dart" "$WORK_DIR/deep_pkg/lib/src/deep/b.dart"
run_hook "$(payload_for "$WORK_DIR/deep_pkg/lib/src/deep/b.dart")"
expect "nested file finds its package" 2 "$(names_package "$WORK_DIR/deep_pkg")" "lacks:$URI_ERROR"

make_package "$WORK_DIR/outer_pkg" dart
make_package "$WORK_DIR/outer_pkg/inner_pkg" dart
run_hook "$(payload_for "$WORK_DIR/outer_pkg/inner_pkg/lib/a.dart")"
expect "nearest pubspec.yaml names the package" 2 "$(names_package "$WORK_DIR/outer_pkg/inner_pkg")"

make_package "$WORK_DIR/with space/pkg" dart
run_hook "$(payload_for "$WORK_DIR/with space/pkg/lib/a.dart")"
expect "path with spaces" 2 "$(names_package "$WORK_DIR/with space/pkg")" "lacks:$URI_ERROR"

make_package "$WORK_DIR/ws_unresolved" workspace-root
make_package "$WORK_DIR/ws_unresolved/packages/member" workspace-member
run_hook "$(payload_for "$WORK_DIR/ws_unresolved/packages/member/lib/a.dart")"
expect "workspace never resolved" 2 "$(names_package "$WORK_DIR/ws_unresolved/packages/member")" "lacks:$URI_ERROR"

make_package "$WORK_DIR/half_resolved" dart
mkdir -p "$WORK_DIR/half_resolved/.dart_tool/pub"
run_hook "$(payload_for "$WORK_DIR/half_resolved/lib/a.dart")"
expect ".dart_tool without package_config.json" 2 "$(names_package "$WORK_DIR/half_resolved")"

make_package "$WORK_DIR/relative" dart
run_hook "$(payload_for "lib/a.dart")" "$FULL_PATH" "$WORK_DIR/relative"
expect "relative file path" 2 "$(names_package "$WORK_DIR/relative")" "lacks:$URI_ERROR"

mkdir -p "$WORK_DIR/cdpath/lib"
make_package "$WORK_DIR/cdpath_pkg" dart
HOOK_CDPATH="$WORK_DIR/cdpath"
run_hook "$(payload_for "lib/a.dart")" "$FULL_PATH" "$WORK_DIR/cdpath_pkg"
HOOK_CDPATH=""
expect "relative path with CDPATH set" 2 "$(names_package "$WORK_DIR/cdpath_pkg")"

make_package "$WORK_DIR/parent" dart
resolve "$WORK_DIR/parent"
make_package "$WORK_DIR/parent/example" flutter
run_hook "$(payload_for "$WORK_DIR/parent/example/lib/a.dart")"
expect "package nested in a resolved package that is not its workspace" 2 \
  "$(names_package "$WORK_DIR/parent/example")" "lacks:$URI_ERROR"

echo ""
echo "--- Dependencies resolved (exit 2, analyzer output passed through) ---"
make_package "$WORK_DIR/resolved" dart
resolve "$WORK_DIR/resolved"
run_hook "$(payload_for "$WORK_DIR/resolved/lib/a.dart")"
expect "package with package_config.json" 2 "has:$URI_ERROR" "lacks:not resolved"

make_package "$WORK_DIR/ws" workspace-root
make_package "$WORK_DIR/ws/packages/member" workspace-member
resolve "$WORK_DIR/ws"
run_hook "$(payload_for "$WORK_DIR/ws/packages/member/lib/a.dart")"
expect "workspace member resolved at the root" 2 "has:$URI_ERROR" "lacks:not resolved"

echo ""
echo "--- Nothing pub get can fix (exit 2, analyzer output passed through) ---"
stub_dart type-error
make_package "$WORK_DIR/typo" dart
run_hook "$(payload_for "$WORK_DIR/typo/lib/a.dart")"
expect "unresolved package, error unrelated to imports" 2 "has:$TYPE_ERROR" "lacks:not resolved"
stub_dart uri-error

mkdir -p "$WORK_DIR/loose"
printf "import 'package:path/path.dart';\n" > "$WORK_DIR/loose/a.dart"
run_hook "$(payload_for "$WORK_DIR/loose/a.dart")"
expect "file with no pubspec.yaml above it" 2 "has:$URI_ERROR" "lacks:not resolved"

make_package "$WORK_DIR/gone" dart
run_hook "$(payload_for "$WORK_DIR/gone/missing_dir/a.dart")"
expect "file in a directory that does not exist" 2 "has:$URI_ERROR" "lacks:not resolved"

make_package "$WORK_DIR/no_dart" dart
run_hook "$(payload_for "$WORK_DIR/no_dart/lib/a.dart")" "$WORK_DIR/jq-bin:$BASE_PATH"
expect "dart not installed" 2 "has:dart" "lacks:pub get"


echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi

#!/bin/bash
# Tests for sync-vge-standards.sh
#
# Usage: bash hooks/scripts/sync-vge-standards_test.sh
#
# Every case runs against a stubbed curl that serves files from a local "server"
# directory, answers If-None-Match with 304, and logs each URL it is asked for. No case
# touches the network or the real cache.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/sync-vge-standards.sh"

PASSED=0
FAILED=0

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

STUB_BIN="$WORK/bin"
SERVER="$WORK/server"      # URL path -> file, with an optional <file>.etag sibling
REQUESTS="$WORK/requests"  # one requested URL per line
CACHE_HOME="$WORK/cache"
ROOT="$CACHE_HOME/very_good_engineering/bundles"
ORIGIN="https://engineering.verygood.ventures"
BASE_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

mkdir -p "$STUB_BIN"

# The stub covers the two ways the hook calls curl: a single conditional GET
# (-o, -D, -w, -H) and a -K config of url/output pairs. $SERVER/offline makes every
# request fail the way an unreachable host does.
cat > "$STUB_BIN/curl" <<EOF
#!/bin/bash
SERVER="$SERVER"
REQUESTS="$REQUESTS"
ORIGIN="$ORIGIN"
EOF
cat >> "$STUB_BIN/curl" <<'EOF'
out=""; hdr=""; fmt=""; inm=""; cfg=""; url=""
while [ $# -gt 0 ]; do
  case "$1" in
    -o) out=$2; shift ;;
    -D) hdr=$2; shift ;;
    -w) fmt=$2; shift ;;
    -H) case "$2" in If-None-Match:*) inm=${2#If-None-Match: } ;; esac; shift ;;
    -K) cfg=$2; shift ;;
    --connect-timeout|--max-time|--max-filesize|--proto|--parallel-max) shift ;;
    -*) ;;
    *) url=$1 ;;
  esac
  shift
done

serve() { # serve URL OUT HDR -> prints status
  local u=$1 o=$2 h=$3 f etag=""
  echo "$u" >> "$REQUESTS"
  [ -e "$SERVER/offline" ] && return 7
  f="$SERVER/${u#"$ORIGIN"/}"
  [ -f "$f" ] || { echo 404; return 0; }
  [ -f "$f.etag" ] && etag=$(cat "$f.etag")
  if [ -n "$inm" ] && [ "$inm" = "$etag" ]; then
    [ -n "$h" ] && printf 'HTTP/2 304\r\netag: %s\r\n\r\n' "$etag" > "$h"
    : > "$o"; echo 304; return 0
  fi
  [ -n "$h" ] && printf 'HTTP/2 200\r\netag: %s\r\n\r\n' "$etag" > "$h"
  cp "$f" "$o"; echo 200
}

if [ -n "$cfg" ]; then
  u=""
  while IFS= read -r line; do
    v=${line#*= \"}; v=${v%\"}
    case "$line" in
      url*) u=$v ;;
      output*) serve "$u" "$v" "" >/dev/null || exit 7 ;;
    esac
  done < "$cfg"
  exit 0
fi
code=$(serve "$url" "$out" "$hdr") || { [ -n "$fmt" ] && printf '000'; exit 7; }
[ -n "$fmt" ] && printf '%s' "$code"
exit 0
EOF
chmod +x "$STUB_BIN/curl"

sha() { if command -v sha256sum >/dev/null; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d' ' -f1; }

# --- server fixtures -------------------------------------------------------------

# publish_manifest MAJOR MAJORS_JSON ETAG
publish_manifest() {
  mkdir -p "$SERVER/bundles"
  jq -n --argjson major "$1" --argjson majors "$2" --arg origin "$ORIGIN" \
    '{version: "\($major).0", major: $major, majors: $majors,
      index: "\($origin)/bundles/\($major)/index.json"}' > "$SERVER/bundles/manifest.json"
  printf '"%s"' "$3" > "$SERVER/bundles/manifest.json.etag"
}

# put_doc PATH CONTENT — serves a document under major 1.
put_doc() {
  mkdir -p "$(dirname "$SERVER/bundles/1/$1")"
  printf '%s' "$2" > "$SERVER/bundles/1/$1"
}
rm_doc() { rm -f "$SERVER/bundles/1/$1"; }

# publish_index ETAG PATH... — indexes the given documents as they are on the server.
publish_index() {
  local etag=$1 p entries="[]"
  shift
  for p in "$@"; do
    entries=$(jq --arg p "$p" --arg url "$ORIGIN/bundles/1/$p" \
      --arg sha "$(sha "$SERVER/bundles/1/$p")" \
      --argjson bytes "$(wc -c < "$SERVER/bundles/1/$p" | tr -d ' ')" \
      '. + [{path: $p, url: $url, sha256: $sha, bytes: $bytes,
             section: ($p | split("/")[0]), title: $p}]' <<< "$entries")
  done
  jq -n --argjson docs "$entries" '{version: "1.0", major: 1, docs: $docs}' \
    > "$SERVER/bundles/1/index.json"
  printf '"%s"' "$etag" > "$SERVER/bundles/1/index.json.etag"
}

# publish_raw_index ETAG JSON — an index with hand-written entries.
publish_raw_index() {
  printf '%s' "$2" > "$SERVER/bundles/1/index.json"
  printf '"%s"' "$1" > "$SERVER/bundles/1/index.json.etag"
}

reset() {
  rm -rf "$SERVER" "$CACHE_HOME" "$REQUESTS"
  mkdir -p "$SERVER" "$CACHE_HOME"
  : > "$REQUESTS"
}

baseline() {
  publish_manifest 1 '[1]' m1
  put_doc development/testing.md "# Testing"
  put_doc architecture/layers.md "# Layers"
  publish_index i1 development/testing.md architecture/layers.md
}

# --- runner ------------------------------------------------------------------------

LAST_OUTPUT=""
LAST_STATUS=0
run_hook() {
  : > "$REQUESTS"
  LAST_STATUS=0
  LAST_OUTPUT=$(env -i PATH="$STUB_BIN:$BASE_PATH" HOME="$WORK" XDG_CACHE_HOME="$CACHE_HOME" \
    bash "$HOOK" 2>&1) || LAST_STATUS=$?
}

requests() { wc -l < "$REQUESTS" | tr -d ' '; }

pass() { printf "  \033[32mPASS\033[0m  %s\n" "$1"; PASSED=$((PASSED + 1)); }
fail() {
  printf "  \033[31mFAIL\033[0m  %s\n    got (exit %s, %s requests): %s\n" \
    "$1" "$LAST_STATUS" "$(requests)" "$LAST_OUTPUT"
  FAILED=$((FAILED + 1))
}
check() { local name=$1; shift; if "$@"; then pass "$name"; else fail "$name"; fi; }

silent_ok() { [ "$LAST_STATUS" -eq 0 ] && [ -z "$LAST_OUTPUT" ]; }
cached() { [ "$(cat "$ROOT/1/$1" 2>/dev/null)" = "$2" ]; }

echo "sync-vge-standards"

echo "  first sync"
reset; baseline; run_hook
check "cold cache downloads every document silently" \
  bash -c '[ "$1" = 0 ] && [ -z "$2" ]' _ "$LAST_STATUS" "$LAST_OUTPUT"
check "documents land at their index path" \
  bash -c '[ "$(cat "$1/1/development/testing.md")" = "# Testing" ] && [ -f "$1/1/architecture/layers.md" ]' _ "$ROOT"
check "manifest and index ETags are stored next to the content" \
  bash -c '[ "$(cat "$1/manifest.etag")" = "\"m1\"" ] && [ "$(cat "$1/1/index.etag")" = "\"i1\"" ]' _ "$ROOT"
check "no lock or staging directory is left behind" \
  bash -c '! ls -a "$1" | grep -qE "^\.(lock|tmp)"' _ "$ROOT"

echo "  nothing changed"
run_hook
check "two 304s cost exactly two requests" bash -c '[ "$1" = 2 ]' _ "$(requests)"
check "and print nothing" silent_ok

echo "  minor release"
put_doc development/testing.md "# Testing v2"
rm_doc architecture/layers.md
put_doc general-practices/code-style.md "# Code style"
publish_index i2 development/testing.md general-practices/code-style.md
run_hook
check "only changed and new documents are downloaded" \
  bash -c '[ "$1" = 4 ] && ! grep -q layers "$2"' _ "$(requests)" "$REQUESTS"
check "changed document is updated" cached development/testing.md "# Testing v2"
check "new document is added" cached general-practices/code-style.md "# Code style"
check "document dropped from the index is removed with its empty directory" \
  bash -c '[ ! -e "$1/1/architecture" ]' _ "$ROOT"
check "index ETag advances" bash -c '[ "$(cat "$1/1/index.etag")" = "\"i2\"" ]' _ "$ROOT"

echo "  manifest unchanged, index changed"
put_doc development/testing.md "# Testing v3"
publish_index i3 development/testing.md general-practices/code-style.md
run_hook
check "a 304 manifest still revalidates the index" cached development/testing.md "# Testing v3"

echo "  integrity"
reset; baseline; run_hook
put_doc development/testing.md "# Testing v2"
publish_index i2 development/testing.md architecture/layers.md
put_doc development/testing.md "# Tampered!!"   # same length, different hash
run_hook
check "a document failing sha256 is discarded" cached development/testing.md "# Testing"
check "and the index ETag is not saved, so the next session retries" \
  bash -c '[ "$(cat "$1/1/index.etag")" = "\"i1\"" ]' _ "$ROOT"
put_doc development/testing.md "# Testing v2"
run_hook
check "next session completes the sync" cached development/testing.md "# Testing v2"

reset; baseline; run_hook
put_doc development/testing.md "# Testing v2"
publish_index i2 development/testing.md architecture/layers.md
put_doc development/testing.md "# Testing v2 plus"
run_hook
check "a document failing the byte count is discarded" cached development/testing.md "# Testing"

echo "  untrusted index entries"
reset; publish_manifest 1 '[1]' m1; put_doc ok.md "# ok"
publish_raw_index i1 "$(jq -n --arg o "$ORIGIN" --arg sha "$(sha "$SERVER/bundles/1/ok.md")" '{major: 1, docs: [
  {path: "../../escape.md", url: "\($o)/bundles/1/../../escape.md", sha256: $sha, bytes: 4},
  {path: "/abs.md", url: "\($o)/bundles/1//abs.md", sha256: $sha, bytes: 4},
  {path: "foreign.md", url: "https://example.com/foreign.md", sha256: $sha, bytes: 4},
  {path: "script.sh", url: "\($o)/bundles/1/script.sh", sha256: $sha, bytes: 4},
  {path: "ok.md", url: "\($o)/bundles/1/ok.md", sha256: $sha, bytes: 4}]}')"
run_hook
check "path traversal, absolute paths, foreign hosts and non-markdown are ignored" \
  bash -c '[ "$(grep -c . "$1")" = 3 ] && ! grep -qE "escape|abs|example|script" "$1"' _ "$REQUESTS"
check "valid entries still sync" cached ok.md "# ok"
check "nothing is written outside the cache" bash -c '[ ! -e "$1/escape.md" ] && [ ! -e "$1/../escape.md" ]' _ "$ROOT"

echo "  new VGE major"
reset; baseline; run_hook
publish_manifest 2 '[1,2]' m2
put_doc development/testing.md "# Testing v2"
publish_index i2 development/testing.md architecture/layers.md
run_hook
check "a newer major stops the sync and says so" \
  bash -c '[ "$1" = 0 ] && [[ "$2" == *"major 2"* ]] && [[ "$2" == *"target major 1"* ]]' _ "$LAST_STATUS" "$LAST_OUTPUT"
check "without requesting the index" bash -c '[ "$1" = 1 ]' _ "$(requests)"
check "and the local copy is kept" cached development/testing.md "# Testing"
run_hook
check "the message repeats when the manifest answers 304" \
  bash -c '[[ "$1" == *"major 2"* ]]' _ "$LAST_OUTPUT"

publish_manifest 2 '[2]' m3
run_hook
check "a retired target major is called out" \
  bash -c '[[ "$1" == *"no longer lists major 1"* ]]' _ "$LAST_OUTPUT"

reset; publish_manifest 1 '[2]' m1; run_hook
check "target major missing from majors is called out" \
  bash -c '[ "$1" = 0 ] && [[ "$2" == *"no longer lists standards major 1"* ]]' _ "$LAST_STATUS" "$LAST_OUTPUT"

echo "  failing open"
reset; touch "$SERVER/offline"; run_hook
check "offline with no cache exits 0 silently" silent_ok

reset; baseline; run_hook; touch "$SERVER/offline"; run_hook
check "offline with a cache exits 0 silently" silent_ok
check "and keeps the cache" cached development/testing.md "# Testing"

reset; baseline; run_hook
printf '<html>Sign in to Wi-Fi</html>' > "$SERVER/bundles/manifest.json"
printf '"portal"' > "$SERVER/bundles/manifest.json.etag"
run_hook
check "a captive portal page is not taken for the manifest" \
  bash -c '[ "$(cat "$1/manifest.etag")" = "\"m1\"" ] && jq -e .major "$1/manifest.json" >/dev/null' _ "$ROOT"
check "and the session carries on silently" silent_ok

reset; baseline; run_hook
printf '<html>portal</html>' > "$SERVER/bundles/1/index.json"
printf '"portal"' > "$SERVER/bundles/1/index.json.etag"
run_hook
check "a non-JSON index leaves the cache alone" \
  bash -c '[ "$(cat "$1/1/index.etag")" = "\"i1\"" ] && [ -f "$1/1/architecture/layers.md" ]' _ "$ROOT"

reset; baseline; run_hook; rm -f "$ROOT/1/index.json"
run_hook
check "a missing index.json is refetched rather than trusted to its ETag" \
  bash -c '[ -f "$1/1/index.json" ]' _ "$ROOT"

echo "  concurrency"
reset; baseline; mkdir -p "$ROOT/.lock"; run_hook
check "a fresh lock held by another run is respected" \
  bash -c '[ "$1" = 0 ] && [ -d "$2/.lock" ]' _ "$(requests)" "$ROOT"
touch -t 202001010000 "$ROOT/.lock"; mkdir -p "$ROOT/.tmp.dead"; run_hook
check "a stale lock is taken over and staging leftovers are cleared" \
  bash -c '[ -f "$1/1/development/testing.md" ] && [ ! -e "$1/.lock" ] && [ ! -e "$1/.tmp.dead" ]' _ "$ROOT"

echo
echo "  $PASSED passed, $FAILED failed"
[ "$FAILED" -eq 0 ]

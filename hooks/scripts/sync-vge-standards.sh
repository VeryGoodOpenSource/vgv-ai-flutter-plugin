#!/bin/bash
# SessionStart hook: keep a local copy of Very Good Engineering's published standards.
#
# The cache is shared by every VGV plugin and lives outside any plugin directory:
#   ${XDG_CACHE_HOME:-$HOME/.cache}/very_good_engineering/bundles/
#     manifest.json  manifest.etag
#     <major>/index.json  <major>/index.etag  <major>/<doc path>.md
# Local paths mirror the URL paths under https://engineering.verygood.ventures/bundles/.
#
# A normal run is two conditional GETs answered with 304. Downloaded content is data:
# it is hashed, size-checked and written to disk, never printed or executed.
# Fails open — any network, parse or filesystem problem leaves the cache as it was.
# Prints only when VGE published a major this plugin was not built for. Always exits 0.

# The VGE major this plugin's skills are written against. Bump it in the same change
# that updates the skills for a new major.
VGE_TARGET_MAJOR=1

VGE_ORIGIN="https://engineering.verygood.ventures"
ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/very_good_engineering/bundles"
MAJOR_DIR="$ROOT/$VGE_TARGET_MAJOR"
LOCK="$ROOT/.lock"
DEADLINE=8           # seconds; the hook timeout is 10
MAX_BYTES=1048576    # per response

command -v jq >/dev/null 2>&1 || exit 0
command -v curl >/dev/null 2>&1 || exit 0
if command -v sha256sum >/dev/null 2>&1; then
  sha256() { sha256sum "$1" | cut -d' ' -f1; }
elif command -v shasum >/dev/null 2>&1; then
  sha256() { shasum -a 256 "$1" | cut -d' ' -f1; }
else
  exit 0
fi

mkdir -p "$MAJOR_DIR" 2>/dev/null || exit 0

# One sync at a time across sessions and plugins. A lock older than a minute belongs to
# a run that was killed, so it is taken over.
if ! mkdir "$LOCK" 2>/dev/null; then
  [ -n "$(find "$LOCK" -maxdepth 0 -mmin +1 2>/dev/null)" ] || exit 0
  rm -rf "$LOCK"
  mkdir "$LOCK" 2>/dev/null || exit 0
fi
TMP=""
trap 'rm -rf "$TMP"; rmdir "$LOCK" 2>/dev/null' EXIT
trap 'exit 0' TERM INT HUP

# Holding the lock, any staging directory left behind is from a killed run.
rm -rf "$ROOT"/.tmp.* 2>/dev/null
TMP=$(mktemp -d "$ROOT/.tmp.XXXXXX") || exit 0

# fetch URL OUT [ETAG] — sets FETCH_CODE (000 on any transport failure) and FETCH_ETAG.
fetch() {
  local url=$1 out=$2 etag=${3:-} budget
  FETCH_CODE=000
  FETCH_ETAG=""
  budget=$((DEADLINE - SECONDS))
  [ "$budget" -ge 1 ] || return 0
  [ "$budget" -gt 5 ] && budget=5
  local args=(-sS --proto =https --connect-timeout 3 --max-time "$budget"
    --max-filesize "$MAX_BYTES" -o "$out" -D "$out.headers" -w '%{http_code}')
  [ -n "$etag" ] && args+=(-H "If-None-Match: $etag")
  FETCH_CODE=$(curl "${args[@]}" "$url" 2>/dev/null) || FETCH_CODE=000
  FETCH_ETAG=$(grep -i '^etag:' "$out.headers" 2>/dev/null | tail -n 1 | cut -d: -f2- \
    | tr -d '\r' | sed 's/^ *//')
  [[ "$FETCH_ETAG" =~ ^(W/)?\"[^\"]*\"$ ]] || FETCH_ETAG=""
  rm -f "$out.headers"
}

# An ETag is only sent when the file it validates is still on disk.
stored_etag() { [ -f "$1" ] && cat "$1.etag" 2>/dev/null; }

valid_manifest() {
  jq -e '(.major | type == "number") and (.majors | type == "array")
    and (.index | type == "string")' "$1" >/dev/null 2>&1
}

# 1. Manifest. Anything but a valid 200 falls back to the stored copy.
fetch "$VGE_ORIGIN/bundles/manifest.json" "$TMP/manifest.json" \
  "$(stored_etag "$ROOT/manifest.json")"
if [ "$FETCH_CODE" = 200 ] && valid_manifest "$TMP/manifest.json"; then
  mv -f "$TMP/manifest.json" "$ROOT/manifest.json" || exit 0
  if [ -n "$FETCH_ETAG" ]; then
    printf '%s\n' "$FETCH_ETAG" > "$ROOT/manifest.etag"
  else
    rm -f "$ROOT/manifest.etag"
  fi
fi
valid_manifest "$ROOT/manifest.json" || exit 0

published=$(jq -r '.major' "$ROOT/manifest.json")
listed=$(jq --argjson m "$VGE_TARGET_MAJOR" 'any(.majors[]; . == $m)' "$ROOT/manifest.json")
if [ "$published" -gt "$VGE_TARGET_MAJOR" ] 2>/dev/null; then
  retired=""
  [ "$listed" = true ] || retired=" VGE no longer lists major ${VGE_TARGET_MAJOR}, so the local copy is retired guidance."
  echo "ℹ️ Very Good Engineering published standards major ${published}; this plugin's skills target major ${VGE_TARGET_MAJOR}. The standards sync is paused until the plugin is updated for major ${published}, and the local copy stays on major ${VGE_TARGET_MAJOR}.${retired} Tell the user once that the plugin needs an update."
  exit 0
fi
if [ "$listed" != true ]; then
  echo "ℹ️ Very Good Engineering no longer lists standards major ${VGE_TARGET_MAJOR}, which this plugin's skills target. The standards sync is paused and the local copy may be outdated. Tell the user once that the plugin needs an update."
  exit 0
fi

index_url=$(jq -r '.index' "$ROOT/manifest.json")
case "$index_url" in
  "$VGE_ORIGIN/bundles/$VGE_TARGET_MAJOR/"*) ;;
  *) exit 0 ;;
esac

# 2. Index. 304 means nothing changed.
fetch "$index_url" "$TMP/index.json" "$(stored_etag "$MAJOR_DIR/index.json")"
[ "$FETCH_CODE" = 200 ] || exit 0
jq -e --argjson m "$VGE_TARGET_MAJOR" '.major == $m and (.docs | type == "array")' \
  "$TMP/index.json" >/dev/null 2>&1 || exit 0
index_etag=$FETCH_ETAG

# 3. Documents. Pick out what is missing or stale, fetch it in one parallel curl run
# that reuses the connection, then verify each file before moving it into place.
# The index ETag is saved only when every document landed, so an interrupted run
# resumes next session and skips what it already verified.
complete=1
n=0
mkdir "$TMP/dl" || exit 0
: > "$TMP/listed"
: > "$TMP/wanted"
: > "$TMP/curl.cfg"
while IFS=$'\t' read -r path url sha bytes; do
  # Reject anything that could escape the cache or point at another host.
  [[ "$path" =~ ^[A-Za-z0-9_-][A-Za-z0-9._/-]*\.md$ ]] || continue
  case "$path" in *..* | *//*) continue ;; esac
  [ "$url" = "$VGE_ORIGIN/bundles/$VGE_TARGET_MAJOR/$path" ] || continue
  [[ "$sha" =~ ^[0-9a-f]{64}$ ]] || continue
  [[ "$bytes" =~ ^[0-9]+$ ]] && [ "$bytes" -le "$MAX_BYTES" ] || continue
  printf '%s\n' "$path" >> "$TMP/listed"

  [ -f "$MAJOR_DIR/$path" ] && [ "$(sha256 "$MAJOR_DIR/$path")" = "$sha" ] && continue
  n=$((n + 1))
  printf '%s\t%s\t%s\t%s\n' "$n" "$path" "$sha" "$bytes" >> "$TMP/wanted"
  printf 'url = "%s"\noutput = "%s/dl/%s"\n' "$url" "$TMP" "$n" >> "$TMP/curl.cfg"
done < <(jq -r '.docs[] | [.path, .url, .sha256, (.bytes | tostring)] | @tsv' \
  "$TMP/index.json" 2>/dev/null)

if [ "$n" -gt 0 ]; then
  budget=$((DEADLINE - SECONDS))
  if [ "$budget" -ge 1 ]; then
    curl -sS --fail --proto =https --connect-timeout 3 --max-time "$budget" \
      --max-filesize "$MAX_BYTES" --parallel --parallel-max 6 -K "$TMP/curl.cfg" \
      >/dev/null 2>&1
  fi
  while IFS=$'\t' read -r i path sha bytes; do
    got="$TMP/dl/$i"
    if [ -f "$got" ] \
      && [ "$(wc -c < "$got" | tr -d ' ')" = "$bytes" ] \
      && [ "$(sha256 "$got")" = "$sha" ] \
      && mkdir -p "$(dirname "$MAJOR_DIR/$path")" \
      && mv -f "$got" "$MAJOR_DIR/$path"; then
      :
    else
      complete=0
    fi
  done < "$TMP/wanted"
fi

# Remove documents the index no longer lists.
(cd "$MAJOR_DIR" && find . -type f -name '*.md') | sed 's|^\./||' | while IFS= read -r f; do
  grep -Fxq -- "$f" "$TMP/listed" || rm -f "$MAJOR_DIR/$f"
done
find "$MAJOR_DIR" -mindepth 1 -type d -empty -delete 2>/dev/null

if [ "$complete" = 1 ]; then
  mv -f "$TMP/index.json" "$MAJOR_DIR/index.json" || exit 0
  if [ -n "$index_etag" ]; then
    printf '%s\n' "$index_etag" > "$MAJOR_DIR/index.etag"
  else
    rm -f "$MAJOR_DIR/index.etag"
  fi
fi

exit 0

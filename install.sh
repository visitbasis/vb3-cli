#!/bin/sh
# Install only the checksum-verified binary from VisitBasis's public release repository.
set -eu

fail() { printf 'vb3: %s\n' "$*" >&2; exit 1; }
fetch() {
  curl -q --fail --silent --show-error --location \
    --proto '=https' --proto-redir '=https' --connect-timeout 10 --max-time 120 "$@"
}

[ "$#" -eq 0 ] || fail 'set VB3_VERSION to select a release; no installer arguments are accepted'
[ -n "${HOME:-}" ] || fail 'HOME is not set'
case "$HOME" in /*) ;; *) fail 'HOME must be an absolute path' ;; esac
case "$(uname -s)" in
  Darwin) os=darwin ;;
  Linux) os=linux ;;
  *) fail 'supported systems are macOS and Linux' ;;
esac
case "$(uname -m)" in
  x86_64|amd64) arch=amd64 ;;
  arm64|aarch64) arch=arm64 ;;
  *) fail 'supported architectures are amd64 and arm64' ;;
esac

repo='https://github.com/visitbasis/vb3-cli'
version=${VB3_VERSION:-}
if [ -z "$version" ]; then
  # Resolve latest once, then download both files from the same immutable tag path.
  latest=$(fetch --head --output /dev/null --write-out '%{url_effective}' "$repo/releases/latest") || fail 'could not resolve the latest public release'
  case "$latest" in "$repo/releases/tag/"*) version=${latest#"$repo/releases/tag/"} ;; *) fail 'unexpected latest-release redirect' ;; esac
fi
case "$version" in
  v0.4.*)
    patch=${version#v0.4.}
    case "$patch" in ''|*[!0-9]*|0[0-9]*) fail 'VB3_VERSION must be an exact release tag such as v0.4.0' ;; esac
    ;;
  *) fail 'VB3_VERSION must be an exact release tag such as v0.4.0' ;;
esac

if command -v sha256sum >/dev/null 2>&1; then
  hash() { sha256sum "$1" | awk '{print $1}'; }
elif command -v shasum >/dev/null 2>&1; then
  hash() { shasum -a 256 "$1" | awk '{print $1}'; }
else
  fail 'SHA-256 verification needs sha256sum (Linux) or shasum (macOS)'
fi

tmp=
stage=
cleanup() {
  [ -z "$tmp" ] || rm -rf "$tmp"
  [ -z "$stage" ] || rm -f "$stage"
}
trap cleanup 0
trap 'exit 1' 1 2 3 15
umask 077
tmp=$(mktemp -d "${TMPDIR:-/tmp}/vb3-install.XXXXXX") || fail 'cannot create a temporary directory'
archive="vb3_${os}_${arch}.tar.gz"
base="$repo/releases/download/$version"
fetch --max-filesize 262144 --output "$tmp/checksums.txt" "$base/checksums.txt" || fail 'could not download release checksums'
expected=$(awk -v name="$archive" '($2 == name || $2 == ("*" name)) { n++; print $1 } END { if (n != 1) exit 1 }' "$tmp/checksums.txt") || fail 'release checksum is missing or duplicated'
[ "${#expected}" -eq 64 ] || fail 'invalid release checksum'
case "$expected" in *[!0-9a-fA-F]*) fail 'invalid release checksum' ;; esac
expected=$(printf '%s' "$expected" | tr 'A-F' 'a-f')
fetch --max-filesize 67108864 --output "$tmp/$archive" "$base/$archive" || fail 'could not download the release archive'
actual=$(hash "$tmp/$archive") || fail 'could not calculate the archive checksum'
[ "$actual" = "$expected" ] || fail 'checksum mismatch; installed binary was not changed'

tar -tzf "$tmp/$archive" > "$tmp/members" || fail 'invalid release archive'
binary_count=0
while IFS= read -r entry; do
  case "$entry" in
    vb3) binary_count=$((binary_count + 1)) ;;
    README.md|install.sh) ;;
    *) fail 'unexpected path in release archive' ;;
  esac
done < "$tmp/members"
[ "$binary_count" -eq 1 ] || fail 'release archive must contain exactly one vb3 binary'
tar -tvzf "$tmp/$archive" > "$tmp/types" || fail 'invalid release archive'
awk 'substr($1,1,1) != "-" { exit 1 }' "$tmp/types" || fail 'release archive contains a non-regular file'
# Stream the one allowed member; never extract archive-controlled paths or modes.
tar -xzOf "$tmp/$archive" vb3 > "$tmp/vb3" || fail 'could not extract vb3'
[ -s "$tmp/vb3" ] || fail 'release binary is empty'

install_dir="$HOME/.local/bin"
destination="$install_dir/vb3"
mkdir -p "$install_dir" || fail 'cannot create ~/.local/bin'
[ ! -L "$destination" ] || fail '~/.local/bin/vb3 is a symlink; choose a regular installation path first'
if [ -e "$destination" ] && [ ! -f "$destination" ]; then fail '~/.local/bin/vb3 is not a regular file'; fi
if [ -f "$destination" ] && cmp -s "$tmp/vb3" "$destination"; then
  chmod 0755 "$destination"
  printf 'vb3 %s is already installed at %s\n' "$version" "$destination"
else
  # Same-directory staging makes replacement atomic on the destination filesystem.
  stage=$(mktemp "$install_dir/.vb3-install.XXXXXX") || fail 'cannot stage the installation'
  cat "$tmp/vb3" > "$stage"
  chmod 0755 "$stage"
  mv -f "$stage" "$destination" || fail 'could not replace vb3'
  stage=
  printf 'Installed vb3 %s at %s\n' "$version" "$destination"
fi
case ":${PATH:-}:" in
  *":$install_dir:"*) ;;
  *) printf 'Add vb3 to this shell:\n  export PATH="$HOME/.local/bin:$PATH"\n' ;;
esac

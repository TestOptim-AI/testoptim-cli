#!/bin/sh
# Install the testoptim CLI: curl -fsSL <url>/install.sh | sh
# Env: TESTOPTIM_VERSION (e.g. 1.2.3, default latest), INSTALL_DIR (default /usr/local/bin or ~/.local/bin),
#      TESTOPTIM_REPO (GitHub owner/repo hosting the releases).
set -eu

REPO="${TESTOPTIM_REPO:-TestOptim-AI/testoptim-cli}"
TAG_PREFIX="cli-v"

fail() { echo "install: $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

case "$(uname -s)" in
  Darwin) os=darwin ;;
  Linux) os=linux ;;
  *) fail "unsupported OS $(uname -s); download a release manually (Windows: use the .zip)" ;;
esac
case "$(uname -m)" in
  x86_64 | amd64) arch=amd64 ;;
  arm64 | aarch64) arch=arm64 ;;
  *) fail "unsupported architecture $(uname -m)" ;;
esac

if have curl; then fetch() { curl -fsSL "$1"; }; download() { curl -fsSL -o "$2" "$1"; }
elif have wget; then fetch() { wget -qO- "$1"; }; download() { wget -qO "$2" "$1"; }
else fail "curl or wget is required"; fi

version="${TESTOPTIM_VERSION:-}"
version="${version#v}"
version="${version#cli-v}"
case "$version" in *[!0-9A-Za-z.+-]*) fail "invalid version: $version" ;; esac
if [ -z "$version" ]; then
  version=$(fetch "https://api.github.com/repos/$REPO/releases?per_page=50" |
    grep -o "\"tag_name\": *\"${TAG_PREFIX}[0-9][0-9.]*\"" | head -n 1 | sed "s/.*\"${TAG_PREFIX}\([^\"]*\)\"/\1/")
  [ -n "$version" ] || fail "could not determine the latest version; set TESTOPTIM_VERSION"
fi

archive="testoptim_${version}_${os}_${arch}.tar.gz"
checksums="testoptim_${version}_checksums.txt"
base="https://github.com/$REPO/releases/download/${TAG_PREFIX}${version}"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "Downloading testoptim $version ($os/$arch)..."
download "$base/$archive" "$tmp/$archive" || fail "download failed: $base/$archive"
download "$base/$checksums" "$tmp/$checksums" || fail "download failed: $base/$checksums"

expected=$(awk -v f="$archive" '$2 == f {print $1}' "$tmp/$checksums")
[ -n "$expected" ] || fail "no checksum listed for $archive"
if have sha256sum; then actual=$(sha256sum "$tmp/$archive" | awk '{print $1}')
elif have shasum; then actual=$(shasum -a 256 "$tmp/$archive" | awk '{print $1}')
else fail "sha256sum or shasum is required to verify the download"; fi
[ "$expected" = "$actual" ] || fail "checksum mismatch for $archive"

tar -xzf "$tmp/$archive" -C "$tmp" testoptim

dir="${INSTALL_DIR:-}"
if [ -z "$dir" ]; then
  if [ -w /usr/local/bin ]; then dir=/usr/local/bin; else dir="$HOME/.local/bin"; fi
fi
mkdir -p "$dir"
if [ -w "$dir" ]; then install -m 0755 "$tmp/testoptim" "$dir/testoptim"
else
  have sudo || fail "$dir is not writable; set INSTALL_DIR"
  sudo install -m 0755 "$tmp/testoptim" "$dir/testoptim"
fi

echo "Installed $dir/testoptim"
case ":$PATH:" in *":$dir:"*) ;; *) echo "Add $dir to your PATH." ;; esac
echo "Next: testoptim auth"

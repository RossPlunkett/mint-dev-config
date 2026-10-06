#!/usr/bin/env bash
set -euo pipefail

# draw.io desktop from the latest official jgraph/drawio-desktop GitHub release.
# The .deb is checked against the release's own SHA-256 list, then installed
# with apt so its declared dependencies are resolved.
arch="$(dpkg --print-architecture)"
case "$arch" in
    amd64|arm64) ;;
    *) printf 'draw.io publishes no .deb for %s\n' "$arch" >&2; exit 1 ;;
esac

release="$(DRAWIO_ARCH="$arch" python3 <<'PY'
import json
import os
import re
import urllib.request

request = urllib.request.Request(
    "https://api.github.com/repos/jgraph/drawio-desktop/releases/latest",
    headers={"Accept": "application/vnd.github+json", "User-Agent": "mint-dev-config"},
)
with urllib.request.urlopen(request) as response:
    release = json.load(response)

version = release["tag_name"].removeprefix("v")
pattern = re.compile(rf"drawio-{re.escape(os.environ['DRAWIO_ARCH'])}-{re.escape(version)}\.deb")
assets = {asset["name"]: asset["browser_download_url"] for asset in release["assets"]}
debs = [name for name in assets if pattern.fullmatch(name)]
if len(debs) != 1 or "Files-SHA256-Hashes.txt" not in assets:
    raise SystemExit(f"draw.io {version}: expected one {os.environ['DRAWIO_ARCH']} .deb and Files-SHA256-Hashes.txt")
print(version, debs[0], assets[debs[0]], assets["Files-SHA256-Hashes.txt"])
PY
)"
read -r version deb_name deb_url hashes_url <<<"$release"

if [[ "$(dpkg-query -W -f='${Version}' draw.io 2>/dev/null || true)" == "$version" ]]; then
    printf 'exists  draw.io %s\n' "$version"
    exit 0
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
curl -fsSL --proto '=https' "$hashes_url" -o "$work_dir/hashes.txt"
awk -v name="$deb_name" '$2 == name' "$work_dir/hashes.txt" >"$work_dir/deb.sha256"
if [[ ! -s "$work_dir/deb.sha256" ]]; then
    printf 'No official SHA-256 for %s\n' "$deb_name" >&2
    exit 1
fi
curl -fL --proto '=https' "$deb_url" -o "$work_dir/$deb_name"
(cd "$work_dir" && sha256sum --check --strict deb.sha256)

# apt reads local packages as the unprivileged _apt user.
chmod 0755 "$work_dir"
chmod 0644 "$work_dir/$deb_name"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$work_dir/$deb_name"

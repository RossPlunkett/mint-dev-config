#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/Applications" "$HOME/.local/bin"
asset_url="$(python3 <<'PY'
import json
import platform
import urllib.request

request = urllib.request.Request(
    "https://api.github.com/repos/pingdotgg/t3code/releases/latest",
    headers={"Accept": "application/vnd.github+json", "User-Agent": "mint-dev-config"},
)
with urllib.request.urlopen(request) as response:
    assets = json.load(response)["assets"]

machine = platform.machine().lower()
tokens = ("arm64", "aarch64") if machine in {"arm64", "aarch64"} else ("x86_64", "amd64", "x64")
matches = [asset for asset in assets if asset["name"].endswith(".AppImage") and any(token in asset["name"].lower() for token in tokens)]
if not matches:
    raise SystemExit(f"No T3 Code AppImage release supports {machine}")
print(matches[0]["browser_download_url"])
PY
)"
curl -fL "$asset_url" -o "$HOME/Applications/T3-Code.AppImage"
chmod +x "$HOME/Applications/T3-Code.AppImage"
ln -sfn "$HOME/Applications/T3-Code.AppImage" "$HOME/.local/bin/t3code"


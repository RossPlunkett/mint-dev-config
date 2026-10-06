#!/usr/bin/env bash
set -euo pipefail

# Blender LTS from the official release archive, verified against the official
# SHA-256 list, unpacked to ~/.local/share/blender/<version>.
version=5.2.2
series="${version%.*}"
archive="blender-$version-linux-x64.tar.xz"
release_url="https://download.blender.org/release/Blender$series"
install_root="$HOME/.local/share/blender"
install_dir="$install_root/$version"
software_marker="$HOME/.config/mint-dev-config/blender-software-rendering"
mode="${1:-}"
if (($# > 1)) || [[ -n "$mode" && "$mode" != --software-rendering && "$mode" != --hardware-rendering ]]; then
    printf 'Usage: %s [--software-rendering|--hardware-rendering]\n' "$0" >&2
    exit 2
fi

case "$(uname -m)" in
    x86_64|amd64) ;;
    *) printf 'Blender %s is installed only for x86_64; this machine is %s.\n' "$version" "$(uname -m)" >&2; exit 1 ;;
esac

mkdir -p "$install_root" "$HOME/.local/bin"

if [[ -x "$install_dir/blender" ]]; then
    printf 'exists  %s\n' "$install_dir"
else
    work_dir="$(mktemp -d)"
    trap 'rm -rf "$work_dir"' EXIT

    curl -fsSL --proto '=https' "$release_url/blender-$version.sha256" -o "$work_dir/blender.sha256"
    awk -v name="$archive" '$2 == name' "$work_dir/blender.sha256" >"$work_dir/archive.sha256"
    if [[ ! -s "$work_dir/archive.sha256" ]]; then
        printf 'No official SHA-256 for %s\n' "$archive" >&2
        exit 1
    fi

    curl -fL --proto '=https' "$release_url/$archive" -o "$work_dir/$archive"
    (cd "$work_dir" && sha256sum --check --strict archive.sha256)

    # Extract beside the destination, then rename into place so an interrupted
    # run never leaves a half-populated version directory.
    staging="$(mktemp -d "$install_root/.staging.XXXXXX")"
    trap 'rm -rf "$work_dir" "$staging"' EXIT
    tar -xJf "$work_dir/$archive" -C "$staging" --strip-components=1
    [[ -x "$staging/blender" ]] || { printf 'Archive did not contain a blender executable\n' >&2; exit 1; }
    chmod 0755 "$staging"
    mv -T "$staging" "$install_dir"
fi

# This preference is local to the machine and survives normal bootstrap reruns.
case "$mode" in
    --software-rendering)
        mkdir -p "$(dirname "$software_marker")"
        printf '1\n' >"$software_marker"
        ;;
    --hardware-rendering) rm -f -- "$software_marker" ;;
esac

if [[ -f "$software_marker" ]]; then
    launcher_tmp="$(mktemp "$HOME/.local/bin/.blender.XXXXXX")"
    printf '#!/usr/bin/env bash\nexport LIBGL_ALWAYS_SOFTWARE=1\nexec %q "$@"\n' "$install_dir/blender" >"$launcher_tmp"
    chmod 0755 "$launcher_tmp"
    mv -Tf -- "$launcher_tmp" "$HOME/.local/bin/blender"
    printf 'launcher Blender uses software OpenGL on this machine\n'
else
    ln -sfn "$install_dir/blender" "$HOME/.local/bin/blender"
fi

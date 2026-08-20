#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0
WITH_PROJECTS=0
SKIP_BUILD=0

usage() {
    cat <<'EOF'
Usage: ./bootstrap.sh [options]

Configure a Linux Mint 22.3 + i3 development workstation.

Options:
  --dry-run        Print intended actions without changing the machine
  --with-projects  Clone Ross-o-Fone, Sauce, and karaoke repositories
  --skip-build     Clone projects but skip npm/JUCE bootstrap builds
  -h, --help       Show this help
EOF
}

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --with-projects) WITH_PROJECTS=1 ;;
        --skip-build) SKIP_BUILD=1 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

manifest_items() {
    sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$1"
}

print_manifest() {
    local label="$1" path="$2"
    printf '\n%s:\n' "$label"
    manifest_items "$path" | sed 's/^/  - /'
}

printf 'Target: Linux Mint 22.3 with i3\n'
printf 'Repository: %s\n' "$ROOT"
print_manifest 'APT packages' "$ROOT/manifests/apt.txt"
print_manifest 'Homebrew formulae' "$ROOT/manifests/brew.txt"
print_manifest 'Flatpak applications' "$ROOT/manifests/flatpak.txt"

if ((WITH_PROJECTS)); then
    printf '\nProject checkouts:\n'
    awk -F '\t' '!/^#/ && NF == 3 { printf "  - %s/%s (%s)\n", $1, $2, $3 }' "$ROOT/manifests/repositories.tsv"
fi

if ((DRY_RUN)); then
    printf '\nDry run complete; no changes made.\n'
    exit 0
fi

if [[ ! -r /etc/linuxmint/info ]] || ! rg -q '^RELEASE=22\.3$' /etc/linuxmint/info; then
    printf 'This bootstrap supports Linux Mint 22.3 only.\n' >&2
    exit 1
fi

printf '\nThe executable installation phases are added in the following verified slices.\n'


#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if rg -n --hidden \
    --glob '!.git/**' \
    --glob '!scripts/secret-scan.sh' \
    --glob '!tests/test.sh' \
    '(BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|sk-[A-Za-z0-9_-]{20,}|gh[opsu]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16})' \
    "$ROOT"; then
    printf 'Potential secret material found. Review before committing.\n' >&2
    exit 1
fi

printf 'No obvious secret material found.\n'

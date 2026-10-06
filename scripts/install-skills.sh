#!/usr/bin/env bash
set -euo pipefail

# Installs the agent skills listed in manifests/skills.tsv
# (source-id<TAB>clone-url<TAB>upstream-subdir<TAB>skill-name).
#
# Each source repository is shallow-cloned once into a temporary directory;
# existing checkouts elsewhere on the machine are never touched. A skill comes
# from its upstream directory when that contains SKILL.md, otherwise from the
# bundled copy in fallback-skills/<source-id>/<skill-name>. The chosen
# directory is copied (symlinks dereferenced) into ~/.agents/skills/<skill-name>.
# Pi and OMP discover it there; other supported CLIs receive compatibility links.
# Nothing inside a downloaded skill is executed.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/manifests/skills.tsv"
FALLBACK_ROOT="$ROOT/fallback-skills"
STORE="$HOME/.agents/skills"
OLD_STORE="$HOME/.local/share/mint-dev-config-skills"
DESTINATIONS=(
    "$HOME/.claude/skills"
    "$HOME/.codex/skills"
    "$HOME/.config/opencode/skills"
)
# Symlinks into these trees were made by earlier installers (the old
# install-matt-skills.sh checkout and manual plugin installs); a link here that
# points at a directory with the same skill name is replaced by the managed one.
OLD_LINK_ROOTS=(
    "$HOME/.local/share/mattpocock-skills"
    "$HOME/.local/share/cursor-plugins/pstack/skills"
    "$HOME/.pi/agent/git/github.com/DietrichGebert/ponytail/skills"
)

# Downloads give up when slower than 1 KiB/s for 30 s, and never run longer
# than 10 minutes in total. Credential and SSH prompts fail instead of waiting.
CLONE_TIMEOUT=600
export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -o BatchMode=yes -o ConnectTimeout=20}"

log() { printf '%-9s %s\n' "$1" "$2"; }
warn() { printf '%-9s %s\n' "$1" "$2" >&2; }

[[ -f "$MANIFEST" ]] || { warn error "missing manifest $MANIFEST"; exit 1; }

safe_name() { [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; }
safe_subdir() {
    [[ -n "$1" && "$1" != /* && ! "$1" =~ (^|/)\.\.?(/|$) ]]
}

# Parse and validate the whole manifest before changing anything.
sources=() rows=()
declare -A source_url=() seen_name=()
line_number=0
while IFS=$'\t' read -r source url subdir name extra || [[ -n "$source" ]]; do
    line_number=$((line_number + 1))
    [[ -z "$source" || "$source" == \#* ]] && continue
    if [[ -z "$url" || -z "$subdir" || -z "$name" || -n "${extra:-}" ]] ||
        ! safe_name "$source" || ! safe_name "$name" || ! safe_subdir "$subdir"; then
        warn error "invalid manifest line $line_number in $MANIFEST"
        exit 1
    fi
    if [[ -n "${seen_name[$name]:-}" ]]; then
        warn error "skill $name listed twice in $MANIFEST"
        exit 1
    fi
    seen_name[$name]=1
    if [[ -z "${source_url[$source]:-}" ]]; then
        source_url[$source]="$url"
        sources+=("$source")
    elif [[ "${source_url[$source]}" != "$url" ]]; then
        warn error "source $source has more than one clone URL in $MANIFEST"
        exit 1
    fi
    rows+=("$source"$'\t'"$subdir"$'\t'"$name")
done <"$MANIFEST"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

declare -A clone_dir=()
for source in "${sources[@]}"; do
    url="${source_url[$source]}"
    destination="$work/clones/$source"
    log fetch "$source $url"
    if timeout "$CLONE_TIMEOUT" git \
        -c http.lowSpeedLimit=1024 -c http.lowSpeedTime=30 -c advice.detachedHead=false \
        clone --quiet --depth 1 --no-tags --single-branch -- "$url" "$destination" \
        </dev/null 2>"$work/clone-$source.err"; then
        clone_dir[$source]="$destination"
    else
        reason="$(tail -n 1 "$work/clone-$source.err")"
        warn offline "$source: clone failed (${reason:-timed out}); using bundled fallbacks"
    fi
done

# A skill directory is usable when it has SKILL.md, lies inside $2, and every
# symlink inside it resolves to an existing path within $2 that is not one of
# its own ancestors. Copying it dereferenced then cannot pull in files from
# elsewhere on the machine, loop, or leave dangling links.
usable_skill_dir() {
    local dir="$1" boundary real link resolved
    boundary="$(realpath -e -- "$2" 2>/dev/null)" || return 1
    [[ -d "$dir" && ! -L "$dir" && -f "$dir/SKILL.md" ]] || return 1
    real="$(realpath -e -- "$dir")" || return 1
    [[ "$real" == "$boundary" || "$real" == "$boundary"/* ]] || return 1
    while IFS= read -r -d '' link; do
        resolved="$(realpath -e -- "$link" 2>/dev/null)" || return 1
        [[ "$resolved" == "$boundary"/* ]] || return 1
        [[ "$real" == "$resolved" || "$real" == "$resolved"/* ]] && return 1
    done < <(find "$dir" -type l -print0)
    return 0
}

# Copy $1 to $STORE/$2 through a staging directory on the same filesystem, so
# the previous copy is only removed once the new one is complete.
materialize() {
    local source_dir="$1" name="$2" stage
    mkdir -p "$STORE" && stage="$(mktemp -d "$STORE/.staging.XXXXXX")" || return 1
    if ! cp -RL -- "$source_dir" "$stage/$name"; then
        rm -rf "$stage"
        return 1
    fi
    printf '%s\n' 'Managed by mint-dev-config' >"$stage/$name/.mint-dev-config-managed"
    if [[ -e "$STORE/$name" || -L "$STORE/$name" ]]; then
        mv -T -- "$STORE/$name" "$stage/previous" || { rm -rf "$stage"; return 1; }
    fi
    if ! mv -T -- "$stage/$name" "$STORE/$name"; then
        mv -T -- "$stage/previous" "$STORE/$name" 2>/dev/null
        rm -rf "$stage"
        return 1
    fi
    rm -rf "$stage"
}

# True when an existing symlink was made by this installer or by an earlier
# installer of the same skill.
replaceable_link() {
    local target="$1" name="$2" raw root
    raw="$(readlink -- "$target")"
    [[ "$raw" == /* ]] || raw="$(dirname "$target")/$raw"
    [[ "$raw" == "$STORE/$name" || "$raw" == "$OLD_STORE/$name" ]] && return 0
    [[ "$(basename "$raw")" == "$name" ]] || return 1
    for root in "${OLD_LINK_ROOTS[@]}"; do
        [[ "$raw" == "$root"/* ]] && return 0
    done
    return 1
}

link_skill() {
    local name="$1" destination target
    for destination in "${DESTINATIONS[@]}"; do
        mkdir -p "$destination"
        target="$destination/$name"
        if [[ -L "$target" ]]; then
            if [[ "$(readlink -- "$target")" == "$STORE/$name" ]]; then
                continue
            fi
            if ! replaceable_link "$target" "$name"; then
                log skip "$target links to $(readlink -- "$target")"
                continue
            fi
            ln -s -- "$STORE/$name" "$target.mint-dev-config.$$"
            mv -T -- "$target.mint-dev-config.$$" "$target"
            log relink "$target"
        elif [[ -e "$target" ]]; then
            log skip "existing skill $target"
        else
            ln -s -- "$STORE/$name" "$target"
            log link "$target"
        fi
    done
}

# Pi and OMP discover ~/.agents/skills directly. Retire only our duplicate links.
retire_native_links() {
    local name="$1" directory target resolved
    for directory in "$HOME/.pi/agent/skills" "$HOME/.omp/agent/skills"; do
        target="$directory/$name"
        if [[ -L "$target" ]]; then
            resolved="$(readlink -m -- "$target")"
            if [[ "$resolved" == "$STORE/$name" || "$resolved" == "$OLD_STORE/$name" ]]; then
                rm -- "$target"
                log retired "$target"
            fi
        fi
        rmdir -- "$directory" 2>/dev/null || true
    done
}

failed=()
for row in "${rows[@]}"; do
    IFS=$'\t' read -r source subdir name <<<"$row"
    fallback="$FALLBACK_ROOT/$source/$name"
    chosen=""
    if [[ -n "${clone_dir[$source]:-}" ]]; then
        if usable_skill_dir "${clone_dir[$source]}/$subdir" "${clone_dir[$source]}"; then
            chosen="${clone_dir[$source]}/$subdir"
            log upstream "$name from ${source_url[$source]} $subdir"
        else
            warn missing "$name: upstream $subdir lacks SKILL.md or links outside the repository"
        fi
    fi
    if [[ -z "$chosen" ]]; then
        if usable_skill_dir "$fallback" "$fallback"; then
            chosen="$fallback"
            log fallback "$name from ${fallback#"$ROOT"/}"
        else
            warn error "$name: no upstream copy and bundled fallback missing at ${fallback#"$ROOT"/}"
            failed+=("$name")
            continue
        fi
    elif [[ ! -f "$fallback/SKILL.md" ]]; then
        warn warn "$name: bundled fallback missing at ${fallback#"$ROOT"/}"
    fi
    target="$STORE/$name"
    if [[ -e "$target" || -L "$target" ]]; then
        if [[ -L "$target" ]]; then
            if ! replaceable_link "$target" "$name"; then
                log skip "custom shared skill $target"
                continue
            fi
        elif [[ ! -f "$target/.mint-dev-config-managed" ]]; then
            log skip "custom shared skill $target"
            continue
        fi
    fi
    if ! materialize "$chosen" "$name"; then
        warn error "$name: could not copy $chosen into $STORE"
        failed+=("$name")
        continue
    fi
    link_skill "$name"
    retire_native_links "$name"
    rm -rf -- "$OLD_STORE/$name"
done
rmdir -- "$OLD_STORE" 2>/dev/null || true

if ((${#failed[@]})); then
    warn error "skills not installed: ${failed[*]}"
    exit 1
fi

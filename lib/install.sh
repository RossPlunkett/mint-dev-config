#!/usr/bin/env bash

setup_apt_repositories() {
    local arch codename
    arch="$(dpkg --print-architecture)"
    codename="$(. /etc/os-release; printf '%s' "${UBUNTU_CODENAME:-noble}")"

    sudo install -m 0755 -d /etc/apt/keyrings

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc >/dev/null
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu %s stable\n' "$arch" "$codename" |
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor --yes -o /etc/apt/keyrings/google-chrome.gpg
    printf 'deb [arch=%s signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main\n' "$arch" |
        sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null

    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg |
        sudo tee /etc/apt/keyrings/tailscale.gpg >/dev/null
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list |
        sudo tee /etc/apt/sources.list.d/tailscale.list >/dev/null
}

install_apt_packages() {
    mapfile -t packages < <(manifest_items "$ROOT/manifests/apt.txt")
    setup_apt_repositories
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"
    sudo usermod -aG docker "$USER"
}

install_flatpaks() {
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    while IFS= read -r app; do
        flatpak install --user --noninteractive flathub "$app"
    done < <(manifest_items "$ROOT/manifests/flatpak.txt")
}

install_homebrew() {
    if [[ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    mapfile -t formulae < <(manifest_items "$ROOT/manifests/brew.txt")
    brew install "${formulae[@]}"
}

install_node_tools() {
    if [[ ! -d "$HOME/.nvm/.git" ]]; then
        git clone https://github.com/nvm-sh/nvm.git "$HOME/.nvm"
    fi
    git -C "$HOME/.nvm" fetch --tags origin
    latest_nvm="$(git -C "$HOME/.nvm" tag --sort=-v:refname | head -1)"
    git -C "$HOME/.nvm" checkout --quiet "$latest_nvm"
    export NVM_DIR="$HOME/.nvm"
    source "$NVM_DIR/nvm.sh"
    nvm install 22
    nvm alias default 22
    nvm use 22
    npm install --global @anthropic-ai/claude-code @railway/cli
    curl -fsSL https://cli.coderabbit.ai/install.sh | sh
}

install_editor_and_skills() {
    if [[ -e "$HOME/.config/nvim" && ! -d "$HOME/.config/nvim/.git" ]]; then
        printf 'Refusing to replace non-Git Neovim config: %s\n' "$HOME/.config/nvim" >&2
        return 1
    fi
    if [[ ! -d "$HOME/.config/nvim/.git" ]]; then
        git clone https://github.com/RossPlunkett/nvim.git "$HOME/.config/nvim"
    elif [[ -n "$(git -C "$HOME/.config/nvim" status --porcelain)" ]]; then
        printf 'Leaving dirty Neovim checkout unchanged.\n'
    else
        git -C "$HOME/.config/nvim" pull --ff-only
    fi

    "$ROOT/scripts/install-matt-skills.sh"
    "$ROOT/scripts/install-t3code.sh"
    "$ROOT/scripts/install-fonts.sh"
}

clone_projects() {
    local group directory url destination root
    while IFS=$'\t' read -r group directory url; do
        [[ "$group" == \#* || -z "$group" ]] && continue
        case "$group" in
            ross) root="$HOME/dev/ross-o-fone" ;;
            karaoke) root="$HOME/dev/liquid-live-karaoke" ;;
            *) printf 'Unknown repository group: %s\n' "$group" >&2; return 1 ;;
        esac
        destination="$root/$directory"
        mkdir -p "$root"
        if [[ -d "$destination/.git" ]]; then
            printf 'exists  %s\n' "$destination"
        elif [[ -e "$destination" ]]; then
            printf 'Refusing to replace existing path: %s\n' "$destination" >&2
            return 1
        else
            git clone "$url" "$destination"
        fi
    done <"$ROOT/manifests/repositories.tsv"
}

build_projects() {
    local workspace lock directory
    for workspace in "$HOME/dev/ross-o-fone" "$HOME/dev/liquid-live-karaoke"; do
        [[ -d "$workspace" ]] || continue
        while IFS= read -r lock; do
            directory="$(dirname "$lock")"
            printf 'npm ci  %s\n' "$directory"
            (cd "$directory" && npm ci)
        done < <(find "$workspace" -maxdepth 4 -name package-lock.json -not -path '*/node_modules/*' -print | sort)
    done

    "$HOME/dev/ross-o-fone/csoundfreak/builddesktop.sh"
}

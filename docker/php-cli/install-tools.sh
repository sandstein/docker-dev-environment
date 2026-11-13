#!/bin/bash
#
# Installs the optional tools listed in DDE_CLI_TOOLS (see .env.sample).
#
#   install-tools.sh system   as root: neovim (with the tree-sitter CLI), lazygit
#   install-tools.sh user     as phpcli: nvm, nanocoder, claude, codex, junie
#
# phpcli has the host user's uid, so everything in its home behaves like on
# the host. claude, codex and junie come from their vendors' install scripts
# (~/.local/bin, ~/.local/share, ~/.codex); self-updates work until the
# container is recreated, a rebuild installs the then current version.
# nanocoder is installed with npm into nvm's default Node (DDE_CLI_NODE, it
# needs Node 22 or newer); after switching Node for a project, reinstall it
# with: npm install -g @nanocollective/nanocoder

set -euo pipefail

KNOWN=(nvm claude codex junie nanocoder neovim lazygit)
declare -A INSTALLERS=(
    [claude]="https://claude.ai/install.sh"
    [codex]="https://chatgpt.com/codex/install.sh"
    [junie]="https://junie.jetbrains.com/install.sh"
)

TOOLS=()
IFS=', ' read -r -a TOOLS <<< "${DDE_CLI_TOOLS:-}"

want() {
    local tool
    for tool in "${TOOLS[@]}"; do
        [[ "${tool}" == "$1" ]] && return 0
    done
    return 1
}

check_tools() {
    local tool known
    for tool in "${TOOLS[@]}"; do
        for known in "${KNOWN[@]}"; do
            [[ "${tool}" == "${known}" ]] && continue 2
        done
        echo "DDE_CLI_TOOLS: unknown tool '${tool}', known are: ${KNOWN[*]}" >&2
        exit 1
    done
    if want nanocoder && ! want nvm; then
        echo "DDE_CLI_TOOLS: nanocoder is installed with nvm's Node, add nvm" >&2
        exit 1
    fi
}

arch() {
    case "$(dpkg --print-architecture)" in
        amd64) echo x86_64 ;;
        arm64) echo arm64 ;;
        *) echo "unsupported architecture $(dpkg --print-architecture)" >&2; exit 1 ;;
    esac
}

ts_arch() {
    case "$(arch)" in
        x86_64) echo x64 ;;
        *) arch ;;
    esac
}

install_neovim() {
    want neovim || return 0
    local file
    file="nvim-linux-$(arch).tar.gz"
    curl -fsSLo "/tmp/${file}" \
        "https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/${file}"
    mkdir -p /opt/nvim
    tar -xzf "/tmp/${file}" -C /opt/nvim --strip-components=1
    rm "/tmp/${file}"
    ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
    # nvim-treesitter (main) builds its parsers with the tree-sitter CLI
    curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/download/v${TREE_SITTER_VERSION}/tree-sitter-linux-$(ts_arch).gz" \
        | gunzip > /usr/local/bin/tree-sitter
    chmod 755 /usr/local/bin/tree-sitter
}

install_lazygit() {
    want lazygit || return 0
    local url file
    url="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}"
    file="lazygit_${LAZYGIT_VERSION}_linux_$(arch).tar.gz"
    curl -fsSLo "/tmp/${file}" "${url}/${file}"
    (cd /tmp && curl -fsSL "${url}/checksums.txt" | grep " ${file}\$" | sha256sum -c --quiet -)
    tar -xzf "/tmp/${file}" -C /usr/local/bin lazygit
    rm "/tmp/${file}"
}

install_nvm() {
    want nvm || return 0
    mkdir -p "${NVM_DIR}"
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" \
        | PROFILE=/dev/null bash
    # shellcheck disable=SC1091
    . "${HOME}/.nvm/nvm.sh"
    nvm install "${DDE_CLI_NODE}"
    nvm alias default "${DDE_CLI_NODE}"
    # creates ~/.nvm/current (NVM_SYMLINK_CURRENT), which is on the image's PATH
    nvm use default
    if want nanocoder; then
        npm install --global --no-fund --no-audit @nanocollective/nanocoder
        npm cache clean --force 2> /dev/null
    fi
    nvm cache clear
}

install_agents() {
    local tool
    for tool in claude codex junie; do
        want "${tool}" || continue
        curl -fsSL "${INSTALLERS[${tool}]}" | CODEX_NON_INTERACTIVE=1 bash
    done
    rm -rf "${HOME}/.claude/downloads" "${HOME}/.cache"
}

write_bashrc() {
    # For the image's own .bashrc; dotfiles replace it with their own. The
    # PATH (~/.local/bin, ~/.nvm/current/bin) is set in the Dockerfile.
    if want nvm; then
        cat >> "${HOME}/.bashrc" <<'EOF'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
EOF
    fi
}

check_tools
case "${1:-}" in
    system) install_neovim; install_lazygit ;;
    user) install_nvm; install_agents; write_bashrc ;;
    *) echo "usage: $0 system|user" >&2; exit 1 ;;
esac

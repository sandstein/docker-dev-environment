#!/bin/bash
#
# Checks out the optional dotfiles (DDE_DOTFILES_CORE, DDE_DOTFILES_LOCAL, see
# .env.sample) into the home directory when the container starts for the first
# time, then runs the php image's own entrypoint.
#
# The repositories are cloned bare to ~/.cfg-core and ~/.cfg-local, like on the
# host, so `git --git-dir ~/.cfg-core --work-tree ~ ...` (alias `config`) works.
# Files below directories shared with the host (.ssh, .secrets) are not
# checked out: they already come from the host, and writing them would change
# the host's files. ~/.config is a directory of the container's own below
# config/<service>/home-config and survives a recreate; files there that equal
# the repository are kept, other existing files (such as the image's .bashrc)
# are moved to ~/.dotfiles-backup. A failure only warns, the container starts.

SHARED_WITH_HOST=(.ssh .secrets)

dotfiles_checkout() {
    local url="$1" name="$2" git_dir="${HOME}/.cfg-$2"
    local -a files=()
    local file shared

    [[ -n "${url}" && ! -d "${git_dir}" ]] || return 0
    cfg() { git --git-dir="${git_dir}" --work-tree="${HOME}" "$@"; }

    echo "dde: checking out dotfiles ${url} into ~/.cfg-${name}" >&2
    git clone --quiet --bare "${url}" "${git_dir}" || return 1
    cfg config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
    cfg config status.showUntrackedFiles no
    cfg fetch --quiet origin
    cfg branch --quiet --set-upstream-to="origin/$(cfg symbolic-ref --short HEAD)" || true

    while IFS= read -r file; do
        for shared in "${SHARED_WITH_HOST[@]}"; do
            [[ "${file}" == "${shared}"/* ]] && continue 2
        done
        files+=("${file}")
    done < <(cfg ls-tree -r --name-only HEAD)

    for file in "${files[@]}"; do
        [[ -e "${HOME}/${file}" || -L "${HOME}/${file}" ]] || continue
        if [[ ! -L "${HOME}/${file}" && -f "${HOME}/${file}" ]] \
            && cfg cat-file blob "HEAD:${file}" | cmp -s - "${HOME}/${file}"; then
            continue
        fi
        mkdir -p "${HOME}/.dotfiles-backup/$(dirname "${file}")"
        mv "${HOME}/${file}" "${HOME}/.dotfiles-backup/${file}"
    done
    cfg read-tree HEAD
    ((${#files[@]})) && cfg checkout-index --force -- "${files[@]}"
    # git expands the tilde itself, as on the host
    # shellcheck disable=SC2088
    cfg config core.excludesFile "~/.config/dotfiles/${3}.allow"
}

if [[ -n "${DDE_DOTFILES_CORE:-}${DDE_DOTFILES_LOCAL:-}" ]]; then
    dotfiles_checkout "${DDE_DOTFILES_CORE:-}" core core \
        || echo "dde: could not check out ${DDE_DOTFILES_CORE}" >&2
    dotfiles_checkout "${DDE_DOTFILES_LOCAL:-}" local local \
        || echo "dde: could not check out ${DDE_DOTFILES_LOCAL}" >&2
fi

exec docker-php-entrypoint "$@"

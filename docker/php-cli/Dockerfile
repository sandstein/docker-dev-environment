# base image (always tagged) per version, see services.yml
ARG BASE_IMAGE
# hadolint ignore=DL3006
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG USER_ID=1000
ARG GROUP_ID=1000
RUN chown phpcli:phpcli /home/phpcli/.[a-zA-Z]* \
    && modify-user-ids phpcli ${USER_ID} ${GROUP_ID}

# Optional tools (DDE_CLI_TOOLS and DDE_CLI_NODE in .env), pinned versions
ARG DDE_CLI_TOOLS=""
ARG DDE_CLI_NODE="lts/*"
ARG NVM_VERSION=0.41.0
ARG NEOVIM_VERSION=0.12.6
ARG LAZYGIT_VERSION=0.66.3
ARG TREE_SITTER_VERSION=0.27.2
# Tools work in every command, not only in interactive shells: `composer global`
# tools, the agents' ~/.local/bin and nvm's active Node (~/.nvm/current, kept
# up to date by nvm use because of NVM_SYMLINK_CURRENT)
ENV NVM_DIR=/home/phpcli/.nvm \
    NVM_SYMLINK_CURRENT=true \
    PATH="/home/phpcli/bin:/home/phpcli/.composer/vendor/bin:/home/phpcli/.local/bin:/home/phpcli/.nvm/current/bin:$PATH"
COPY install-tools.sh /usr/local/lib/dde/install-tools.sh
RUN /usr/local/lib/dde/install-tools.sh system
USER phpcli
RUN /usr/local/lib/dde/install-tools.sh user

# Optional dotfiles (DDE_DOTFILES_CORE and DDE_DOTFILES_LOCAL in .env),
# checked out when the container starts
COPY entrypoint.sh /usr/local/bin/dde-cli-entrypoint
ENTRYPOINT ["dde-cli-entrypoint"]
CMD ["php", "-a"]

EXPOSE 8082

VOLUME /usr/local/etc/php /home/phpcli/bin

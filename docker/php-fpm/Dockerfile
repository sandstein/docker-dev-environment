# base image (always tagged) per version, see services.yml
ARG BASE_IMAGE
# hadolint ignore=DL3006
FROM ${BASE_IMAGE}

ARG USER_ID=33
ARG GROUP_ID=33
RUN modify-user-ids www-data ${USER_ID} ${GROUP_ID}

VOLUME /usr/local/etc/php

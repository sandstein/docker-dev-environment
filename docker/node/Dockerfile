# base image (always tagged) per version, see services.yml
ARG BASE_IMAGE
# hadolint ignore=DL3006
FROM ${BASE_IMAGE}

ARG USER_ID=1000
ARG GROUP_ID=1000
RUN modify-user-ids node ${USER_ID} ${GROUP_ID}

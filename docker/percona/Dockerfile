# base image (always tagged) per version, see services.yml
ARG BASE_IMAGE
# hadolint ignore=DL3006
FROM ${BASE_IMAGE}

ARG USER_ID=999
ARG GROUP_ID=999
USER root
RUN modify-user-ids mysql ${USER_ID} ${GROUP_ID}
USER mysql

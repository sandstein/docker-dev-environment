# base image (always tagged) per version, see services.yml
ARG BASE_IMAGE
# hadolint ignore=DL3006
FROM ${BASE_IMAGE}

RUN bin/opensearch-plugin install analysis-phonetic

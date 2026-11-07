# base image (always tagged) per version, see services.yml
ARG BASE_IMAGE
# hadolint ignore=DL3006
FROM ${BASE_IMAGE}

ARG USER_ID=1000
ARG GROUP_ID=1000
RUN modify-user-ids elasticsearch ${USER_ID} ${GROUP_ID} \
    && modify-elasticsearch-entrypoint

RUN bin/elasticsearch-plugin install analysis-phonetic \
    && bin/elasticsearch-plugin install analysis-icu


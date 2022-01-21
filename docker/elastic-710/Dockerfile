FROM sandstein/elasticsearch:7.10

ARG USER_ID=1000
ARG GROUP_ID=1000
RUN modify-user-ids elasticsearch ${USER_ID} ${GROUP_ID} \
    && modify-elasticsearch-entrypoint

RUN bin/elasticsearch-plugin install analysis-phonetic \
    && bin/elasticsearch-plugin install analysis-icu


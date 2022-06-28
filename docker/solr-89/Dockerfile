FROM sandstein/solr:8.9

ARG USER_ID=1000
ARG GROUP_ID=1000
RUN modify-user-ids solr ${USER_ID} ${GROUP_ID} \
    mkdir /opt/solr/lib \
    chown -R solr.solr /opt/solr \
    chown -R solr.solr /opt/docker-solr

USER solr

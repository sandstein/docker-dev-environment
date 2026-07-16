#!/bin/bash
sudo "/usr/share/opensearch/plugins/opensearch-security/tools/securityadmin.sh" -cd "/usr/share/opensearch/config/opensearch-security" -icl -key "/usr/share/opensearch/config/kirk-key.pem" -cert "/usr/share/opensearch/config/kirk.pem" -cacert "/usr/share/opensearch/config/root-ca.pem" -nhnv

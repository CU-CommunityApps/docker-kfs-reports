FROM docker.cucloud.net/apache22

ENV PATH /infra/oracle/instantclient_12_1/:$PATH
ENV NLS_LANG AMERICAN_AMERICA.UTF8
ENV ORACLE_HOME /infra/oracle/instantclient_12_1/
ENV LD_LIBRARY_PATH $ORACLE_HOME:$LD_LIBRARY_PATH

RUN apt-get update \
    && apt-get install -y perl \
      libapache2-mod-perl2 \
      libaio1 \
      cpanminus \
    && rm -fr /var/lib/apt/lists/*

# Setup oracle dependenciues
ADD deps/oracle.tar.gz /infra/

# update per modules
RUN cpanm --self-upgrade && \
  cpanm install \
    YAML \
    DBI DBD::Oracle

COPY bin/start-apache.sh /opt/start-apache.sh

#setup puppet stuff
COPY keys/id_rsa /root/.ssh/id_rsa
COPY known_hosts /root/.ssh/known_hosts
COPY Puppetfile /

# Run puppet config
RUN librarian-puppet install && \
  puppet apply --modulepath=/modules -e "class { 'kuali::kfs-reports': }" && \
  rm -rf /modules && \
  rm -rf /root/.ssh

COPY scripts /infra/kfs-reports/scripts

EXPOSE 80
EXPOSE 443

CMD ["/opt/start-apache.sh"]

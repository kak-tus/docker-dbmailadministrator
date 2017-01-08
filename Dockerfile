FROM alpine:3.4

COPY consul-template_0.16.0_SHA256SUMS /usr/local/bin/consul-template_0.16.0_SHA256SUMS
COPY DBMA_SQL_V3_SHA256SUMS /var/www/DBMA_SQL_V3_SHA256SUMS

RUN \
  apk add --update-cache curl unzip apache2 apache2-utils perl perl-cgi \
  perl-dbd-pg perl-dbd-mysql perl-digest-md5 \

  && cd /usr/local/bin \
  && curl -L https://releases.hashicorp.com/consul-template/0.16.0/consul-template_0.16.0_linux_amd64.zip -o consul-template_0.16.0_linux_amd64.zip \
  && sha256sum -c consul-template_0.16.0_SHA256SUMS \
  && unzip consul-template_0.16.0_linux_amd64.zip \
  && rm consul-template_0.16.0_linux_amd64.zip consul-template_0.16.0_SHA256SUMS \

  && cd /var/www \
  && curl -L http://dbma.ca/DBMA_SQL_V3.tar -o DBMA_SQL_V3.tar \
  && sha256sum -c DBMA_SQL_V3_SHA256SUMS \
  && tar -xvf DBMA_SQL_V3.tar \
  && rm -rf DBMA_SQL_V3.tar \
  && chmod 755 /var/www/dbmailadministrator/*.cgi \

  && mkdir -p /run/apache2 \
  && mkdir -p /var/log/apache \
  && ln -sf /proc/1/fd/1 /var/log/apache2/access.log \
  && ln -sf /proc/1/fd/2 /var/log/apache2/error.log \

  && apk del curl unzip && rm -rf /var/cache/apk/*

ENV CONSUL_HTTP_ADDR=
ENV CONSUL_TOKEN=
ENV VAULT_ADDR=
ENV VAULT_TOKEN=

COPY service.conf /etc/apache2/conf.d/service.conf
COPY apache.hcl /etc/apache.hcl
COPY DBMA_CONFIG.DB.template /root/DBMA_CONFIG.DB.template

CMD consul-template -config /etc/apache.hcl

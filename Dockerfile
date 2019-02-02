FROM alpine:3.9 AS build

ENV \
  CONSUL_TEMPLATE_VERSION=0.19.5 \
  CONSUL_TEMPLATE_SHA256=e6b376701708b901b0548490e296739aedd1c19423c386eb0b01cfad152162af \
  \
  RTTFIX_VERSION=0.1 \
  RTTFIX_SHA256=349b309c8b4ba0afe3acf7a0b0173f9e68fffc0f93bad4b3087735bd094dea0d \
  \
  DBMA_VERSION=3.0.2 \
  DBMA_SHA256=9cf1389d49557ff368241b2a6f197729e3a447c819acdaa82eba05154a57f1b5

RUN \
  apk add --no-cache \
    curl \
    unzip \
  \
  && cd /usr/local/bin \
  && curl -L https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip -o consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip \
  && echo -n "$CONSUL_TEMPLATE_SHA256  consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip" | sha256sum -c - \
  && unzip consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip \
  && rm consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip \
  \
  && cd /usr/local/bin \
  && curl -L https://github.com/kak-tus/rttfix/releases/download/$RTTFIX_VERSION/rttfix -o rttfix \
  && echo -n "$RTTFIX_SHA256  rttfix" | sha256sum -c - \
  && chmod +x rttfix \
  \
  && mkdir -p /var/www \
  && cd /var/www \
  && curl -L https://github.com/kak-tus/dbmailadministrator/archive/v${DBMA_VERSION}.zip -o DBMA_SQL_V${DBMA_VERSION}.zip \
  && echo -n "$DBMA_SHA256  DBMA_SQL_V${DBMA_VERSION}.zip" | sha256sum -c - \
  && unzip DBMA_SQL_V${DBMA_VERSION}.zip \
  && mv dbmailadministrator-${DBMA_VERSION} dbmailadministrator \
  && rm -rf DBMA_SQL_V${DBMA_VERSION}.zip \
  && chmod 755 /var/www/dbmailadministrator/*.cgi

FROM alpine:3.9

COPY --from=build /var/www/dbmailadministrator /var/www/dbmailadministrator

RUN \
  apk add --no-cache \
    apache2 \
    apache2-ctl \
    apache2-utils \
    perl \
    perl-cgi \
    perl-dbd-mysql \
    perl-dbd-pg \
    perl-digest-md5 \
  \
  && mkdir -p /run/apache2 \
  && mkdir -p /var/log/apache \
  && ln -sf /proc/1/fd/1 /var/log/apache2/access.log \
  && ln -sf /proc/1/fd/2 /var/log/apache2/error.log \
  && chown -R apache:apache /var/www/dbmailadministrator

ENV \
  CONSUL_HTTP_ADDR= \
  CONSUL_TOKEN= \
  VAULT_ADDR= \
  VAULT_TOKEN=

COPY service.conf /etc/apache2/conf.d/service.conf
COPY templates /root/templates
COPY --from=build /usr/local/bin/consul-template /usr/local/bin/consul-template
COPY --from=build /usr/local/bin/rttfix /usr/local/bin/rttfix

CMD ["/usr/local/bin/consul-template", "-config", "/root/templates/service.hcl"]

FROM alpine:3.9 AS build

ENV \
  CONSUL_TEMPLATE_VERSION=0.19.5 \
  CONSUL_TEMPLATE_SHA256=e6b376701708b901b0548490e296739aedd1c19423c386eb0b01cfad152162af \
  \
  RTTFIX_VERSION=0.1 \
  RTTFIX_SHA256=349b309c8b4ba0afe3acf7a0b0173f9e68fffc0f93bad4b3087735bd094dea0d \
  \
  DBMA_VERSION=3 \
  DBMA_SHA256=629172c54ff00d4a2cb2f4f250f93373d31eba995f601794abe5894731fca09d

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
  && curl -L http://dbma.ca/DBMA_SQL_V${DBMA_VERSION}.tar -o DBMA_SQL_V${DBMA_VERSION}.tar \
  && echo -n "$DBMA_SHA256  DBMA_SQL_V${DBMA_VERSION}.tar" | sha256sum -c - \
  && tar -xvf DBMA_SQL_V${DBMA_VERSION}.tar \
  && rm -rf DBMA_SQL_V${DBMA_VERSION}.tar \
  && chmod 755 /var/www/dbmailadministrator/*.cgi

FROM alpine:3.9

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
  && ln -sf /proc/1/fd/2 /var/log/apache2/error.log

ENV \
  CONSUL_HTTP_ADDR= \
  CONSUL_TOKEN= \
  VAULT_ADDR= \
  VAULT_TOKEN=

COPY service.conf /etc/apache2/conf.d/service.conf
COPY templates /root/templates
COPY --from=build /usr/local/bin/consul-template /usr/local/bin/consul-template
COPY --from=build /usr/local/bin/rttfix /usr/local/bin/rttfix
COPY --from=build /var/www/dbmailadministrator /var/www/dbmailadministrator

CMD ["/usr/local/bin/consul-template", "-config", "/root/templates/service.hcl"]

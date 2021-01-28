FROM alpine:3.13

COPY *.sh /usr/local/bin/

RUN apk --no-cache add curl bash \
  && chmod +x /usr/local/bin/*.sh

ENTRYPOINT ["docker-entrypoint.sh"]

FROM alpine:20240329
RUN apk add --no-cache \
  perl-xml-twig=3.52-r5
WORKDIR /app
COPY rules_pfsense.pl rules_pfsense.pl
RUN chmod +x rules_pfsense.pl && mkdir /app/mnt
ENTRYPOINT ["/app/rules_pfsense.pl"]

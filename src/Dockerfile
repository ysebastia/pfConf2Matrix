FROM alpine:3.15.0
RUN apk add --no-cache perl-xml-twig
WORKDIR /app
COPY rules_pfsense.pl rules_pfsense.pl
RUN chmod +x rules_pfsense.pl && mkdir /app/mnt
ENTRYPOINT ["/app/rules_pfsense.pl"]
FROM caddy:2.11-builder-alpine AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/he

FROM caddy:2.11-alpine

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

FROM caddy:2.10-builder-alpine AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/he

FROM caddy:2.10-alpine

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

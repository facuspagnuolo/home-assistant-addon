FROM debian:bookworm-slim AS downloader

ARG BUILD_ARCH

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates curl unzip \
    && rm -rf /var/lib/apt/lists/*

RUN case "${BUILD_ARCH}" in \
        amd64) \
            asset="rathole-x86_64-unknown-linux-gnu.zip"; \
            checksum="3e7d0d0f365120cd3cd351d147d1a12ee960c8068b464d4dd533a3821873b80e" \
            ;; \
        aarch64) \
            asset="rathole-aarch64-unknown-linux-musl.zip"; \
            checksum="fa4a6fc63d86f8f1faa7c103a845e4715ce79a048455c0eec897b27237576564" \
            ;; \
        *) \
            echo "Unsupported architecture: ${BUILD_ARCH}" >&2; \
            exit 1 \
            ;; \
    esac \
    && curl --fail --location --silent --show-error \
        --output /tmp/rathole.zip \
        "https://github.com/rathole-org/rathole/releases/download/v0.5.0/${asset}" \
    && echo "${checksum}  /tmp/rathole.zip" | sha256sum --check --strict \
    && unzip /tmp/rathole.zip -d /out \
    && chmod 0755 /out/rathole

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates curl iproute2 jq \
    && rm -rf /var/lib/apt/lists/*

COPY --from=downloader /out/rathole /usr/local/bin/rathole
COPY run.sh /run.sh

RUN chmod 0755 /run.sh

CMD ["/run.sh"]

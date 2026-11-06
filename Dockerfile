# syntax=docker/dockerfile:1

# Sonarr v4 on the shared Alpine base, rootless from the first process.
# Upstream ships a self-contained .NET build (runtime inside the tarball), so
# the image only adds the native libraries that runtime loads.
FROM ghcr.io/rake-pro/alpine-base:1.0@sha256:f62113d237739786f9b4419271e4625f509374576b50c8cb8ea4fc882952d168 AS fetch
ARG VERSION="4.0.20.3014"
ARG BRANCH="main"
RUN apk add --no-cache curl \
    && mkdir -p /out/bin \
    && curl -fsSL -o /tmp/app.tgz \
        "https://services.sonarr.tv/v1/update/${BRANCH}/download?version=${VERSION}&os=linuxmusl&runtime=netcore&arch=x64" \
    && tar -xzf /tmp/app.tgz -C /out/bin --strip-components=1 \
    && rm -rf /out/bin/Sonarr.Update /tmp/app.tgz \
    && printf 'UpdateMethod=docker\nBranch=%s\nPackageVersion=%s\nPackageAuthor=[Rake-Pro](https://github.com/Rake-Pro)\n' "${BRANCH}" "${VERSION}" > /out/package_info \
    && chmod -R u=rwX,go=rX /out

FROM ghcr.io/rake-pro/alpine-base:1.0@sha256:f62113d237739786f9b4419271e4625f509374576b50c8cb8ea4fc882952d168
ARG VERSION
LABEL org.opencontainers.image.source="https://github.com/Rake-Pro/sonarr" \
      org.opencontainers.image.version="${VERSION}"

# PGGSSENCMODE: krb5 on musl is not thread-safe and Npgsql's GSS probe
# segfaults on it (exit 139) when a PostgreSQL backend is configured.
ENV HOME="/config" \
    DOTNET_EnableDiagnostics=0 \
    PGGSSENCMODE=disable \
    SONARR__UPDATE__BRANCH=main

RUN apk add --no-cache \
        icu-libs \
        krb5-libs \
        libintl \
        sqlite-libs

COPY --from=fetch /out /app
COPY --chmod=0755 entrypoint.sh /entrypoint.sh

USER 65534:65534
WORKDIR /config
VOLUME ["/config"]
EXPOSE 8989

ENTRYPOINT ["/usr/bin/catatonit", "--", "/entrypoint.sh"]

ARG DEBIAN_VERSION=13.6

FROM docker.io/gautada/debian:$DEBIAN_VERSION as BUILD

# hadolint ignore=DL3008
RUN apt-get update \
 && apt-get upgrade --yes \
 && apt-get install --yes --no-install-recommends \
            make git go \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* 
# Cloudflare Tunnel client: https://github.com/cloudflare/cloudflared
ARG GITHUB_TAG=2026.8.3
WORKDIR /opt
RUN git clone --branch ${GITHUB_TAG} https://github.com/cloudflare/cloudflared
WORKDIR /opt/cloudflared
RUN make cloudflared

FROM docker.io/gautada/debian:$DEBIAN_VERSION as CONTAINER

ARG IMAGE_NAME=cloudflared

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL org.opencontainers.image.title="${IMAGE_NAME}"
LABEL org.opencontainers.image.description="A cloudflared access point"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/gautada/cloudflared"
LABEL org.opencontainers.image.source="https://github.com/gautada/cloudflared"
LABEL org.opencontainers.image.version="${IMAGE_VERSION}"
LABEL org.opencontainers.image.license="Upstream"

# ╭――――――――――――――――――――╮
# │ USER               │
# ╰――――――――――――――――――――╯
ARG OLDUSER=debian
ARG USER=cloudflared
RUN /usr/sbin/usermod -l $USER $OLDUSER \
 && /usr/sbin/usermod -d /home/$USER -m $USER \
 && /usr/sbin/groupmod -n $USER $OLDUSER \
 && PASSWORD="$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 24)" \
 && printf '%s:%s\n' "$USER" "$PASSWORD" | /usr/sbin/chpasswd


# ╭――――――――――――――――――――╮
# │ CONTAINER          │
# ╰――――――――――――――――――――╯
RUN mkdir -p /home/${USER}/.cloudflared \
 && ln -fsv /mnt/volumes/secrets/cert.pem /home/${USER}/.cloudflared/cert.pem
COPY --from=BUILD /opt/cloudflared/cloudflared /usr/sbin/cloudflared
COPY etc/services.d/cloudflared/run /etc/services.d/cloudflared/run
COPY usr/bin/container-version /usr/bin/container-version
RUN chown ${USER}:${USER} -R /home/${USER} 
WORKDIR /home/$USER

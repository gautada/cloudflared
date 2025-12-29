ARG ALPINE_VERSION=3.22

FROM docker.io/gautada/alpine:$ALPINE_VERSION as BUILD
 
ARG GITHUB_TAG=2025.11.1
WORKDIR /opt
RUN git clone --branch ${GITHUB_TAG} https://github.com/cloudflare/cloudflared
WORKDIR /opt/cloudflared
RUN apk add --no-cache make go \
 && make cloudflared

FROM docker.io/gautada/alpine:$ALPINE_VERSION as CONTAINER

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
ARG USER=cloudflared
RUN /usr/sbin/usermod -l $USER alpine \
&& /usr/sbin/usermod -d /home/$USER -m $USER \ 
&& /usr/sbin/groupmod -n $USER alpine \
&& /bin/echo "$USER:$USER" | /usr/sbin/chpasswd 

# ╭――――――――――――――――――――╮
# │ CONTAINER          │
# ╰――――――――――――――――――――╯

RUN mkdir -p /home/${USER}/.cloudflared \
 && ln -fsv /mnt/volumes/secrets/cert.pem /home/${USER}/.cloudflared/cert.pem
COPY --from=BUILD /opt/cloudflared/cloudflared /usr/sbin/cloudflared
COPY cloudflared.s6 /etc/services.d/cloudflared/run
# COPY cert.pem /home/${USER}/.cloudflared/cert.pem
RUN chown ${USER}:${USER} -R /home/${USER} 
WORKDIR /home/$USER

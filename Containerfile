ARG ALPINE_VERSION=3.22
FROM docker.io/gautada/alpine:$ALPINE_VERSION as CONTAINER

ARG IMAGE_NAME=cloudflared
ARG IMAGE_VERSION=0.11.5
ARG PACKAGE_VERSION=r0

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
# │ BACKUP             │
# ╰――――――――――――――――――――╯
# COPY backup /etc/container/backup

# ╭――――――――――――――――――――╮
# │ ENTRYPOINT         │
# ╰――――――――――――――――――――╯
# Overwrite upstream entrypoint
# COPY entrypoint.sh /usr/bin/container-entrypoint

# ╭――――――――――――――――――――╮
# │ PRIVILEGES         │
# ╰――――――――――――――――――――╯
# COPY privileges /etc/container/privileges

# ╭――――――――――――――――――――╮
# │ APPLICATION        │
# ╰――――――――――――――――――――╯
COPY cloudflared-run /etc/services.d/cloudflared/run
RUN /bin/sed -i 's|dl-cdn.alpinelinux.org/alpine/|mirror.math.princeton.edu/pub/alpinelinux/|g' /etc/apk/repositories \
 && /sbin/apk add --no-cache cloudflared \
 && chmod +x /etc/services.d/cloudflared/run

# ╭――――――――――――――――――――╮
# │ CONTAINER          │
# ╰――――――――――――――――――――╯
# USER $USER
VOLUME /mnt/volumes/backup
VOLUME /mnt/volumes/configmaps
VOLUME /mnt/volumes/data
VOLUME /mnt/volumes/secrets
EXPOSE 6074/tcp
WORKDIR /home/$USER

ENTRYPOINT ["/usr/bin/s6-svscan", "/etc/services.d"]

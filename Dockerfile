# Build xrdp from UBUNTU 24.04 LTS
# See functions of the file: init.sh

ARG TAG=noble
FROM ubuntu:$TAG

ENV DEBIAN_FRONTEND noninteractive
ENV DISPLAY ${DISPLAY:-:1}

RUN apt update \
 && apt -y upgrade \
 && apt -y install --no-install-recommends -o APT::Immediate-Configure=0 \
        ca-certificates \
        dbus-x11 \
        locales \
        x11-utils \
        x11-xserver-utils \
        xauth \
        xdg-utils \        
        xorgxrdp \
        xrdp \
 && apt clean

## Tor Browser
RUN apt install torbrowser-launcher
 && apt clean

# Optional utilities
RUN apt -y install --no-install-recommends -o APT::Immediate-Configure=0 \
        apt-utils \
        curl \
        sudo \
 && apt clean

# Create a new user and add to the sudo group:
ENV USERNAME=ubuntu
ARG PASSWORD=vnc
ARG USER_UID=1001
ARG USER_GID=1001
ARG USER_INIT_CONFIG_DIR=/opt/default-config
ENV LANG=en_US.UTF-8
RUN useradd -ms /bin/bash --home-dir /home/${USERNAME} ${USERNAME} \
 && echo "${USERNAME}:${PASSWORD}" | chpasswd \
 && usermod -aG sudo,xrdp ${USERNAME} \
 && locale-gen en_US.UTF-8
.
# Create a start script:
ENV entry=/usr/bin/entrypoint
RUN cat <<EOF > /usr/bin/entrypoint
#!/bin/bash -v
  test -d $USER_INIT_CONFIG_DIR && {
    cp -r $USER_INIT_CONFIG_DIR/. /home/${USERNAME}
    rm -r $USER_INIT_CONFIG_DIR
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}
  }
  service dbus start
  service xrdp start
  tail -f /dev/null
EOF
RUN chmod +x /usr/bin/entrypoint

EXPOSE 3389/tcp
ENTRYPOINT ["/usr/bin/entrypoint"]

FROM steamcmd/steamcmd:debian-12
LABEL maintainer="git@luxusburg.lu"

ARG DEBIAN_FRONTEND="noninteractive"

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y  \
        apt-utils \
        software-properties-common \
        tzdata \
        wget \
        cron && \        
    apt-get autoremove --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Setting timezone
RUN ln -snf /usr/share/zoneinfo/${TZ:-'Europe/Berlin'} /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# Setting up cron file for backup
ADD ./files/foundry-cron /etc/cron.d/foundry-cron
    chmod 0644 /etc/cron.d/foundry-cron && \
    crontab /etc/cron.d/foundry-cron && \
    cron

# Install wine
RUN mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources && \
    apt-get update && \
    apt-get install -y --install-recommends winehq-stable

# Install xvfb
RUN apt-get install -y xserver-xorg \
                   xvfb

# Clean up
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*  && \    
    apt-get clean && \
    apt-get autoremove -y

# Create user foundry and home directory
RUN groupadd -g "${PGID:-1000}" -o foundry && \
    useradd -g "${PGID:-1000}" -u "${PGUID:-1000}" -o --create-home foundry


# Copy batch files and give execute rights
WORKDIR /home/foundry
ADD ./files ./scripts
RUN chmod +x ./scripts/*.sh && \
    chown foundry:foundry ./scripts/*

ENTRYPOINT ["/bin/bash", "/home/foundry/scripts/entrypoint.sh"]
CMD ["/home/foundry/scripts/start.sh"]

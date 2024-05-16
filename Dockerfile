FROM ubuntu:22.04 
LABEL maintainer="Git@Luxusburg"

ARG DEBIAN_FRONTEND="noninteractive"

RUN apt update -y && \
    apt-get upgrade -y && \
    apt-get install -y  apt-utils && \
    apt-get install -y  software-properties-common \
                        tzdata \
                        locales \
                        cron && \
    add-apt-repository multiverse && \
    dpkg --add-architecture i386 && \
    apt update -y && \
    apt-get upgrade -y 

# Local for steamcmd
RUN locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en

# Setting timezone
RUN ln -snf /usr/share/zoneinfo/${TZ:-'Europe/Berlin'} /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# Setting up cron file for backup
COPY ./files/foundry-cron /etc/cron.d/foundry-cron
RUN chmod 0644 /etc/cron.d/foundry-cron && \
    crontab /etc/cron.d/foundry-cron && \
    cron

# Install steamcmd and create user
RUN useradd -m foundry && cd /home/foundry && \
    echo steam steam/question select "I AGREE" | debconf-set-selections && \
    echo steam steam/license note '' | debconf-set-selections && \
    apt purge steam steamcmd && \
    apt install -y gdebi-core  \
                   libgl1-mesa-glx:i386 \
                   wget && \
    apt install -y steam \
                   steamcmd && \
    ln -s /usr/games/steamcmd /usr/bin/steamcmd

# Install wine
RUN apt install -y wine \
                   winbind

# Install xvfb
RUN apt install -y xserver-xorg \
                   xvfb

# Clean up
RUN rm -rf /var/lib/apt/lists/* && \
    apt clean && \
    apt autoremove -y

# Copy batch files and give execute rights
WORKDIR /home/foundry
ADD ./files ./scripts

RUN chmod +x ./scripts/*.sh
RUN chown foundry:foundry ./scripts/*

ENTRYPOINT ["/bin/bash", "/home/foundry/scripts/entrypoint.sh"]
CMD ["/home/foundry/scripts/start.sh"]

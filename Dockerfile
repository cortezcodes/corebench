FROM ubuntu:22.04

###########
# 
# Installs CoREBench + Desktop environment
# Based on Dockerfile from Roberto H. Hashioka (git://github.com/rogaha/docker-desktop.git)
#
###########

MAINTAINER Marcel Boehme <marcel.boehme@acm.org>

RUN \
    apt-get update  \
        --quiet     \
    && apt-get upgrade -y

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME /root

# RUN apt-mark hold initscripts udev plymouth mountall
# RUN dpkg-divert --local --rename --add /sbin/initctl && ln -sf /bin/true /sbin/initctl
# RUN sed -i "/^# deb.*multiverse/ s/^# //" /etc/apt/sources.list

RUN \
  apt-get install \
        --yes       \
        --no-install-recommends \
        --no-install-suggests \
    autoconf        \
    autogen         \
    autopoint       \
    automake        \
    bison           \
    clang           \
    cvs             \
    gettext         \
    gcc             \
    git             \
    gnuplot         \
    gperf           \
    gzip            \
    lcov            \
    libtool         \
    make            \
    nasm            \
    patch           \
    perl            \
    rsync           \
    tar             \
    texinfo         \
    subversion      \
    unzip           \
    vim             \
    wget            \
    curl
 
 RUN apt-get install \
        --yes       \
        --no-install-recommends \
        --no-install-suggests \
    supervisor      \
    python-dev-is-python3 build-essential \
    openssh-server sudo net-tools \
    lxde-core lxde-icon-theme x11vnc xvfb screen openbox nodejs firefox \
    htop bmon nano lxterminal

#    firefox lxde-core lxterminal tightvncserver
#    firefox lxde-core lxterminal tightvncserver
#    ubuntu-desktop xorg lxde-core lxde-icon-theme x11vnc xvfb \
#    pwgen sudo net-tools openssh-server tightvncserver \
#    gtk2-engines-murrine ttf-ubuntu-font-family nano \
#    language-pack-zh-hant language-pack-gnome-zh-hant firefox-locale-zh-hant \
#    nginx \
#    python-pip python-dev build-essential

RUN apt-get clean   \
  && rm -rf /var/lib/apt/lists/*


WORKDIR /root

ENV SHELL /bin/bash

#Install Haskell and cabal for crucible
# Install dependencies *You don't need all of them
RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y git jq bc make automake libnuma-dev \
    && apt-get install -y rsync htop curl build-essential \
    && apt-get install -y pkg-config libffi-dev libgmp-dev \
    && apt-get install -y libssl-dev libtinfo-dev libsystemd-dev \
    && apt-get install -y zlib1g-dev make g++ wget libncursesw5 libtool autoconf \
    && apt-get clean

# Install ghcup
ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=1
RUN bash -c "curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh"
RUN bash -c "curl -sSL https://get.haskellstack.org/ | sh"

# Add ghcup to PATH
ENV PATH=${PATH}:/root/.local/bin
ENV PATH=${PATH}:/root/.ghcup/bin

# Install cabal
RUN bash -c "ghcup upgrade"
RUN bash -c "ghcup install cabal 3.4.0.0"
RUN bash -c "ghcup set cabal 3.4.0.0"

# Install GHC
RUN bash -c "ghcup install ghc 8.10.4"
RUN bash -c "ghcup set ghc 8.10.4"

# Update Path to include Cabal and GHC exports
RUN bash -c "echo PATH="$HOME/.local/bin:$PATH" >> $HOME/.bashrc"
RUN bash -c "echo export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH" >> $HOME/.bashrc"
RUN bash -c "source $HOME/.bashrc"

#Install Rust for build-bom
RUN curl -y --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Download crucible
RUN git clone https://github.com/GaloisInc/crucible.git 

# Download build-bom
RUN git clone https://github.com/travitch/build-bom.git

#Install Crucible
WORKDIR /root/crucible
RUN git submodule update --init
RUN cabal update \
 && cabal new-configure \
 && cabal new-build all

#Install build-bom \
WORKDIR /root/build-bom
RUN cargo build

WORKDIR /root

#FIX problem with aclocal and pkg-config
ENV ACLOCAL_PATH /usr/share/aclocal
RUN \
  wget http://pkgconfig.freedesktop.org/releases/pkg-config-0.28.tar.gz >/dev/null 2>&1 \
  && tar -zxvf pkg-config-0.28.tar.gz >/dev/null 2>&1\
  && cd pkg-config-0.28 \
  && ./configure --with-internal-glib >/dev/null 2>&1 && make >/dev/null 2>&1 && make install >/dev/null 2>&1
#FIX problem with aclocal
#RUN cp /usr/local/share/aclocal/* /usr/share/aclocal && mv /usr/local/share/aclocal /tmp

#RUN \ 
#     locale-gen en_US.UTF-8 \
  # && locale-gen ru_RU.KOI8-R\
  # && locale-gen tr_TR.UTF-8 \
  # && locale-gen ja_JP.UTF-8 \
  # && locale-gen en_HK.UTF-8 \
  # && locale-gen zh_CN       \
  # && localedef -i ja_JP -c -f SHIFT_JIS /usr/lib/locale/ja_JP.sjis

#Attempt to make as much progress as possible
WORKDIR /root
#RUN \
#  wget --no-check-certificate https://github.com/mboehme/corebench/archive/master.zip \
#  && unzip master.zip \
#  && cp corebench-master/corebench.tar.gz . \
#  && cp corebench-master/startup.sh / \
#  && cp corebench-master/supervisord.conf / \
#  && cp corebench-master/password.txt / \
#  && rm -rf corebench-master

ENV SHELL /bin/bash

COPY corebench.tar.gz /root
RUN \
  tar -zxvf corebench.tar.gz >/dev/null 2>&1 \
  && mkdir corerepo
WORKDIR /root/corebench
RUN ./createCoREBench.sh compile-all make /root/corerepo
RUN ./createCoREBench.sh compile-all grep /root/corerepo
RUN ./createCoREBench.sh compile-all find /root/corerepo

# #Now fail if any problems
RUN ./createCoREBench.sh compile make /root/corerepo
RUN ./createCoREBench.sh compile grep /root/corerepo
RUN ./createCoREBench.sh compile find /root/corerepo
RUN ./executeTests.sh test-all make /root/corerepo
RUN ./executeTests.sh test-all grep /root/corerepo
RUN ./executeTests.sh test-all find /root/corerepo

## Installing coreutils will deplete the 10GB limit imposed by Docker
RUN ./createCoREBench.sh compile-all core /root/corerepo
RUN ./createCoREBench.sh compile core /root/corerepo
RUN ./executeTests.sh test-all core /root/corerepo

ADD startup.sh /
ADD supervisord.conf /
ADD password.txt /

EXPOSE 5800
EXPOSE 5900
EXPOSE 22

WORKDIR /
ENTRYPOINT ["/startup.sh"]
# Base image: Ubuntu 18.04 (Bionic Beaver)
FROM ubuntu:18.04

# Prevent interactive prompts
ARG DEBIAN_FRONTEND=noninteractive

# 1. Install Buildroot dependencies + sudo (for the ubuntu user)
RUN apt-get update && apt-get install -y \
    build-essential \
    bash \
    bc \
    binutils \
    bzip2 \
    cpio \
    file \
    g++ \
    gcc \
    git \
    gzip \
    locales \
    libncurses5-dev \
    libssl-dev \
    make \
    ncurses-dev \
    patch \
    perl \
    python \
    python3 \
    rsync \
    sed \
    sudo \
    tar \
    unzip \
    wget \
    vim \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    libguestfs-tools \
    && rm -rf /var/lib/apt/lists/*    

# 2. Configure Locales for Taiwan (zh_TW)
RUN locale-gen zh_TW.UTF-8
ENV LANG=zh_TW.UTF-8 \
    LANGUAGE=zh_TW:zh \
    LC_ALL=zh_TW.UTF-8

# 3. Create user 'ubuntu' with password 'ubuntu'
# -m: Create home directory
# -s: Set shell to bash
# -G: Add to sudo group
RUN useradd -m -s /bin/bash -G sudo ubuntu && \
    echo 'ubuntu:ubuntu' | chpasswd

# 4. Switch to the new user
USER ubuntu
WORKDIR /home/ubuntu

# Default command
CMD ["/bin/bash"]
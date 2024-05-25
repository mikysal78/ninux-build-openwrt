FROM debian

RUN apt-get update
RUN apt-get install -y \
        sudo ccache time git-core subversion build-essential g++ bash make \
        libssl-dev patch libncurses5 libncurses5-dev zlib1g-dev gawk \
        flex gettext wget unzip xz-utils \
        python3 python3-distutils-extra rsync curl libsnmp-dev liblzma-dev \
        libpam0g-dev cpio rsync
RUN wget https://github.com/cli/cli/releases/download/v2.49.2/gh_2.49.2_linux_amd64.deb && \
    apt-get install -f ./gh_2.49.2_linux_amd64.deb && apt-get clean
RUN wget https://github.com/github-release/github-release/releases/download/v0.9.0/linux-amd64-github-release.bz2 -O- | bzip2 -d > /usr/local/bin/github-release && chmod +x /usr/local/bin/github-release

RUN useradd -m user && echo 'user ALL=NOPASSWD: ALL' > /etc/sudoers.d/user

USER user
WORKDIR /home/user

# set dummy git config
RUN git config --global user.name "user" && git config --global user.email "user@example.com"

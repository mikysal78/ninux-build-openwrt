FROM debian:bullseye

RUN apt-get update &&\
    apt-get install -y \
        sudo ccache time git-core subversion build-essential g++ bash make \
        libssl-dev patch libncurses5 libncurses5-dev zlib1g-dev gawk flex \
        gettext wget unzip xz-utils python3 python3-distutils-extra rsync curl \
        gcc-multilib libsnmp-dev liblzma-dev libpam0g-dev cpio rsync && \
    apt-get clean && \
    useradd -m user && \
    echo 'user ALL=NOPASSWD: ALL' > /etc/sudoers.d/user

USER user
WORKDIR /home/user

# set dummy git config
RUN git config --global user.name "user" && git config --global user.email "user@example.com"

#!/bin/bash

apt install snapd -y
snap refresh
snap install core
snap install lxd
snap refresh
lxd init

/etc/default/grub
GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=false"

update-grub2




CONTAINER_NAME=jenkins

lxc info ${CONTAINER_NAME} &> /dev/null || {
    lxc launch images:ubuntu/xenial/amd64 ${CONTAINER_NAME}
    sleep 5 # Wait network DHCP
    lxc exec ${CONTAINER_NAME} -- bash << EOF
        apt-get update
        apt-get install -y apt-transport-https wget ca-certificates curl openjdk-11-jre
	curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
	echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
        apt-get update
        # Add OpenWRT Prerequisites
        apt-get install -y git-core build-essential libssl-dev libncurses5-dev unzip gawk subversion mercurial gettext
        # Add github-release
        wget https://github.com/github-release/github-release/releases/download/v0.9.0/linux-amd64-github-release.bz2 -O- | bzip2 -d > /usr/local/bin/github-release && chmod +x /usr/local/bin/github-release
        # Install Jenkins
        apt-get install -y jenkins
        sleep 5
        wget -q http://127.0.0.1:8080
        echo "InitialAdminPassword:"
        cat /var/lib/jenkins/secrets/initialAdminPassword
EOF
}

lxc list ${CONTAINER_NAME} -c s | grep STOPPED &> /dev/null && lxc start ${CONTAINER_NAME}

#lxc exec ${CONTAINER_NAME} -- sudo -u ubuntu -i

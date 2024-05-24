#!/bin/bash

# curl -fsSL https://raw.githubusercontent.com/gscafo78/Dockers/main/install_docker.sh?token=GHSAT0AAAAAACSJ5YWXHAUEVCZD7JLP7TFAZSHCLVA | bash


# Check if /etc/os-release exists
if [ -f /etc/os-release ]; then
    # Source the file to get the OS details
    . /etc/os-release

    # Check the ID and ID_LIKE to print the corresponding OS
    case "$ID" in
        ubuntu)
            echo "The operating system is Ubuntu."
            so="ubuntu"
            package_manager="apt"
            ;;
        debian)
            echo "The operating system is Debian."
            so="debian"
            package_manager="apt"
            ;;
        centos|rhel|fedora)
            echo "The operating system is CentOS/RHEL/Fedora."
            so="centos"
            package_manager="yum"
            ;;
        *)
            # Check ID_LIKE for more information if ID is not sufficient
            case "$ID_LIKE" in
                debian)
                    echo "The operating system is Debian-based."
                    so="debian"
                    package_manager="apt"
                    ;;
                rhel|fedora)
                    echo "The operating system is RHEL-based."
                    so="centos"
                    package_manager="yum"
                    ;;
                *)
                    echo "The operating system is not recognized."
                    exit 1
                    ;;
            esac
            ;;
    esac
else
    echo "/etc/os-release file not found. Unable to determine the operating system."
    exit 1
fi

# Remove any existing Docker-related packages (for apt systems)
if [ "$package_manager" == "apt" ]; then
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        apt remove -y $pkg
    done

    # Add Docker's official GPG key and setup the repository for apt systems
    apt update
    apt install -y ca-certificates curl gnupg lsb-release

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/${so}/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${so} \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

# Install Docker on CentOS/RHEL/Fedora
if [ "$package_manager" == "yum" ]; then
    yum remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

    yum install -y yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    systemctl start docker
    systemctl enable docker
fi

# Verify Docker installation
docker --version
#!/usr/bin/env bash

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

if [ "$package_manager" == "apt" ]; then
    apt update
    apt upgrade -y
    apt install -y curl
fi

if [ "$package_manager" == "yum" ]; then
    yum update -y
    yum install -y curl
fi

# Ensure the .ssh directory exists with correct permissions
 mkdir -p /root/.ssh
 chmod 700 /root/.ssh

# Ensure the authorized_keys file exists with correct permissions
 touch /root/.ssh/authorized_keys
 chmod 600 /root/.ssh/authorized_keys

# Download the file, visualize, and append its contents to authorized_keys
curl -fsSL https://raw.githubusercontent.com/gscafo78/Dockers/main/id_ed25519.pub?token=GHSAT0AAAAAACSJ5YWXJXVZ2GJIGYU2AD4QZSHDW4Q |  tee -a /root/.ssh/authorized_keys

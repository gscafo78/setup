# wget -qO- https://raw.githubusercontent.com/gscafo78/setup/main/inizialsetup/setup.sh
# bash setup.sh

#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
#  Check that the script is run as root
# -------------------------------------------------------------------
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ This script must be run as root."
  exit 1
fi

# -------------------------------------------------------------------
#  Function: Initial system setup
# -------------------------------------------------------------------
initial_setup() {
  echo
  echo "=== INITIAL SETUP ==="
  echo

  # Detect OS
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$ID
    PRETTY_NAME=${PRETTY_NAME:-$ID}
  else
    echo "❌ Unable to detect the operating system."
    exit 1
  fi
  echo "✅ Detected operating system: $PRETTY_NAME"

  # Configure package manager & sudo group
  case "$OS" in
    debian|ubuntu)
      PKG_UPDATE="apt update -y"
      PKG_INSTALL="apt install -y"
      SUDO_GROUP="sudo"
      PACKAGES="figlet fastfetch sudo vim tcpdump locate bash-completion"
      ;;
    centos|rhel|rocky|almalinux|fedora)
      if command -v dnf &>/dev/null; then
        PKG_UPDATE="dnf -y update"
        PKG_INSTALL="dnf install -y"
      else
        PKG_UPDATE="yum -y update"
        PKG_INSTALL="yum install -y"
      fi
      SUDO_GROUP="wheel"
      PACKAGES="figlet neofetch sudo vim tcpdump mlocate bash-completion"
      ;;
    *)
      echo "❌ Unsupported operating system: $OS"
      exit 1
      ;;
  esac

  # Install SSH key for root
  mkdir -p /root/.ssh
  chmod 700 /root/.ssh
  echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMX8jtJJ0jHEQ9p3wf2jHjwnmK5aSMd3rNPM1ZN7Eyye Scafo' \
    | tee /root/.ssh/authorized_keys >/dev/null
  chmod 600 /root/.ssh/authorized_keys

  # Update package lists and install base packages
  echo "📦 Updating packages..."
  $PKG_UPDATE
  echo "📦 Installing packages: $PACKAGES"
  $PKG_INSTALL $PACKAGES

  # Deploy a custom MOTD banner
  tee /etc/update-motd.d/01-custom >/dev/null <<'EOF'
#!/bin/sh
echo "GENERAL SYSTEM INFORMATION\n"
/usr/bin/figlet $(hostname) 2>/dev/null 
/usr/bin/fastfetch
echo
echo
echo " ******************************************************************"
echo " * WARNING: Unauthorized access to this system is prohibited.     *"
echo " * All activities on this system are logged.                      *"
echo " * By accessing this system, you consent to monitoring.           *"
echo " * Unauthorized access will be prosecuted to the fullest extent   *"
echo " * of the law.                                                    *"
echo " ******************************************************************"
echo
EOF
  chmod +x /etc/update-motd.d/01-custom

  # Find the first real user (UID 1000)
  USER_1000=$(getent passwd 1000 | cut -d: -f1)
  if [[ -z "$USER_1000" ]]; then
    echo "❌ No user with UID 1000 found."
    exit 1
  fi
  echo "✅ User with UID 1000 found: $USER_1000"

  # Ensure the user is in the sudo/wheel group
  if id -nG "$USER_1000" | grep -qw "$SUDO_GROUP"; then
    echo "ℹ️  User $USER_1000 is already in group $SUDO_GROUP."
  else
    echo "➕ Adding $USER_1000 to group $SUDO_GROUP..."
    usermod -aG "$SUDO_GROUP" "$USER_1000"
    echo "✅ User added to group $SUDO_GROUP."
  fi

  # Deploy .bashrc and .bash_aliases for root and the user
  for TARGET in /root /home/"$USER_1000"; do
    cat > "$TARGET/.bashrc" <<'EOF'
# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Avoid duplicate lines or lines starting with space in the history
HISTCONTROL=ignoreboth
# Append to the history file, don't overwrite it
shopt -s histappend
# Set history size
HISTSIZE=1000
HISTFILESIZE=2000
# Check window size after each command and update LINES and COLUMNS
shopt -s checkwinsize

# Make less more friendly for non-text input files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Set a fancy prompt (color, if the terminal has the capability)
force_color_prompt=yes
if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi
if [ "$color_prompt" = yes ]; then
    PS1="\[\033[38;5;8m\][\[$(tput sgr0)\]\[\033[38;5;1m\]\u\[$(tput sgr0)\]\[\033[38;5;6m\]@\[$(tput sgr0)\]\[\033[38;5;4m\]\h\[$(tput sgr0)\]\[\033[38;5;6m\]:\[$(tput sgr0)\]\[\033[38;5;5m\]\w\[$(tput sgr0)\]\[\033[38;5;8m\]]\[$(tput sgr0)\]\[\033[38;5;1m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# Enable color support for ls and grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Set vim as the default editor
export EDITOR=vim
# Add local bin directory to PATH
export PATH="$HOME/.local/bin:$PATH"

# Enable colorful man pages
export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

# Add any custom functions or additional configurations below this line
EOF

    cat > "$TARGET/.bash_aliases" <<'EOF'
alias rmdir='rm -Rf'
alias update='apt update && apt upgrade -y && apt autoremove -y'
alias install='apt update && apt install -y'
alias remove='apt remove -y'

alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

# Docker shortcuts
alias dc='docker compose'
alias de='docker exec'
alias dv='docker volume'
alias dw='watch -n 2 "docker ps --format \"table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.Status}}\""'
alias dcw='watch -n 2 "docker compose ps --format \"table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.Status}}\""'
EOF

    chown "$USER_1000":"$USER_1000" "$TARGET/.bashrc" "$TARGET/.bash_aliases" || true
  done

  passwd -l root
  echo "🔒 Password di root disabilitata (account bloccato)."

  echo
  echo "✅ Initial setup completed successfully!"
  echo
}

# -------------------------------------------------------------------
#  Function: Install Docker
# -------------------------------------------------------------------
install_docker() {
  echo
  echo "=== INSTALL DOCKER ==="
  echo

  # Detect OS and package manager
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$ID
    IDL=${ID_LIKE:-""}
  else
    echo "❌ /etc/os-release not found, cannot determine OS."
    exit 1
  fi

  # Choose apt vs yum/dnf
  if [[ "$OS" =~ ubuntu|debian ]] || [[ "$IDL" =~ debian ]]; then
    pkg_mgr="apt"
  elif [[ "$OS" =~ centos|rhel|fedora ]] || [[ "$IDL" =~ rhel|fedora ]]; then
    pkg_mgr="yum"
  else
    echo "❌ Unrecognized OS for Docker installation."
    exit 1
  fi

  if [[ "$pkg_mgr" == "apt" ]]; then
    apt remove -y docker.io docker-doc docker-compose podman-docker containerd runc || true
    apt update
    apt install -y ca-certificates curl gnupg lsb-release

    install -m0755 -d /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/$OS/gpg" \
      | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/$OS \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      | tee /etc/apt/sources.list.d/docker.list >/dev/null

    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  else
    yum remove -y docker docker-client docker-client-latest docker-common \
                  docker-latest docker-latest-logrotate docker-logrotate docker-engine || true
    yum install -y yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl start docker
    systemctl enable docker
  fi

  echo
  echo "✅ Docker installed successfully. Version:"
  docker --version
  echo
}

# -------------------------------------------------------------------
#  MAIN MENU
# -------------------------------------------------------------------
PS3=$'\n''Select what you want to install: '
options=(
  "🔧 All‑in‑one (Initial Setup + Docker)"
  "⚙️  Only Initial Setup"
  "🐳 Only Docker"
  "🚪 Exit"
)
select choice in "${options[@]}"; do
  case $REPLY in
    1)
      initial_setup
      install_docker
      break
      ;;
    2)
      initial_setup
      break
      ;;
    3)
      install_docker
      break
      ;;
    4)
      echo "Bye!"
      exit 0
      ;;
    *)
      echo "⚠️ Invalid choice, please try again."
      ;;
  esac
done

echo "🎉 Operation completed."

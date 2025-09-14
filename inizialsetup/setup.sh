#!/bin/bash

# Installare chiave SSH per root (ATTENZIONE: sovrascrive!)
mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMX8jtJJ0jHEQ9p3wf2jHjwnmK5aSMd3rNPM1ZN7Eyye Scafo' | tee /root/.ssh/authorized_keys > /dev/null
chmod 600 /root/.ssh/authorized_keys

# Installare figlet e fastfetch
apt update
apt install -y figlet fastfetch sudo vim tcpdump locate bash-completion

# Creare custom motd
tee /etc/update-motd.d/01-custom > /dev/null << 'EOF'
#!/bin/sh
echo "GENERAL SYSTEM INFORMATION\n"
/usr/bin/figlet $(hostname)
echo
/usr/bin/fastfetch
echo
echo
echo " ******************************************************************"
echo " _WARNING: Unauthorized access to this system is prohibited._     "
echo " _All activities on this system are logged._                      "
echo " _By accessing this system, you consent to monitoring._           "
echo " _Unauthorized access will be prosecuted to the fullest extent_   "
echo " _of the law._                                                    "
echo " ******************************************************************"
echo
EOF
chmod +x /etc/update-motd.d/01-custom

# Sovrascrive ~/.bashrc e ~/.bash_aliases dell'utente che esegue lo script
# Attenzione: se esegui da root cambi la bash root, da utente cambi quella dell’utente
cat > ~/.bashrc << 'EOF'
# ~/.bashrc

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Don't put duplicate lines or lines starting with space in the history
HISTCONTROL=ignoreboth

# Append to the history file, don't overwrite it
shopt -s histappend

# Set history length
HISTSIZE=1000
HISTFILESIZE=2000

# Check window size after each command and update LINES and COLUMNS if necessary
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

cat > ~/.bash_aliases << 'EOF'
alias rmdir='rm -Rf'
alias update='apt update && apt upgrade -y && apt autoremove -y'
alias install='apt update && apt install -y'
alias remove='apt remove -y'

# Add an "alert" alias for long running commands
alias alert='echo "$(date): Command $(history | tail -n1 | sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'') finished with status $?" >> ~/command_alerts.log'

alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

#git commands
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

#docker compose
alias dc='docker compose'
alias de='docker exec'
alias dv='docker volume'
alias dw='watch -n 2 "docker ps --format \"table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.Status}}\""'
alias dcw='watch -n 2 "docker compose ps --format \"table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.Status}}\""'
EOF

# Controllo se esiste un utente con UID 1000
USER_1000=$(getent passwd 1000 | cut -d: -f1)

if [ -z "$USER_1000" ]; then
    echo "❌ Nessun utente con UID 1000 trovato."
    exit 1
fi

echo "✅ Utente con UID 1000 trovato: $USER_1000"

# Controllo se è nel gruppo sudo
if id -nG "$USER_1000" | grep -qw "sudo"; then
    echo "ℹ️  L'utente $USER_1000 è già sudo."
else
    echo "➕ Aggiungo $USER_1000 al gruppo sudo..."
    usermod -aG sudo "$USER_1000"
    if [ $? -eq 0 ]; then
        echo "✅ L'utente $USER_1000 è stato aggiunto al gruppo sudo."
    else
        echo "❌ Errore durante l'aggiunta al gruppo sudo."
        exit 1
    fi
fi



cat > /home/$USER_1000/.bashrc << 'EOF'
# ~/.bashrc

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Don't put duplicate lines or lines starting with space in the history
HISTCONTROL=ignoreboth

# Append to the history file, don't overwrite it
shopt -s histappend

# Set history length
HISTSIZE=1000
HISTFILESIZE=2000

# Check window size after each command and update LINES and COLUMNS if necessary
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
    PS1="\[\033[38;5;8m\][\[$(tput sgr0)\]\[\033[38;5;2m\]\u\[$(tput sgr0)\]\[\033[38;5;6m\]@\[$(tput sgr0)\]\[\033[38;5;4m\]\h\[$(tput sgr0)\]\[\033[38;5;6m\]:\[$(tput sgr0)\]\[\033[38;5;5m\]\w\[$(tput sgr0)\]\[\033[38;5;8m\]]\[$(tput sgr0)\]\[\033[38;5;1m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"
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


cat > /home/$USER_1000/.bash_aliases << 'EOF'
alias rmdir='rm -Rf'
alias update='apt update && apt upgrade -y && apt autoremove -y'
alias install='apt update && apt install -y'
alias remove='apt remove -y'

# Add an "alert" alias for long running commands
alias alert='echo "$(date): Command $(history | tail -n1 | sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'') finished with status $?" >> ~/command_alerts.log'

alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

#git commands
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

#docker compose
alias dc='docker compose'
alias de='docker exec'
alias dv='docker volume'
alias dw='watch -n 2 "docker ps --format \"table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.Status}}\""'
alias dcw='watch -n 2 "docker compose ps --format \"table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.Status}}\""'
EOF

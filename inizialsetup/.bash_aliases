alias rmdir='rm -Rf'
alias update='apt update && apt upgrade -y && apt autoremove -y'
alias install='apt update && apt install -y'

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
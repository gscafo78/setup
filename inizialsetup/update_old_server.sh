#!/bin/bash

apt update && apt upgrade -y && apt install figlet neofetch -y

rm -f /etc/motd

uname -snrvm > /var/run/motd.dynamic
# systemctl disable motd

#apt install --reinstall update-motd -y
rm -Rf /etc/update-motd.d/*

cat <<EOF > /etc/update-motd.d/01-custom
#!/bin/bash
GENERAL SYSTEM INFORMATION

/usr/bin/figlet \$(hostname)

/usr/bin/neofetch

echo "---------------------------------------------------"
echo "|  Server Responsible: Ufficio CybInt - Sez. ATSC |"
echo "|  Contact Number: 2028825                        |"
echo "---------------------------------------------------"
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

mkdir -p  /.config/neofetch/

cat << EOF > /.config/neofetch/config.conf
print_info() {
    info title
    info underline
    info "OS" distro
    info "Host" model
    info "Kernel" kernel
    info "Uptime" uptime
    info "Packages" packages
    info "Shell" shell
    info "Resolution" resolution
    info "DE" de
    info "WM" wm
    info "WM Theme" wm_theme
    info "Theme" theme
    info "Icons" icons
    info "Terminal" term
    info "Terminal Font" term_font
    info "CPU" cpu
    info "GPU" gpu
    info "Memory" memory
    info "Disk" disk
    info "Local IP" local_ip
    info "Public IP" public_ip
    info cols
}

title_fqdn="off"
kernel_shorthand="on"
distro_shorthand="off"
os_arch="on"
uptime_shorthand="on"
memory_percent="off"
memory_unit="mib"
package_managers="on"
shell_path="off"
shell_version="on"
speed_type="bios_limit"
speed_shorthand="off"
cpu_brand="on"
cpu_speed="on"
cpu_cores="logical"
cpu_temp="off"
gpu_brand="on"
gpu_type="all"
refresh_rate="off"
gtk_shorthand="off"
gtk2="on"
gtk3="on"
public_ip_host="http://ident.me"
public_ip_timeout=2
de_version="on"
disk_show=('/')
disk_subtitle="mount"
disk_percent="on"
music_player="auto"
song_format="%artist% - %album% - %title%"
song_shorthand="off"
mpc_args=()
colors=(distro)
bold="on"
underline_enabled="on"
underline_char="-"
separator=":"
block_range=(0 15)
color_blocks="on"
block_width=3
block_height=1
col_offset="auto"
bar_char_elapsed="-"
bar_char_total="="
bar_border="on"
bar_length=15
bar_color_elapsed="distro"
bar_color_total="distro"
cpu_display="off"
memory_display="off"
battery_display="off"
disk_display="off"
image_backend="ascii"
image_source="auto"
ascii_distro="auto"
ascii_colors=(distro)
ascii_bold="on"
image_loop="off"
thumbnail_dir="\${XDG_CACHE_HOME:-\${HOME}/.cache}/thumbnails/neofetch"
crop_mode="normal"
crop_offset="center"
image_size="auto"
gap=3
yoffset=0
xoffset=0
background_color=
stdout="off"
EOF

cat << EOF > /root/.bashrc
# ~/.bashrc

# If not running interactively, don't do anything
case \$- in
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
[ -x /usr/bin/lesspipe ] && eval "\$(SHELL=/bin/sh lesspipe)"

# Set a fancy prompt (color, if the terminal has the capability)
force_color_prompt=yes

if [ -n "\$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "\$color_prompt" = yes ]; then
    PS1="\[\033[38;5;8m\][\[\$(tput sgr0)\]\[\033[38;5;1m\]\u\[\$(tput sgr0)\]\[\033[38;5;6m\]@\[\$(tput sgr0)\]\[\033[38;5;4m\]\h\[\$(tput sgr0)\]\[\033[38;5;6m\]:\[\$(tput sgr0)\]\[\033[38;5;5m\]\w\[\$(tput sgr0)\]\[\033[38;5;8m\]]\[\$(tput sgr0)\]\[\033[38;5;1m\]\\\$\[\$(tput sgr0)\]\[\033[38;5;15m\] \[\$(tput sgr0)\]"
else
    PS1='\${debian_chroot:+(\$debian_chroot)}\u@\h:\w\\$ '
fi
unset color_prompt force_color_prompt

# Enable color support for ls and grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "\$(dircolors -b ~/.dircolors)" || eval "\$(dircolors -b)"
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
export PATH="\$HOME/.local/bin:\$PATH"

# Enable colorful man pages
export LESS_TERMCAP_mb=\$'\E[1;31m'     # begin blink
export LESS_TERMCAP_md=\$'\E[1;36m'     # begin bold
export LESS_TERMCAP_me=\$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=\$'\E[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=\$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=\$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=\$'\E[0m'        # reset underline

# Add any custom functions or additional configurations below this line
EOF

cat << EOF > /root/.bash_aliases
alias rmdir='rm -Rf'
alias update='apt update && apt upgrade -y && apt autoremove -y'
alias install='apt update && apt install -y'

# Add an "alert" alias for long running commands
alias alert='echo "\$(date): Command \$(history | tail -n1 | sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert\$//'\'') finished with status \$?" >> ~/command_alerts.log'

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
EOF
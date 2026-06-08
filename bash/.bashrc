#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

[[ $(tty) == "/dev/tty1" ]] && {
    read -r -p "Start Hyprland? [Y/n] " answer
    [[ "$answer" =~ ^[Nn]([Oo])?$ ]] || start-hyprland
}

orphan() {
    setsid -f "$@" </dev/null >/dev/null 2>&1 &
    disown "$!" 2>/dev/null || true
}

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias d='du -hs -t 1G {.*,*} | sort -hr'
alias restart-waybar='killall waybar; orphan waybar'
alias colab='docker run --network host --gpus=all -p 127.0.0.1:9000:8080 \
    us-docker.pkg.dev/colab-images/public/runtime'
alias ffmpeg='ffmpeg -hide_banner'
alias ffprobe='ffprobe -hide_banner'

# ===== BEGIN create prompt =====
ps1_c() { printf '\[\e[%sm\]' "$1"; }

make_ps1() {
    local top1="$(ps1_c $2)\u@\h"
    local top2="$(ps1_c $3)\w"
    local top="$(ps1_c $1)┌──(${top1}$(ps1_c $1))─[${top2}$(ps1_c $1)]"
    local bot="$(ps1_c $1)└─\$ "
    PS1="\n$top\n${bot}$(ps1_c 0)"
}

make_ps1 34 32 33

unset -f ps1_c make_ps1
# ===== END create prompt ======

recent() {
    ls -t | head -n ${1:-1}
}

alias mpv-recent="recent | xargs -d '\n' mpv"

export EDITOR=nvim
export VISUAL=nvim

alias icat='kitty +kitten icat'
alias diff='kitty +kitten diff'
alias alpine='kitten ssh jawa5671@login.rc.colorado.edu'

# >>> juliaup initialize >>>

# !! Contents within this block are managed by juliaup !!

case ":$PATH:" in
    *:/home/jackson/.juliaup/bin:*)
        ;;

    *)
        export PATH=/home/jackson/.juliaup/bin${PATH:+:${PATH}}
        ;;
esac
# Tab completion for juliaup and julia channel selection
[ -f "/home/jackson/.julia/juliaup/completions/bash.sh" ] && source "/home/jackson/.julia/juliaup/completions/bash.sh"

# <<< juliaup initialize <<<

export PATH="$PATH:$HOME/.local/bin:/opt/cuda/bin:$HOME/.julia/bin"

export JULIA_NUM_THREADS=24

# >>> nnn >>>
export NNN_OPTS="denH"
export LC_COLLATE="C"
export NNN_FIFO=/tmp/nnn.fifo
export NNN_PLUG='p:preview-tui;'

function n {
    # Block nesting of nnn in subshells
    [ "${NNNLVL:-0}" -eq 0 ] || {
        echo "nnn is already running"
        return
    }

    # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
    # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to
    # see. To cd on quit only on ^G, remove the "export" and make sure not to
    # use a custom path, i.e. set NNN_TMPFILE *exactly* as follows:
    NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    # export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

    # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
    # stty start undef
    # stty stop undef
    # stty lwrap undef
    # stty lnext undef

    # The command builtin allows one to alias nnn to n, if desired, without
    # making an infinitely recursive alias
    command nnn "$@"

    [ ! -f "$NNN_TMPFILE" ] || {
        . "$NNN_TMPFILE"
        rm -f -- "$NNN_TMPFILE" > /dev/null
    }
}

alias nnn='nnn -P p'
alias n='n -P p'

# <<< nnn <<<

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

export MPD_HOST="$XDG_RUNTIME_DIR/mpd/socket"

[[ $COLUMNS -ge 120 ]] && fastfetch --logo-position left
[[ $COLUMNS -lt 120 ]] && fastfetch --logo none


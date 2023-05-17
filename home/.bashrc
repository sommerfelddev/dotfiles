# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples
case $- in
    *i*) stty -ixon
        ;;
      *) return
          ;;
esac

# shellcheck source=/dev/null
[ -r  ~/.config/sh/shinit ] && . ~/.config/sh/shinit

safesource /usr/share/git/completion/git-prompt.sh

PS1="\[\033[38;1;32m\]\u\[$(tput sgr0)\]\[\033[38;1;37m\]@\[$(tput sgr0)\]\[\033[38;1;36m\]\h\[$(tput sgr0)\]\[\033[38;1;37m\]:\[$(tput sgr0)\]\[\033[38;0;33m\]\w\[$(tput sgr0)\]$(__git_ps1 " (%s)")[\[\033[38;0;31m\]\$?\[$(tput sgr0)\]]\$ "
export PS1


HISTFILE="$XDG_CACHE_HOME"/bash_history
# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=50000
HISTFILESIZE=50000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    safesource /usr/share/bash-completion/bash_completion
fi

shopt -s autocd

bind '"\eh": "\C-a\eb\ed\C-y\e#man \C-y\C-m\C-p\C-p\C-a\C-d\C-e"'

safesource /usr/share/bash-completion/completions/fzf || safesource /usr/share/fzf/completion.bash
safesource /etc/profile.d/fzf.bash || safesource /usr/share/fzf/key-bindings.bash

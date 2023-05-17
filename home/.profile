# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# shellcheck source=/dev/null
[ -r  ~/.config/sh/envrc ] && . ~/.config/sh/envrc

if [ ! "$DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    ifexists sx
fi

if [ "$BASH" ]; then
    safesource ~/.bashrc
elif [ "$ZSH_VERSION" ]; then
    safesource "$XDG_CONFIG_HOME"/zsh/.zshrc
else
    safesource "$XDG_CONFIG_HOME"/sh/shinit
fi

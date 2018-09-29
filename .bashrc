#!/usr/bin/env bash
# ====================[ .bashrc                           ]====================
#
# --------------------( LICENSE                           )--------------------
# Copyright 2008-2018 by Cecil Curry.
# See "LICENSE" for further details.
#
# --------------------( SYNOPSIS                          )--------------------
# User-specific "bash" startup script for non-login shells.

# ....................{ INTERACTIVE                       }....................
# If the current shell is non-interactive, silently reduce to a noop.
case $- in
    *i*) ;;
      *) return;;
esac
# Else, the current shell is interactive. In this case, configure us up.

# ....................{ GLOBALS                           }....................
# User-specific ":"-delimited list of the absolute paths of all directories to
# find commands in. 
PATH="${PATH}:${HOME}/bash:${HOME}/perl"

# ....................{ GLOBALS ~ history                 }....................
# Avoid appending both duplicate lines and space-prefixed lines to the history.
HISTCONTROL=ignoreboth

# Append rather than overwrite the history file.
shopt -s histappend

# Maximum number of commands preserved by this file.
HISTSIZE=1000

# Maximum filesize in kilobytes of this file.
HISTFILESIZE=2000

# ....................{ OPTIONS                           }....................
# Implicitly update the ${LINES} and ${COLUMNS} environment variables after
# each input command to reflect the current dimensions of the parent graphical
# terminal hosting this interactive shell.
shopt -s checkwinsize

# Recursively expand the "**" pattern in pathname expansions to all files and
# subdirectories of the given directory (defaulting to the current directory).
shopt -s globstar

# Change to directories in command position (i.e., specified as the first shell
# word of a given command).
shopt -s autocd

# Emulate Vi[m] modality on reading keyboard input.
set -o vi

# ....................{ PROMPT                            }....................
# If the "tput" command exists *AND* reports that the current shell supports
# color, assume this to mean that this shell complies with Ecma-48
# (i.e., ISO/IEC-6429).
if hash tput >&/dev/null && tput setaf 1 >&/dev/null; then
    IS_COLOR=yes
else
    IS_COLOR=
fi

# String identifying the current chroot if any *OR* undefined otherwise.
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    DEBIAN_CHROOT=$(cat /etc/debian_chroot)
fi

if [ "${IS_COLOR}" == yes ]; then
    PS1='${DEBIAN_CHROOT:+($DEBIAN_CHROOT)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${DEBIAN_CHROOT:+($DEBIAN_CHROOT)}\u@\h:\w\$ '
fi

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# ....................{ COLOUR                            }....................
# Enable colour support for all relevant "coreutils" commands.
if [ -x /usr/bin/dircolors ]; then
    # If a user-specific ".dircolors" dotfile exists, replace the current
    # "dircolors" configuration (if any) with that specified by this file.
    [ -r ~/.dircolors ] &&
        eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"

    # Colour "ls" output and all derivatives thereof.
    LS_OPTIONS='--all --color=auto --group-directories-first --human-readable'
    alias ls="ls ${LS_OPTIONS}"
    alias dir="dir ${LS_OPTIONS}"
    alias vdir="vdir ${LS_OPTIONS}"

    # Colour "grep" output and all derivatives thereof.
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Colour GCC warnings and errors.
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# ....................{ ALIASES                           }....................
# One-letter aliases for brave brevity.
alias d='date'
alias f='fg'
alias l='ls -CF'
alias m='mv'
alias v='vim'

# Two-letter aliases for great justice.
alias cm='chmod'
alias co='chown'
alias cp='cp -i'
alias gr='grep -R'
alias ll='ls -alF'
alias lr='ll -R'
alias md='mkdir'
alias mv='mv -i'
alias rd='rmdir'
alias rm='rm -i'

# Three-letter aliases for tepid tumescence.
alias lns='ln -s'

# ....................{ COMPLETIONS                       }....................
# Enable programmable completion if *NOT* in strict POSIX-compatible mode and
# one or more of the following Bash-specific completion files exist.
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# ....................{ CUSTOMIZATIONS                    }....................
# Customize "less" to behave sanely when piped non-text input files.
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# ....................{ CLEANUP                           }....................
# Prevent local variables declared above from polluting the environment.
unset IS_COLOR DEBIAN_CHROOT LS_OPTIONS

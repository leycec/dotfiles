#!/usr/bin/env bash
# ====================[ .bashrc                           ]====================
#
# --------------------( LICENSE                           )--------------------
# Copyright 2008-2018 by Cecil Curry.
# See "LICENSE" for further details.
#
# --------------------( SYNOPSIS                          )--------------------
# User-specific "bash" startup script for non-login shells.
#
# --------------------( SYNOPSIS                          )--------------------
# This file is sourced by *ALL* interactive bash shells on startup, including
# numerous low-level fragile shells (e.g., "scp", "rcp") intolerate of output.
# To avoid spurious issues, both this script and all commands transitively run
# by this script *MUST* run silently (i.e., output nothing).

# ....................{ INTERACTIVE                       }....................
# If the current shell is non-interactive, silently reduce to a noop to avoid
# breaking low-level fragile shells (e.g., "scp", "rcp") intolerate of output.
[[ $- == *i* ]] || return
# Else, the current shell is interactive. In this case, configure us up.

# ....................{ GLOBALS ~ path                    }....................
# Define the current ${PATH} (i.e., user-specific ":"-delimited list of the
# absolute dirnames of all directories to locate command basenames relative to)
# *BEFORE* performing any subsequent logic possibly expecting this ${PATH}.
PATH="${PATH}:${HOME}/bash:${HOME}/perl"

# If Miniconda3 is available, prepend the absolute dirname of the Miniconda3
# subdirectory defining external commands to the current ${PATH} *AFTER*
# defining the ${PATH}, ensuring that system-wide commands (e.g., "python3")
# take precedence over Miniconda3-specific commands of the same basename.
PATH_MINICONDA3="${HOME}/py/miniconda3/bin"
[ -d "${PATH_MINICONDA3}" ] && PATH="${PATH_MINICONDA3}:${PATH}"

# Export the current ${PATH} to the parent shell environment.
export PATH

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

    # Colour "ls" output and all derivatives thereof. Dismantled, this is:
    #
    # * "--color=always", unconditionally enabling colors regardless of
    #   context. The comparable "--color=auto" option only conditionally
    #   enables colors if the current command outputs to an interactive shell.
    #   While *USUALLY* desirable, such detection fails for the common case of
    #   outputting to a pipe (e.g., "less") outputting to an interactive shell.
    LS_OPTIONS='--all --color=always --group-directories-first --human-readable'
    alias ls="ls ${LS_OPTIONS}"
    alias dir="dir ${LS_OPTIONS}"
    alias vdir="vdir ${LS_OPTIONS}"

    # Colour "grep" output and all derivatives thereof.
    alias grep='grep --color=always'
    alias fgrep='fgrep --color=always'
    alias egrep='egrep --color=always'

    # Configure "less" to preserve control characters and hence color codes.
    alias less='less --RAW-CONTROL-CHARS'
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

# ....................{ ALIASES ~ coreutils               }....................
# Configure "coreutils"-based commands with sane defaults.
alias mkdir='mkdir --parents'

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

# If bash-specific integration for the Fuzzy File Finder (FZF) is available,
# locally enable this integration.
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# ....................{ CUSTOMIZATIONS                    }....................
#FIXME; Sadly, the following command is Ubuntu-specific and hence fails under
#Gentoo with the following inscrutable error:
#    -bash: eval: line 171: syntax error near unexpected token `newline'
#    -bash: eval: line 171: `Usage: lesspipe <file>'
#The culprit is, of course, "lesspipe". As there appears to exist *NO*
#standardized "lesspipe" command, each Linux distribution ships its own
#distribution-specific mutuall-incompatible variant of "lesspipe". Generalizing
#this command to transparently support all relevant Linux distributions would
#thus require:
#
#* Detecting whether the current platform is Linux.
#* If so, detecting whether the current Linux distribution is Ubuntu, Gentoo,
#  or otherwise.
#* Conditionally running the appropriate distribution-specific command.
#
#Since all of this is fragile and none of this is worthwhile, we avoid doing
#anything whatsoever here for the moment.

# Customize "less" to behave sanely when piped non-text input files.
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# ....................{ CLEANUP                           }....................
# Prevent local variables declared above from polluting the environment.
unset IS_COLOR DEBIAN_CHROOT LS_OPTIONS PATH_MINICONDA3

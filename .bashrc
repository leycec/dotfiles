#!/usr/bin/env bash
# ====================[ .bashrc                           ]====================
#
# --------------------( LICENSE                           )--------------------
# Copyright 2008-2018 by Cecil Curry.
# See "LICENSE" for further details.
#
# --------------------( SYNOPSIS                          )--------------------
# User-specific startup script for non-login bash shells.
#
# --------------------( USAGE                             )--------------------
# This script transparently supports both bash and zsh for generality.
#
# For bash support, no further work is needed. For zsh support, either
# Symlink this script to "~/.zshrc" or source this script from "~/.zshrc".
#
# --------------------( CAVEATS                           )--------------------
# This file is sourced by *ALL* interactive bash shells on startup, including
# numerous low-level fragile shells (e.g., "scp", "rcp") intolerate of output.
# To avoid spurious issues, both this script and all commands transitively run
# by this script *MUST* run silently (i.e., output nothing).

# ....................{ SHELLS                            }....................
# 1 if the current shell is bash and the empty string otherwise. 
IS_BASH=

# 1 if the current shell is zsh and the empty string otherwise. 
IS_ZSH=

# If the current shell is zsh, define the above booleans accordingly.
if [[ -n "${ZSH_VERSION}" ]]; then
    IS_ZSH=1
# Else if the current shell is bash, define the above booleans accordingly.
elif [[ -n "${BASH_VERSION}" ]]; then
    IS_BASH=1
# Else, the current shell is unrecognized. In this case...
else
    # Print a human-readable error message to stderr.
    echo 'Current shell neither "bash" nor "zsh".' 1>&2

    # Report failure from this script.
    return 1
fi

# ....................{ INTERACTIVE                       }....................
# If the current shell is non-interactive, silently reduce to a noop to avoid
# breaking low-level fragile shells (e.g., "scp", "rcp") intolerate of output.
if   [[ -n "${IS_ZSH}"  ]]; then [[ -o interactive ]] || return
elif [[ -n "${IS_BASH}" ]]; then [[ $- == *i*      ]] || return
fi
# Else, the current shell is interactive. To quoth the Mario: "Let's a-go!"

# ....................{ GLOBALS ~ path                    }....................
# Define the current ${PATH} (i.e., user-specific ":"-delimited list of the
# absolute dirnames of all directories to locate command basenames relative to)
# *BEFORE* performing any subsequent logic possibly expecting this ${PATH}.
PATH="${PATH}:${HOME}/bash:${HOME}/perl:${HOME}/zsh"

# If Miniconda3 is available, prepend the absolute dirname of the Miniconda3
# subdirectory defining external commands to the current ${PATH} *AFTER*
# defining the ${PATH}, ensuring that system-wide commands (e.g., "python3")
# take precedence over Miniconda3-specific commands of the same basename.
PATH_MINICONDA3="${HOME}/py/miniconda3/bin"
[[ -d "${PATH_MINICONDA3}" ]] && PATH="${PATH_MINICONDA3}:${PATH}"

# Export the current ${PATH} to the parent shell environment.
export PATH

# ....................{ GLOBALS ~ color                   }....................
# 1 if the current shell supports color and the empty string otherwise. 
#
# If the "tput" command exists *AND* reports that the current shell supports
# color, assume this to mean that this shell complies with Ecma-48
# (i.e., ISO/IEC-6429). Note that, under zsh, similar logic is achievable by:
#
#     autoload colors zsh/terminfo
#     [[ "$terminfo[colors]" -ge 8 ]] && IS_COLOR=YES
IS_COLOR=
hash tput >&/dev/null && tput setaf 1 >&/dev/null && IS_COLOR=1

# ....................{ GLOBALS ~ history                 }....................
# Absolute path of the history file to which the current shell appends
# previously run commands.
export HISTFILE="${HOME}/.histfile"

# Maximum number of commands preserved by the history file.
export HISTSIZE=1000

# Maximum filesize in kilobytes of this file.
export HISTFILESIZE=2000

if [[ -n "${IS_ZSH}" ]]; then
    export SAVEHIST=1000

    # Append rather than overwrite the history file.
    setopt appendhistory
elif [[ -n "${IS_BASH}" ]]; then
    # Avoid appending both duplicate lines and space-prefixed lines.
    export HISTCONTROL=ignoreboth

    # Append rather than overwrite the history file.
    shopt -s histappend
fi

# ....................{ MODULES ~ zsh                     }....................
# Lazily load zsh-specific modules (i.e., optional C-based extensions),
# commonly defining useful functions and variables.
if [[ -n "${IS_ZSH}" ]]; then
    # Lazily load the following modules:
    #
    # * "colors", defining the ${fg} and ${bg} associative arrays whose:
    #   * Keys are strings in "red", "green", "yellow", "blue", "magenta",
    #     "cyan", and "white".
    #   * Values are the terminal-specific ANSI escape codes for setting the
    #     forground or background to that color.
    # * "terminfo", defining the ${terminfo} associative arrays whose:
    #   * Keys are standard termcap (i.e., terminal capabality) strings,
    #     including:
    #     * "bold", the ANSI escape code for bolding all subsequent colors.
    #     * "colors", the number of colors supported by this terminal.
    autoload colors zsh/terminfo
fi

# ....................{ OPTIONS                           }....................
if [[ -n "${IS_ZSH}" ]]; then
    # Change to directories in command position (i.e., specified as the first
    # shell word of a given command).
    setopt autocd

    # Dynamically expand variable expansions embedded within prompt variables
    # (e.g., ${PS1}) immediately before each display of that prompt.
    setopt prompt_subst

    setopt extendedglob
    setopt nomatch
    setopt notify

    # Disable beeping when interactively typing in the zsh line editor (ZLE).
    unsetopt beep

    # Emulate Vi[m] modality on reading keyboard input.
    bindkey -v
elif [[ -n "${IS_BASH}" ]]; then
    # Change to directories in command position (i.e., specified as the first
    # shell word of a given command).
    shopt -s autocd

    # Implicitly update the ${LINES} and ${COLUMNS} environment variables after
    # each input command to reflect the current dimensions of the parent
    # graphical terminal hosting this interactive shell.
    shopt -s checkwinsize

    # Recursively expand the "**" pattern in pathname expansions to all files
    # and subdirectories of the given directory (defaulting to the current
    # directory).
    shopt -s globstar

    # Emulate Vi[m] modality on reading keyboard input.
    set -o vi
fi

# ....................{ PROMPT                            }....................
# If this shell supports color, define a colorful shell prompt.
if [[ -n "${IS_COLOR}" ]]; then
    if [[ -n "${IS_ZSH}" ]]; then
        # Dismantled, this is:
        #
        # * "%B" and "%b", enabling and disabling boldface respectively.
        # * "%F{color}" and "%f", enabling and disabling the foreground color
        #   named "color" respectively.
        # * "%(!.root.nonroot)", expanding to the substring "root" if the
        #   current user is the superuser or the substring "nonroot" otherwise.
        # * "%n", expanding to the current username.
        # * "%~", expanding to the current directory.
        #
        # * "%{" and "%}", zsh-specific prompt escapes instructing zsh to
        #   ignore all embedded strings with respect to deciding prompt length.
        #
        # See also:
        #
        # * The "SIMPLE PROMPT ESCAPES" section of "man zshmisc".
        PROMPT='%B%(!.%F{red}.%F{green})[%bzsh%B]%f %F{cyan}%~%f %F{blue}\$%f%b '
        # PROMPT='%B%(!.%F{red}%n%f .)%F{cyan}%~%f %F{blue}\$%f%b '
    elif [[ -n "${IS_BASH}" ]]; then
        PS1='\[\033[01;32m\][\[\033[00;32m\]bash\[\033[01;32m\]]\[\033[00m\] \[\033[01;36m\]\w \[\033[01;34m\]\$\[\033[00m\] '
        # PS1='\[\033[01;32m\]\u\[\033[00m\] \[\033[01;34m\]\w \[\033[01;36m\]\$\[\033[00m\] '
    fi
else
    if [[ -n "${IS_ZSH}" ]]; then
        PROMPT='%n %~$ '
    elif [[ -n "${IS_BASH}" ]]; then
        PS1='\u \w\$ '
    fi
fi

# ....................{ COLOUR                            }....................
# Enable colour support for all relevant "coreutils" commands.

# If this shell supports color...
if [[ -n "${IS_COLOR}" ]]; then
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

    # Color GCC warnings and errors.
    export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

    # If the "dircolors" command exists, evaluate the output of this command to
    # define the ${LS_COLORS} environment variable appropriately.
    if hash dircolors >&/dev/null; then
        # If a user-specific ".dircolors" dotfile exists, replace the current
        # "dircolors" configuration (if any) with that specified by this file.
        if [[ -r ~/.dircolors ]]; then
            eval "$(dircolors --sh ~/.dircolors)"
        # Else, fallback to the default "dircolors" configuration.
        else
            eval "$(dircolors --sh)"
        fi
    fi
fi

# ....................{ ALIASES ~ coreutils               }....................
# Configure "coreutils"-based commands with sane defaults.
alias cp='cp --interactive'
alias df='df --human-readable'
alias du='du --human-readable --total'
alias mv='mv --interactive'
alias mkdir='mkdir --parents'
alias rm='rm --interactive'

# ....................{ ALIASES ~ abbreviations           }....................
# One-letter abbreviations for brave brevity.
alias d='date'
alias f='fg'
alias l='ls -CF'
alias m='mv'
alias v='vim'

# Two-letter abbreviations for great justice.
alias cm='chmod'
alias co='chown'
alias gr='grep -R'
alias ll='ls -alF'
alias lr='ll -R'
alias md='mkdir'
alias rd='rmdir'

# Three-letter abbreviations for tepid tumescence.
alias lns='ln -s'

# ....................{ ALIASES ~ distro : gentoo         }....................
# Gentoo Linux-specific aliases.

# Configure "eix" to pipe ANSI color sequences to "less".
hash eix >&/dev/null && alias eix='eix --force-color'

# ....................{ COMPLETIONS                       }....................
if [[ -n "${IS_ZSH}"  ]]; then
    # Enable all default completions.
    zstyle :compinstall filename "${HOME}/.zshrc"

    # Initialize the completion subsystem.
    autoload -Uz compinit
    compinit
elif [[ -n "${IS_BASH}" ]]; then
    # Enable programmable completion if *NOT* in strict POSIX-compatible mode
    # and one or more of the following Bash-specific completion files exist.
    if ! shopt -oq posix; then
        if [[ -f /usr/share/bash-completion/bash_completion ]]; then
            source /usr/share/bash-completion/bash_completion
        elif [[ -f /etc/bash_completion ]]; then
            source /etc/bash_completion
        fi
    fi

    # If bash-specific integration for the Fuzzy File Finder (FZF) is available,
    # locally enable this integration.
    [[ -f ~/.fzf.bash ]] && source ~/.fzf.bash
fi

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

# ....................{ CRYPTO                            }....................
# If the "keychain" command exists:
#
# * If no "ssh-agent" daemon is currently running:
#   * Spawn a long-running "ssh-agent" daemon.
#   * Cache passphrases for typical user-specific private keys with this agent.
# * Else, reuse the passphrases previously cached with this agent.
if hash keychain >&/dev/null; then
    eval "$( \
        keychain \
        --eval --ignore-missing --quick --quiet \
        ~/.ssh/id_dsa ~/.ssh/id_ecdsa ~/.ssh/id_ed25519 ~/.ssh/id_rsa \
    )"
fi

# ....................{ CLEANUP                           }....................
# Prevent local variables declared above from polluting the environment.
unset IS_BASH IS_COLOR IS_ZSH LS_OPTIONS PATH_MINICONDA3

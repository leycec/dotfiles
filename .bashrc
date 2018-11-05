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

# ....................{ FUNCTIONS                         }....................
# For disambiguity (e.g., with external commands in the current ${PATH}), *ALL*
# functions defined below are prefixed with punctuation supported by both bash
# and zsh but otherwise prohibited for standard command basenames: "+".

# bool is_command(str command_name)
#
# Report success only if a command with the passed basename resides in the
# current user's ${PATH}.
+command.is() {
    # While there exist a countably infinite number of alternative
    # shell-specific implementations of this test, the current implementation
    # appears to be the only one-liner applicable to both bash and zsh. Since
    # "hash" is a builtin in both shells, this implementation is also
    # guaranteed to be reasonably efficient.
    hash "${1}" >&/dev/null
}

# ....................{ FUNCTIONS ~ startup               }....................
# void +shell()
#
# Source the current ".bashrc" script from the current shell, typically after
# externally modifying this script.
function +shell() {
    source ~/.bashrc
}


# void +shell.edit()
#
# Edit the current ".bashrc" script from the preferred editor.
function +shell.edit() {
    "${EDITOR}" ~/.bashrc
    +shell
}

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

# ....................{ GLOBALS ~ other                   }....................
# Basename of a command in the current ${PATH} acting as the preferred
# command-line editor for this user.
  if +command.is vim ; then export EDITOR=vim
elif +command.is nano; then export EDITOR=nano
fi

# 1 if the current shell supports color and the empty string otherwise.
#
# If the "tput" command exists *AND* reports that the current shell supports
# color, assume this to mean that this shell complies with Ecma-48
# (i.e., ISO/IEC-6429). Note that, under zsh, similar logic is achievable by:
#
#     autoload colors zsh/terminfo
#     [[ "$terminfo[colors]" -ge 8 ]] && IS_COLOR=YES
IS_COLOR=
+command.is tput && tput setaf 1 >&/dev/null && IS_COLOR=1

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

    # Implicitly update the ${LINES} and ${COLUMNS} variables after each input
    # to reflect the current dimensions of the host terminal.
    shopt -s checkwinsize

    # Recursively expand the "**" pattern in pathname expansions to all files
    # and subdirectories of the given directory (defaulting to the current
    # directory).
    shopt -s globstar

    # Disable completion when the input buffer is empty, preventing bash from
    # unnecessarily expanding the entirety of the ${PATH} when the first input
    # character is a tab.
    shopt -s no_empty_cmd_completion

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
        # If this is the superuser, define a superuser-specific prompt.
        if [[ ${EUID} == 0 ]]; then
            PS1='\[\033[01;31m\][\[\033[00;31m\]bash\[\033[01;31m\]]\[\033[00m\] \[\033[01;33m\]\w \[\033[01;35m\]\$\[\033[00m\] '
        # Else, define a non-superuser-specific prompt.
        else
            PS1='\[\033[01;32m\][\[\033[00;32m\]bash\[\033[01;32m\]]\[\033[00m\] \[\033[01;36m\]\w \[\033[01;34m\]\$\[\033[00m\] '
        fi
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

# GNU-style long option unconditionally enabling color support in most modern
# CLI commands, defaulting to the empty string (i.e., ignoring color support).
COLOR_OPTION=

# If this shell supports color...
if [[ -n "${IS_COLOR}" ]]; then
    # Unconditionally enable color support regardless of context. A comparable
    # "--color=auto" option only conditionally enables colors if the current
    # command outputs to an interactive shell.  While *USUALLY* desirable, such
    # detection fails for the common case of outputting to a pipe (e.g.,
    # "less") outputting to an interactive shell.
    COLOR_OPTION=' --color=always'

    # Configure "less" to preserve control characters and hence color codes.
    alias less='less --RAW-CONTROL-CHARS'

    # Color GCC warnings and errors.
    export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

    # If the "dircolors" command exists, evaluate the output of this command to
    # define the ${LS_COLORS} environment variable appropriately.
    if +command.is dircolors; then
        # If a user-specific ".dircolors" dotfile exists, replace the current
        # "dircolors" configuration (if any) with that specified by this file.
        if [[ -f ~/.dircolors ]]; then
            eval "$(dircolors --sh ~/.dircolors)"
        # Else if a system-wide "DIR_COLORS" file exists, replace the current
        # "dircolors" configuration (if any) with that specified by this file.
        elif [[ -f /etc/DIR_COLORS ]]; then
            eval "$(dircolors --sh /etc/DIR_COLORS)"
        # Else, fallback to the default "dircolors" configuration.
        else
            eval "$(dircolors --sh)"
        fi
    fi
fi

# ....................{ ALIASES ~ coreutils               }....................
# Configure "coreutils"-based commands with sane defaults.
alias chmod='chmod --changes --preserve-root'
alias chown='chown --changes --preserve-root'
alias cp='cp --interactive --verbose'
alias df='df --human-readable'
alias du='du --human-readable --total'
alias mv='mv --interactive --verbose'
alias mkdir='mkdir --parents'
alias rm='rm --interactive --verbose'

# Colour "grep"-like commands with options defined above.
GREP_OPTIONS="--binary-files=without-match --extended-regexp --initial-tab --line-number${COLOR_OPTION}"
alias grep="grep ${GREP_OPTIONS}"
alias egrep="egrep ${GREP_OPTIONS}"
alias fgrep="fgrep ${GREP_OPTIONS}"

# Configure "ls"-like commands with options defined above.
LS_OPTIONS="--all --group-directories-first --human-readable${COLOR_OPTION}"
alias ls="ls ${LS_OPTIONS}"
alias dir="dir ${LS_OPTIONS}"
alias vdir="vdir ${LS_OPTIONS}"

# ....................{ ALIASES ~ abbreviations           }....................
# One-letter abbreviations for brave brevity.
alias c='cp'
alias d='date'
alias f='fg'
alias l='ls'
alias m='mv'

# Two-letter abbreviations for great justice.
alias cm='chmod'
alias co='chown'
alias cr='cp -R'
alias ll='l -l'
alias lr='ll -R'
alias md='mkdir'
alias rd='rmdir'

# Three-letter abbreviations for tepid tumescence.
alias chm='chmod'
alias cho='chown'
alias lns='ln -s'

# Four-letter abbreviations for fiery fenestration.
alias chmr='chmod -R'
alias chor='chown -R'

# ....................{ ALIASES ~ abbreviations ~ apps    }....................
# Abbreviations conditionally dependent upon external commands *NOT* guaranteed
# to be installed by default (i.e., not bundled with "coreutils").

# CLI-specific abbreviations.
+command.is fzf && alias fz='fzf'
+command.is htop && alias ht='htop'
+command.is ncdu && alias du='ncdu'
+command.is ncmpcpp && alias n='ncmpcpp'  # the command whose name nobody knows
+command.is vim && alias v='vim'

# GUI-specific abbreviations, typically suffixed by "&!" to permit windowed
# applications to be spawned in a detached manner from the current shell.
+command.is chromium && alias ch='chromium &!'
+command.is firefox && alias ff='firefox &!'
+command.is torbrowser-launcher && alias tb='torbrowser-launcher &!'

# ....................{ ALIASES ~ abbreviations ~ grep    }....................
# If an alternative "grep" command (e.g., ripgrep, Silver Surfer) is available,
# alias "g" and "gr" to the most efficient such command; else, fallback to
# vanilla "grep" for sanity. Anecdotally:
#
#     rg (ripgrep) >
#     ag (Silver Surfer) >
#     sift >
#     ack >
#     pt (Platinum Surfer) >
#     grep
#
# See also:
#
# * http://xuchengpeng.com/2018/03/17/search-with-ripgrep, enumerating
#   wallclock-sorted benchmarks for all commonly available "grep" alternatives.

# For the basename of each alternative "grep" command (including "grep" itself)
# in order of largely anecdotal efficiency...
for GREP_COMMAND in rg ag sift ack pt grep; do
    # If this command exists...
    if +command.is "${GREP_COMMAND}"; then
        # Alias "g" to this command.
        alias g="${GREP_COMMAND}"

        # If this command is ripgrep...
        if [[ "${GREP_COMMAND}" == 'rg' ]]; then
            # Configure ripgrep.
            alias ripgrep="ripgrep${COLOR_OPTION}"

            # Alias "gr" to the same command as well. By design, ripgrep
            # *ALWAYS* operates recursively.
            alias gr='g'
        # Else, alias "gr" to this command passed the standard "-r" option
        # enabling recursion. This assumption may not always hold, of course.
        else
            alias gr='g -r'
        fi

        # Cease iteration.
        break
    fi
done

# ....................{ ALIASES ~ distro : gentoo         }....................
# Gentoo Linux-specific aliases.
+command.is emerge  && alias em='emerge'
+command.is eselect && alias es='eselect'
+command.is repoman && alias re='repoman'

# Configure "eix" to pipe ANSI color sequences to "less".
+command.is eix && alias eix='eix --force-color'

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

    # If bash-specific integration for Fuzzy File Finder (FZF) is available,
    # enable this integration.
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
unset \
    GREP_COMMAND \
    GREP_OPTIONS \
    IS_BASH \
    IS_COLOR \
    IS_ZSH \
    LS_OPTIONS \
    PATH_MINICONDA3

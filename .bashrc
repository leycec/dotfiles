#!/usr/bin/env bash
# ====================[ .bashrc                            ]====================
#
# --------------------( LICENSE                            )--------------------
# Copyright 2008-2020 by Cecil Curry.
# See "LICENSE" for further details.
#
# --------------------( SYNOPSIS                           )--------------------
# User-specific startup script for non-login bash shells.
#
# --------------------( USAGE                              )--------------------
# This script transparently supports both bash and zsh for generality.
#
# For bash support, no further work is required. For zsh support, either
# symlink this script to "~/.zshrc" or source this script from "~/.zshrc".
#
# --------------------( CAVEATS                            )--------------------
# This script is sourced by *ALL* interactive bash shells on startup, including
# numerous low-level fragile shells (e.g., "scp", "rcp") intolerate of output.
# To avoid spurious issues, both this script and all commands transitively run
# by this script *MUST* run silently (i.e., output nothing).
#
# --------------------( DEPENDENCIES                       )--------------------
# This script has no mandatory dependencies but numerous optional dependencies
# recommended for optimal usability, including:
#
# * "zsh", the One True Shell.
# * "vim", the One True IDE.
# * "fzf", the Fuzzy File Finder (FZF).
# * "btop", a highly interactive "top" alternative.
# * "mpd", the Music Player Daemon (MPD).
# * "ncdu", the NCurses Disk Usage (NCDU) "du" alternative.
# * "ncmpcpp", a popular CLI-based MPD client.
# * "ripgrep", a strongly optimized "grep" alternative.
#
# These dependencies are installable as follows:
#
# * Under Gentoo Linux:
#    sudo emerge --ask htop keychain mpd ncdu ncmpcpp ripgrep vim zsh

# ....................{ SHELLS                             }....................
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

# ....................{ INTERACTIVE                        }....................
# If the current shell is non-interactive, silently reduce to a noop to avoid
# breaking low-level fragile shells (e.g., "scp", "rcp") intolerate of output.
if   [[ -n "${IS_ZSH}"  ]]; then [[ -o interactive ]] || return
elif [[ -n "${IS_BASH}" ]]; then [[ $- == *i*      ]] || return
fi
# Else, the current shell is interactive. To quoth the Mario: "Let's a-go!"

# ....................{ FUNCTIONS ~ aliases                }....................
# Aliases principally intended to be expanded non-interactively (e.g., within
# function bodies) rather than interactively at the command line.

# void +args.pop()
#
# Remove the last argument from the current argument list. Dismantled, this is:
#
# * "$(($#-1))", expanding to the number of arguments on the current argument
#   list minus one.
# * "${@:1:...}", expanding to all passed arguments excluding the last.
# * "set -- ...", resetting the current argument list to all passed arguments
#   excluding the last.
#
# This alias is strongly inspired by the following StackOverflow answer:
#     https://stackoverflow.com/a/26163980/2809027
alias -- '+args.pop'='set -- "${@:1:$(($#-1))}"'

# void +args.shift()
#
# Remove the first argument from the current argument list. While trivial, this
# alias is defined for orthogonality with the non-trivial +args.pop() alias.
alias -- '+args.shift'='shift'

# ....................{ FUNCTIONS                          }....................
# For disambiguity (e.g., with external commands in the current ${PATH}), *ALL*
# functions defined below are prefixed with punctuation supported by both bash
# and zsh but otherwise prohibited for standard command basenames: "+".

# bool +command.is(str command_name)
#
# Report success only if a command with the passed basename resides in the
# current user's ${PATH}.
function +command.is() {
    (( $# == 1 )) || {
        echo 'Expected one command basename.' 1>&2
        return 1
    }

    # While there exist a countably infinite number of alternative
    # shell-specific implementations of this test, the current implementation
    # appears to be the only one-liner applicable to both bash and zsh. Since
    # "hash" is a builtin in both shells, this implementation is also
    # guaranteed to be reasonably efficient.
    hash "${1}" >&/dev/null
}


# void +path.append(str dirname, ...)
#
# Append each passed existing directory to the current user's ${PATH} in a
# safe manner silently ignoring:
#
# * Relative directories (i.e., *NOT* prefixed by the directory separator).
# * Duplicate directories (i.e., already listed in the current ${PATH}).
# * Nonextant directories.
function +path.append() {
    (( $# >= 1 )) || {
        echo 'Expected one or more dirnames.' 1>&2
        return 1
    }

    # For each passed dirname...
    local dirname
    for   dirname; do
        # Strip the trailing directory separator if any from this dirname,
        # reducing this dirname to the canonical form expected by the test for
        # uniqueness performed below.
        dirname="${dirname%/}"

        # If this dirname is either relative, duplicate, or nonextant, then
        # silently ignore this dirname and continue to the next. Note that the
        # extancy test is the least performant test and hence deferred.
        [[ "${dirname:0:1}" == '/' &&
           ":${PATH}:" != *":${dirname}:"* &&
           -d "${dirname}" ]] || continue

        # Else, this is an existing absolute unique dirname. In this case,
        # append this dirname to the current ${PATH}.
        PATH="${PATH}:${dirname}"
    done

    # Strip an erroneously leading delimiter from the current ${PATH} if any --
    # a common edge case when the initial ${PATH} is the empty string.
    PATH="${PATH#:}"

    # Export the current ${PATH} to subprocesses. Although system-wide scripts
    # already export the ${PATH} by default on most systems, "Bother free is
    # the way to be."
    export PATH
}

# ....................{ GLOBALS ~ shell : path             }....................
# Define globals *AFTER* defining core functions above (e.g., +command.is())
# but *BEFORE* defining non-core functions below leveraging these globals.

# Define the current ${PATH} (i.e., user-specific ":"-delimited list of the
# absolute dirnames of all directories to locate command basenames relative to)
# *BEFORE* performing any subsequent logic possibly expecting this ${PATH}.
# Paths possibly containing commands include:
#
# * "/usr/local/bin", containing custom system-wide commands.
# * "${HOME}/bash", containing Bash-specific scripts.
# * "${HOME}/zsh", containing zsh-specific scripts.
# * "${HOME}/py/conda/bin", containing Anaconda-specific commands. Note that
#   appending (rather than prepending) this directory ensures system-wide
#   commands (e.g., "python3") take precedence over Miniconda3-specific
#   commands of the same basename.
# echo "PATH=${PATH} (before)"
+path.append /usr/local/bin ~/bin ~/bash ~/zsh  # ~/py/conda/bin
# echo "PATH=${PATH} (after)"

# ....................{ GLOBALS ~ shell : path ~ perl      }....................
# If the current user is *NOT* the superuser, sanitize the current shell
# environment of the Perl-specific globals exported below. Preserving these
# globals as the superuser induces badness elsewhere. For example, attempting
# to emerge Perl packages on Gentoo as the superuser with these globals:
#
#     * perl-module.eclass: Suspicious environment values found.
#     *     PERL_MM_OPT="INSTALL_BASE="/home/leycec/perl/cpan""
#     *     PERL5LIB="/home/leycec/perl/cpan/lib/perl5:/home/leycec/perl/cpan/lib/perl5"
#     *     PERL_MB_OPT="--install_base "/home/leycec/perl/cpan""
#     * Your environment settings may lead to undefined behavior and/or build failures.
#     * ERROR: dev-perl/Text-Template-1.530.0::gentoo failed (configure phase):
#     *   Please fix your environment ( ~/.bashrc, package.env, ... ), see above for details.
if (( EUID == 0 )); then
    unset PERL5LIB PERL_LOCAL_LIB_ROOT PERL_MB_OPT PERL_MM_OPT
# Else if CPAN is locally installed to a mostly sane user-specific directory...
elif [[ -d ~/perl/cpan/bin ]]; then
    # Append CPAN's script directory to the current ${PATH}.
    +path.append ~/perl/cpan/bin

    # Prepend CPAN's library directory to Perl's library path.
    #
    # Note these assignments resemble those emitted by the "cpan" command,
    # refactored for generic applicability.
    export PERL5LIB="${HOME}/perl/cpan/lib/perl5"
    export PERL_LOCAL_LIB_ROOT="${HOME}/perl/cpan${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"
    export PERL_MB_OPT="--install_base \"${HOME}/perl/cpan\""
    export PERL_MM_OPT="INSTALL_BASE=\"${HOME}/perl/cpan\""
    export MANPATH="${HOME}/perl/cpan/man${MANPATH:+:${MANPATH}}"
fi

# ....................{ GLOBALS ~ shell : history          }....................
# Absolute path of the history file to which the current shell appends
# previously run commands.
export HISTFILE="${HOME}/.histfile"

# Maximum number of commands preserved by the history file.
export HISTSIZE=1000

# Maximum filesize in kilobytes of this file.
export HISTFILESIZE=2000

# 1 if this is a login shell or the empty string otherwise. (Set below.)
_IS_LOGIN=

if [[ -n "${IS_ZSH}" ]]; then
    export SAVEHIST=1000

    # Dismantled, this is:
    # * "appendhistory", appending rather than overwrite the history file.
    # * "histignorealldups", removing older commands previously added to the
    #   history list when those older commands duplicate newer commands.
    setopt appendhistory histignorealldups

    # Record whether this is a login shell or not.
    [[ -o login ]] && _IS_LOGIN=1
elif [[ -n "${IS_BASH}" ]]; then
    # Avoid appending both duplicate lines and space-prefixed lines.
    export HISTCONTROL=ignoreboth

    # Append rather than overwrite the history file.
    shopt -s histappend

    # Record whether this is a login shell or not.
    shopt -q login_shell && _IS_LOGIN=1
fi

# ....................{ GLOBALS ~ colour                   }....................
# Conditionally enable colour support for all relevant "coreutils" commands.

# 1 if the current shell supports color or the empty string otherwise.
#
# If the "tput" command exists *AND* reports that the current shell supports
# color, assume this to mean that this shell complies with Ecma-48
# (i.e., ISO/IEC-6429). Note that, under zsh, similar logic is achievable by:
#
#     autoload colors zsh/terminfo
#     [[ "$terminfo[colors]" -ge 8 ]] && _IS_COLOR=YES
_IS_COLOR=
+command.is tput && tput setaf 1 >&/dev/null && _IS_COLOR=1

# GNU-style long option unconditionally enabling color support in most modern
# CLI commands, defaulting to the empty string (i.e., ignoring color support).
_COLOR_OPTION=

# If this shell supports color...
if [[ -n "${_IS_COLOR}" ]]; then
    # Unconditionally enable color support regardless of context. A comparable
    # "--color=auto" option only conditionally enables colors if the current
    # command outputs to an interactive shell.  While *USUALLY* desirable, such
    # detection fails for the common case of outputting to a pipe (e.g.,
    # "less") outputting to an interactive shell.
    _COLOR_OPTION=' --color=always'

    # Configure "less" to:
    # * Preserve control characters and hence color codes.
    # * "-s", wrap rather than truncate long lines.
    alias less='less -s --RAW-CONTROL-CHARS'

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

# ....................{ GLOBALS ~ colour : prompt         }....................
# If this shell supports color, define a colorful shell prompt.
if [[ -n "${_IS_COLOR}" ]]; then
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

# ....................{ GLOBALS ~ command                  }....................
# Gentoo developer-specific git-formatted username effectively required by all
# Gentoo repositories when submitting pull requests (PRs). See also:
#     https://github.com/gentoo/sci/blob/master/CONTRIBUTING.md
export ECHANGELOG_USER="Cecil Curry <leycec@gmail.com>"

#FIXME: Excise us up, please. *sigh*
# # Enable VDPAU-based hardware acceleration on AMD GPUs. See also:
# #     https://wiki.archlinux.org/title/Hardware_video_acceleration#Configuring_VDPAU
# export VDPAU_DRIVER=radeonsi

# ....................{ GLOBALS ~ command : ide            }....................
# If the "vim" command is in the current ${PATH}...
if +command.is vim; then
    # Prefer "vim" as the standard command-line editor.
    export EDITOR=vim

    # Alias "vim"-based commands to sane abbreviations.
    +command.is vim && alias v='vim'
    +command.is vimdiff && alias vd='vimdiff'

    # Alias GNU info to leverage vi key bindings by default.
    alias info='info --vi-keys'
# Else if the "nano" command is in the current ${PATH}, fallback to this.
elif +command.is nano; then
    export EDITOR=nano
fi

# ....................{ GLOBALS ~ lang : python            }....................
# Optimize CPython compilation for the local system. This is especially useful
# when installing older CPython versions under Arch Linux, where performance
# increases of ~30% are not uncommon. See also:
#     https://github.com/pyenv/pyenv/blob/master/plugins/python-build/README.md#building-for-maximum-performance
export PYTHON_CFLAGS='-march=native -mtune=native'
export PYTHON_CONFIGURE_OPTS='--enable-optimizations --with-lto'

# ....................{ GLOBALS ~ lang : perl              }....................
# If the Gentoo-specific "g-cpan" command is in the current ${PATH} *AND* a
# third-party Gentoo overlay exists, notify this command of this overlay.
if +command.is g-cpan && [[ -d ~/bash/raiagent ]]; then
    export GCPAN_OVERLAY=~/bash/raiagent
fi

# ....................{ GLOBALS ~ linux                    }....................
# If the ${XDG_RUNTIME_DIR} variable mandated by the XDG Base Directory
# Specification and hence assumed to exist by applications remains undefined...
if [[ -z "${XDG_RUNTIME_DIR}" ]]; then
    # Define this variable to a user-specific temporary directory.
    #
    # If the systemd-specific "/run/user" or "/var/run/user" directories
    # exist, defer to the first of these such directories; else, fallback to an
    # init-agnostic user-specific temporary directory guaranteed to be writable
    # under most sane permissions schemes.
    if   [[ -d /run/user/     ]]; then XDG_RUNTIME_DIR="/run/user/$UID"
    elif [[ -d /var/run/user/ ]]; then XDG_RUNTIME_DIR="/var/run/user/$UID"
    else                               XDG_RUNTIME_DIR="/tmp/${UID}-runtime-dir"
    fi

    # If this directory does *NOT* exist, create this directory with permissions
    # isolating access to the current user for safety.
    if [[ ! -d "${XDG_RUNTIME_DIR}" ]]; then
        mkdir "${XDG_RUNTIME_DIR}"
        chmod 0700 "${XDG_RUNTIME_DIR}"
    fi
fi

# ....................{ DEPENDENCIES                       }....................
# If the current shell is zsh...
if [[ -n "${IS_ZSH}" ]]; then
#   echo 'Enabling zsh-specific dependencies...'

    # Absolute filename of the system-wide zsh-specific "powerlevel10k" theme.
    local _POWERLEVEL10K_FILENAME='/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme'

    # Absolute filename of system-wide zsh-specific "oh-my-zsh" launch script.
    local _OHMYZSH_FILENAME='/usr/share/oh-my-zsh/oh-my-zsh.sh'

    # If "powerlevel10k" exists...
    #
    # Note that this theme may be customized by either:
    # * Running the "p10k configure" command.
    # * Manually editing the "~/.p10k.zsh" file.
    if [[ -f "${_POWERLEVEL10K_FILENAME}" ]]; then
#       echo 'Enabling "powerlevel10k"...'

        # Enable "powerlevel10k".
        source "${_POWERLEVEL10K_FILENAME}"

    # If the user-specific configuration file for "powerlevel10k" exists,
    # enable this configuration.
        [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
    fi

    # If "oh-my-zsh" exists...
    if [[ -f "${_OHMYZSH_FILENAME}" ]]; then
        # Array of the names of all "oh-my-zsh" plugins to be enabled.
        local -a plugins; plugins=(git sudo zsh-256color zsh-autosuggestions zsh-syntax-highlighting)

    # Enable "oh-my-zsh" with these plugins.
        source "${_OHMYZSH_FILENAME}"
    fi

    # If the "pokemon-colorscripts" command is in the current "${PATH}", run
    # this command to display *ADORABLE* ASCII artwork at shell startup.
    +command.is pokemon-colorscripts &&
        command pokemon-colorscripts --no-title -r 1,3,6
fi

# ....................{ FUNCTIONS ~ path                   }....................
# str +path.canonicalize(str pathname)
#
# Canonicalize the passed path (i.e., convert this path from possibly relative
# to certainly absolute) *WITHOUT* resolving intermediary symbolic links. This
# implementation is strongly inspired by this StackOverflow post:
#     https://stackoverflow.com/a/3373298/2809027
function +path.canonicalize() {
    (( $# == 1 )) || {
        echo 'Expected one pathname.' 1>&2
        return 1
    }

    # Leverage Python to perform this rote task.
    #
    # Note that there exist a multitude of alternatives -- all worse in various
    # ways. These include:
    # * Solutions running the third-party "readlink" and "readpath" commands.
    #   Unfortunately, these commands are *NOT* guaranteed (or even likely) to
    #   be available -- especially under outlier platforms like vanilla macOS
    #   and the *BSD family. Oddly, some variant of Python is basically
    #   guaranteed to be available everywhere.
    #
    # It's both fascinating and sad that POSIX-compliant shells fail to support
    # this out-of-the-box. Unix: "Still imperfect after all these years."
    command python \
        -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "${1}"
}

# ....................{ FUNCTIONS ~ path : dir             }....................
# str +dir.list_recursive(str dirname1, ...)
#
# Recursively list all transitive subdirectories of all directories with the
# passed absolute or relative dirnames.
function +dir.list_recursive() {
    # Make it so, ensign.
    ls -lR "${@}" | less
}


# str +dir.list_subdirs_mtime(str dirname)
#
# Recursively list all transitive subdirectories of the directory with the
# passed absolute or relative dirname, sorted in descending order of
# modification time (i.e., mtime).
function +dir.list_subdirs_mtime() {
    (( $# == 1 )) || {
        echo 'Expected one dirname.' 1>&2
        return 1
    }

    # Dismantled, this is:
    #
    # * "-type d", listing only subdirectories.
    # * "-printf", listing one subdirectory per line formatted as:
    #   * "%T@", the modification time for that subdirectory in seconds since
    #     the Unix epoch.
    #   * "%P", the relative dirname of this subdirectory (omitting the
    #     prefixing passed parent dirname of that dirname for readability).
    # * "sort --reverse", sorting subdirectories in descending order of
    #   modification time (i.e., from newest to oldest).
    # * "cut --complement --fields=1", removing the modification time
    #   prefixing each subdirectory for readability.
    command find "${1}" -type d -printf "%T@\t%P\n" |
        command sort --reverse |
        command cut --complement --fields=1 |
        command less
}


# str +dir.list_subdirs_mtime_depth(str dirname, int subdir_depth)
#
# Non-recursively list all subdirectories of the directory with the passed
# absolute or relative dirname residing at the passed 1-based depth of the
# directory tree rooted at that parent directory, sorted in descending order of
# modification time (i.e., mtime).
function +dir.list_subdirs_mtime_depth() {
    (( $# == 2 )) || {
        echo 'Expected one dirname and one depth.' 1>&2
        return 1
    }

    # See the +dir.list_subdirs_mtime() function.
    command find "${1}" \
            -mindepth "${2}" \
            -maxdepth "${2}" \
            -type d \
            -printf "%T@\t%P\n" |
        command sort --reverse |
        command cut --complement --fields=1 |
        command less
}


# str +dir.print_subsubsubdirname_random()
#
# Print the relative dirname of a randomly selected subsubsubdirectory (i.e.,
# randomly selected subdirectory of a randomly selected subdirectory of a
# randomly selected subdirectory) of the current working directory if any *OR*
# the empty string otherwise.
function +dir.print_subsubsubdirname_random() {
    (( $# == 0 )) || {
        echo 'Expected no arguments.' 1>&2
        return 1
    }

    # Relative dirname of a randomly selected subdirectory of the current
    # working directory.
    local SUBDIRNAME="$(command ls | command shuf -n 1)"

    # Basename of a randomly selected subsubdirectory of that subdirectory.
    local SUBSUBBASENAME="$(command ls "${SUBDIRNAME}" | command shuf -n 1)"

    # Relative dirname of this subsubdirectory.
    local SUBSUBDIRNAME="${SUBDIRNAME}/${SUBSUBBASENAME}"

    # Basename of a randomly selected subsubsubdirectory of that
    # subsubdirectory.
    local SUBSUBSUBBASENAME="$(\
        command ls "${SUBSUBDIRNAME}" | command shuf -n 1)"

    # Relative dirname of this subsubsubdirectory.
    local SUBSUBSUBDIRNAME="${SUBSUBDIRNAME}/${SUBSUBSUBBASENAME}"

    # Print this dirname.
    print "${SUBSUBSUBDIRNAME}"
}

# ....................{ FUNCTIONS ~ process                }....................
# bool +process.has_basename(str command_basename)
#
# Report success only if at least one process with the passed command basename
# (i.e., basename of the command from which that process was invoked) is
# currently running under any user.
#
# This function is strongly inspired by the following StackOverflow answer:
#     https://askubuntu.com/a/988986/415719
function +process.has_basename() {
    (( $# == 1 )) || {
        echo 'Expected one command basename.' 1>&2
        return 1
    }

    # Dismantled, this is:
    #
    # * "ps ...", printing zero or more lines such that each line contains
    #   exactly the passed basename for each process with that basename, where:
    #   * "-o comm=" compacts each line of stdout to a single column containing
    #     exactly that basename.
    #   * "-C" matches only processes with that basename.
    # * "grep -x", reporting success only if the prior "ps ..." command output
    #   at least one line containing exactly that basename.
    command ps -o comm= -C "${1}" 2>/dev/null |
        command grep -x "${1}" >&/dev/null
}

# ....................{ FUNCTIONS ~ rc                     }....................
# void +rc()
#
# Resource the current bash or zsh startup script from the current shell (e.g.,
# after editing this script).
function +rc() {
    (( $# >= 0 )) || {
        echo 'Expected no arguments.' 1>&2
        return 1
    }

    #FIXME: Generalize to source the current script without hardcoding. Under
    #Bash, the absolute filename of this script is "${BASH_SOURCE[0]}".
    echo "Resourcing \"${HOME}/.bashrc\"..."
    source ~/.bashrc
}


# void +rc.edit()
#
# Edit the current bash or zsh startup script with this user's preferred editor
# and resource this script after doing so from the current shell.
function +rc.edit() {
    (( $# >= 0 )) || {
        echo 'Expected no arguments.' 1>&2
        return 1
    }

    "${EDITOR}" ~/.bashrc
    +rc
}

# ....................{ FUNCTIONS ~ command                }....................
# Functions conditionally dependent upon the existence of one or more commands.

# ....................{ FUNCTIONS ~ command : arch : zip   }....................
# If "zip" is in the current ${PATH}...
if +command.is zip; then
    # str +archive.make_zip(
    #     str zip_filename, str input_filename1, str input_filename2, ...)
    #
    # Compress the input files with the passed pathnames into a new output
    # compressed zip-formatted archive with the passed filename.
    #
    # For simplicity, this function unconditionally compresses these paths for
    # maximum compressability and thus minimal output filesize.
    function +archive.make_zip() {
        (( $# >= 1 )) || {
            echo 'Expected one optional output zip filename and one or more mandatory input pathnames.' 1>&2
            return 1
        }

        # If passed only one input path, default to an output zip filename in
        # the current working directory (CWD) whose basename is this input
        # pathname appended by a ".zip" filetype.
        if (( $# == 1 )); then
            set -- "${1}.zip" "${@}"
        fi

        # Compress all input files into this output zip file. Dismantled, this
        # is:
        #
        # * "-9", enabling the maximum compression rate.
        # * "--recurse-paths", transparently compressing directories as well.
        # * "--verbose", displaying progress while compressing.
        command zip -9 --recurse-paths --verbose "${@}"
    }
fi

# If "unzip" is in the current ${PATH}...
if +command.is unzip; then
    # str +archive.find_in_zip(str regex, str zip_filename1, ...)
    #
    # Find all paths contained in any zip-formatted archives with the passed
    # filenames such that the relative pathnames of these paths in these
    # archives match the passed extended regular expression.
    #
    # This alias is strongly inspired by the following StackOverflow comment:
    #     https://unix.stackexchange.com/a/562391/117478
    function +archive.find_in_zip() {
        (( $# >= 2 )) || {
            echo 'Expected one extended regular expression and one or more zip filenames.' 1>&2
            return 1
        }

        # Localize and remove the passed regex from the argument list.
        local regex="${1}" zip_filename
        +args.shift

        # For each passed zip filename...
        for zip_filename in "${@}"; do
            # Print the name of this filename for disambiguity.
            echo "${zip_filename}:"

            # Print all paths in this file matching this regex.
            command unzip -l "${zip_filename}" |
                command grep --extended-regexp --color=always "${regex}"
        # Page the above output for readability.
        done | less
    }

    # str +archive.list_zip(str zip_filename)
    #
    # List the contents of the zip-formatted archive with the passed filename.
    function +archive.list_zip() {
        (( $# == 1 )) || {
            echo 'Expected one zip filename.' 1>&2
            return 1
        }

        # List the contents of this zip file. Dismantled, this is:
        #
        # * "-l", listing this zip file's contents.
        # * "-v", verbosely displaying supplementary per-file metadata (e.g.,
        #         compression method, size, ratio, 32-bit CRC).
        command unzip -l -v "${@}"
    }
fi

# ....................{ FUNCTIONS ~ command : audio        }....................
# If FFmpeg is in the current ${PATH}...
if +command.is ffmpeg; then
    # str +audio.convert_flac_to_mp3(
    #     str flac_filename1, str flac_filename2, ...)
    #
    # Convert each FLAC-uncompressed audio file with the passed filename into
    # an MP3-compressed audio file with the same filename with filetype "mp3"
    # rather than "flac".
    function +audio.convert_flac_to_mp3() {
        (( $# >= 1 )) || {
            echo 'Expected one or more filenames.' 1>&2
            return 1
        }

        # For each passed filename...
        local flac_filename mp3_filename
        for   flac_filename in "${@}"; do
            # Target filename derived from this source filename.
            mp3_filename="${flac_filename%.flac}.mp3"

            # Dismantled, this is:
            #
            # * "-qscale:a 0", encoding only audio with fixed quality scale
            #   variable bitrate (VBR) with the optimum preset predefined by
            #   the target codec. While codec-dependent, this typically
            #   approximates standard high-quality 320Kb CBR compressed audio.
            echo "Converting \"${flac_filename}\" to \"${mp3_filename}\"..."
            command ffmpeg -i "${flac_filename}" -qscale:a 0 "${mp3_filename}"
        done
    }


    # str +audio.convert_m4a_to_mp3(
    #     str m4a_filename1, str m4a_filename2, ...)
    #
    # Convert each M4A-uncompressed audio file with the passed filename into
    # an MP3-compressed audio file with the same filename with filetype "mp3"
    # rather than "m4a".
    function +audio.convert_m4a_to_mp3() {
        (( $# >= 1 )) || {
            echo 'Expected one or more filenames.' 1>&2
            return 1
        }

        local m4a_filename mp3_filename
        for   m4a_filename in "${@}"; do
            mp3_filename="${m4a_filename%.m4a}.mp3"

            # Dismantled, this is:
            #
            # * "-qscale:a 0", encoding only audio with fixed quality scale
            #   variable bitrate (VBR) with the optimum preset predefined by
            #   the target codec. While codec-dependent, this typically
            #   approximates standard high-quality 320Kb CBR compressed audio.
            echo "Converting \"${m4a_filename}\" to \"${mp3_filename}\"..."
            command ffmpeg -i "${m4a_filename}" -qscale:a 0 "${mp3_filename}"
        done
    }


    # str +audio.convert_wav_to_mp3(
    #     str wav_filename1, str wav_filename2, ...)
    #
    # Convert each WAV-uncompressed audio file with the passed filename into
    # an MP3-compressed audio file with the same filename with filetype "mp3"
    # rather than "wav".
    function +audio.convert_wav_to_mp3() {
        (( $# >= 1 )) || {
            echo 'Expected one or more filenames.' 1>&2
            return 1
        }

        local wav_filename mp3_filename
        for   wav_filename in "${@}"; do
            mp3_filename="${wav_filename%.wav}.mp3"

            # Dismantled, this is:
            #
            # * "-qscale:a 0", encoding only audio with fixed quality scale
            #   variable bitrate (VBR) with the optimum preset predefined by
            #   the target codec. While codec-dependent, this typically
            #   approximates standard high-quality 320Kb CBR compressed audio.
            echo "Converting \"${wav_filename}\" to \"${mp3_filename}\"..."
            command ffmpeg -i "${wav_filename}" -qscale:a 0 "${mp3_filename}"
        done
    }
fi

# If "shnsplit" is in the current ${PATH}...
if +command.is shnsplit; then
    # str +audio.split_flac_with_cue(str flac_filename, str cue_filename)
    #
    # Split a monolithic FLAC-uncompressed audio file with the passed filename
    # from the corresponding CUE-formatted metadata with the passed filename
    # into one or more FLAC-uncompressed audio files in the current working
    # directory with basename .
    #
    # If the "cuetools" suite of CLI utilities is available, the audio files
    # produced by this function will also be tagged with appropriate metadata.
    #
    # This function's implementation is strongly inspired by the following
    # StackOverflow answer, courtesy Michael H:
    #     https://unix.stackexchange.com/a/30863/117478
    function +audio.split_flac_with_cue() {
        (( $# == 2 )) || {
            echo 'Expected one FLAC filename and one CUE filename.' 1>&2
            return 1
        }

        local flac_filename="${1}" cue_filename="${2}"

        echo "Splitting \"${flac_filename}\" with \"${cue_filename}\"..."
        command shnsplit \
            -f "${cue_filename}" \
            -t %n-%t \
            -o flac "${flac_filename}"

        # If "cuetag" (provided by the "cuetools" suite of CLI utilities) is in
        # the current ${PATH}, tag each of the FLAC files produced by the prior
        # command with the metadata provided by the same CUE file.
        if +command.is cuetag.sh; then
            echo "Tagging split FLAC files with \"${cue_filename}\"..."
            command cuetag.sh "${cue_filename}" [0-9]*.flac
        # Else, issue a non-fatal warning.
        else
            echo '"cuetools" not found; FLAC files left untagged.' 1>&2
        fi
    }
fi

# ....................{ FUNCTIONS ~ command : code         }....................
# If the third-party "git" command is in the current ${PATH}...
if +command.is git; then
    # str +git.revive_removed_path(str pathname)
    #
    # Revive (i.e., restore, resurrect) the previously removed path with the
    # passed relative pathname from a prior commit in the "git" repository
    # managing the current working directory (CWD) if any *OR* fail otherwise
    # (i.e., if the CWD is *NOT* managed by a "git" repository).
    #
    # See also this StackOverflow answer strongly inspiring this function:
    #     https://stackoverflow.com/a/1113140/2809027
    function +git.revive_removed_path() {
        (( $# == 1 )) || {
            echo 'Expected one relative pathname.' 1>&2
            return 1
        }

        local pathname_removed="${1}" commit_removed

        # Most recent commit containing this relative pathname if any *OR* fail
        # otherwise.
        echo \
            "Searching for git commit providing previously removed" \
            "git-managed file \"${pathname_removed}\"..."
        commit_removed="$(command git rev-list \
            -n 1 HEAD -- "${pathname_removed}")" || {
            echo \
                "Previously removed git-managed file" \
                "\"${pathname_removed}\" not found." 1>&2
            return 1
        }

        # Revive this path.
        #
        # Note that the "^" character *MUST* be explicitly quote-protected to
        # prevent interpretation under various shells (e.g., fish, zsh).
        echo \
            "Restoring previously removed" \
            "git-managed file \"${pathname_removed}\"..."
        command git checkout "${commit_removed}^" -- "${pathname_removed}"
    }
fi

# If the third-party "pygmentize" command from the Python-friendly "pygments"
# package is in the current ${PATH}...
if +command.is pygmentize; then
    # str +python.highlight()
    #
    # Syntactically highlight the string of one or more Python statements passed
    # as standard input (typically using a heredoc) via the "pygments" package
    # if "pygments" successfully parses that string as Python *OR* report
    # failure (i.e., if "pygments" fails to parse that string as Python): e.g.,
    #     +python.highlight << 'EOF'
    #     <copy-paste code here>
    #     EOF
    #
    # This function is *incredibly* useful for resolving non-human-readable
    # Sphinx syntax highlighting warnings resembling:
    #     WARNING: Could not lex literal_block as "python3". Highlighting
    #     skipped.
    function +python.highlight() {
        (( $# == 0 )) || {
            echo 'Expected no arguments.' 1>&2
            return 1
        }

        # We had joy, we had fun, we had seasons in the... pygments! Dismantled,
        # this is:
        # * "-l python3", lexing (i.e., parsing) standard input as Python code.
        # * "-F raiseonerror", raising a fatal exception on lexing errors.
        # * "-v", printing a detailed traceback for that exception.
        command pygmentize -l python3 -F raiseonerror -v
    }
fi

# ....................{ FUNCTIONS ~ command : desktop      }....................
# If the Hyperland Desktop Environment (Hyde) is locally installed to a mostly
# sane user-specific directory...
if [[ -d ~/hypr/hyde/Scripts ]]; then
    # str +hyde.update()
    #
    # Update the Hyperland Desktop Environment (Hyde) to the most recent remote
    # GitHub-managed "live" version. See also these official instructions:
    #      https://github.com/prasanthrangan/hyprdots?tab=readme-ov-file#-1
    function +hyde.update() {
        (( $# == 0 )) || {
            echo "Expected no arguments, but received ${#}." 1>&2
            return 1
        }

        echo 'Updating Hyde...'
        ~/hypr/hyde/Scripts
        command git pull
        ./install.sh -r
    }
fi

# ....................{ FUNCTIONS ~ command : image        }....................
#FIXME: Create similar ImageMagick-based commands for:
#* Reduction to grayscale. Curiously, it would seem that there are a countably
#  infinite number of approaches to archieving this reduction. See also This
#  authoritative INTP-style article on the subject:
#       https://im.snibgo.com/mmono.htm
#
#  The table produced by the sentence "So we sort on Mean and StdDev,
#  eliminating duplicates:" orders the results according to standard statistical
#  measures. That said, we conveniently ignore the first approach in this table
#  (i.e., "colour_distance_Lab"), as the results are qualitatively *HIDEOUS.*
#
#  The results of that article strongly suggest that the following ImageMagick
#  command produces optimal qualitative results for this in-place reduction:
#      magick -grayscale Rec601Luminance "${src_filename}"

# If ImageMagick's "mogrify" command is in the current ${PATH}...
if +command.is mogrify; then
    # str +image.convert(str src_filename1, ..., src trg_filetype)
    #
    # Compact each source image file with the passed filename (of a filetype
    # supported by ImageMagick) into a target image file with a similar filename
    # but whose filetype is replaced with that of the passed target filetype.
    function +image.convert() {
        (( $# >= 2 )) || {
            echo 'Expected one or more image filenames and one target filetype.' 1>&2
            return 1
        }

        # Target filetype, stripped of any preceding "." character for safety.
        local trg_filetype="${@[-1]#.}"

        # Convert these source to target files with this filetype. Thankfully,
        # ImageMagick's "mogrify" command mostly trivializes image conversion.
        echo "Converting images to \"${trg_filetype}\"..."
        command mogrify -format "${trg_filetype}" "${@[1,-2]}"
    }

    # str +image.thumbnail(str src_filename1, ..., int trg_width)
    #
    # Compact each source image file with the passed filename (of a filetype
    # supported by ImageMagick) into a target image file with the target pixel
    # width whose basename excluding filetype is prefixed by "thumbnail-" (e.g.,
    # "+image.thumbnail input1.png" produces "thumbnail-input1.png"), where
    # compaction implies a significant reduction in size and filesize with *NO*
    # discernable reduction in fidelity while preserving the aspect ratio.
    #
    # Note that this file's existing pixel width may be easily inspected with:
    #     $ file "${src_filename}"
    #
    # This function is strongly inspired by Dave Newton's seminal blog article
    # "Efficient Image Resizing With ImageMagick," a phenomenal effort derived
    # by iterative maximization of image reduction quality as objectively
    # measured by structural dissimilarity (DSSIM):
    #     https://www.smashingmagazine.com/2015/06/efficient-image-resizing-with-imagemagick
    function +image.thumbnail() {
        (( $# >= 2 )) || {
            echo 'Expected one or more image filenames and one target width.' 1>&2
            return 1
        }

        # Target image width.
        local trg_width="${@[-1]}"

        # For each passed filename...
        local src_filename trg_filename
        for   src_filename in "${@[1,-2]}"; do
            # Derive this target filename from this source filename.
            trg_filename="$(\
                dirname "${src_filename}")/thumbnail-$(basename "${src_filename}")"

            # Copy this filename to the expected target filename, as the
            # "mogrify" command only works in-place and thus destructively.
            echo "Thumbnailing \"${src_filename}\" to \"${trg_filename}\"..."
            cp -i "${src_filename}" "${trg_filename}"

            # Compact this target file. Note this pipeline diverges from that
            # originally given by Dave Newton above as follows:
            # * "-filter Triangle" is intentionally *NOT* passed, as that filter
            #   imposes a significant Gaussian blur.
            # * "-quality 82" is intentionally *NOT* passed, as that quality
            #   reduction is perceptible to the human eye.
            # * "-strip" is intentionally *NOT* passed, as this option
            #   *DRAMATICALLY* reduces quality for photographs with embedded colour
            #   profiles. Since photographs captured by mobile devices embed colour
            #   profiles *AND* since mobile devices now account for most
            #   photographs, this option effectively destroys photographs.
            command mogrify \
                -thumbnail "${trg_width}" \
                -define filter:support=2 \
                -unsharp '0.25x0.25+8+0.065' \
                -dither None \
                -posterize 136 \
                -define jpeg:fancy-upsampling=off \
                -define png:compression-filter=5 \
                -define png:compression-level=9 \
                -define png:compression-strategy=1 \
                -define png:exclude-chunk=all \
                -interlace line \
                -colorspace sRGB \
                "${trg_filename}"
        done
    }

    # str +tiff.convert_to_jpg_recursive()
    #
    # Recursively convert all TIFF images under the current directory to JPEG
    # format in a safe manner preserving the original images as is.
    function +tiff.convert_to_jpg_recursive() {
        (( $# == 0 )) || {
            echo "Expected no arguments, but received ${#}." 1>&2
            return 1
        }

        echo 'Converting all TIFF images under current directory to JPEG format...'

        # Make it so, Ensign.
        local tiff_filename jpeg_filename
        for   tiff_filename in **/*.tiff*; do
        # for   tiff_filename in (**/*.tif(f|)(.)); do
            jpeg_filename="${tiff_filename%.tif(f|)}.jpg"
            echo "  ${tiff_filename} -> ${jpeg_filename}"
            command convert -quality 50 "${tiff_filename}" "${jpeg_filename}"
        done
    }
fi

# ....................{ FUNCTIONS ~ command : image : jpg  }....................
# If "jpegoptim" is in the current ${PATH}...
#
# Note that numerous JPEG optimizers exist (e.g., "jpeg-tran", MozJPEG), but
# that "jpegoptim" is well-known to be reasonably fast, compress reasonably
# well, and trivially installable under most Linux distributions. For example:
# * MozJPEG is significantly slower, compresses only marginally better, AND* is
#   non-trivial to install under most Linux distributions (due to being a
#   drop-in replacement for the standard "libjpeg" shared library).
#
# In short, "jpegoptim" offers the most reasonable tradeoffs.
if +command.is jpegoptim; then
    # str +jpg.optimize(str jpg_filename1, ..., int jpg_quality)
    #
    # Optimize each JPEG-formatted image file with the passed filename into an
    # output file whose basename excluding filetype is suffixed by "-optim"
    # (e.g., "+jpg.optimize input1.jpg input2.jpg" produces "input1-optim.jpg"
    # and "input2-optim.jpg"), where optimization implies lossy compression to
    # the passed target JPEG quality as an integer in the range [0, 100]
    # (inclusive) with *NO* discernable reduction in subjective fidelity.
    #
    # Note that:
    # * A target quality of 100 effectively guarantees lossless operation.
    # * A target quality of 50 is typically the lowest lossy optimization that
    #   still reasonably preserves the fidelity of the input image. Avoid
    #   decreasing the quality below 50 unless you know what you're doing.
    # * Common web practice as of this implementation typically advises sizes of
    #   between 100—400Kb for JPEG files *NOT* used as hero images (i.e.,
    #   front-facing header banner images, which are typically full-width and
    #   between quarter- to half-height).
    function +jpg.optimize() {
        (( $# >= 2 )) || {
            echo 'Expected one or more JPEG filenames and one target quality.' 1>&2
            return 1
        }

        # Target JPEG quality as an integer in the range [0, 100] (inclusive).
        local trg_quality="${@[-1]}"

        # For each passed filename...
        local src_filename trg_filename
        for   src_filename in "${@[1,-2]}"; do
            print "Optimizing \"${src_filename}\" to quality ${trg_quality}..."

            # Target filename derived from this source filename.
            trg_filename="${src_filename%.jpg}-optim.jpg"

            # Dismantled, this is:
            # * "--max=...", optimizing this input file to this maximum target
            #   quality.
            # * "--stdout", printing the contents of the optimized target file
            #   to standard output. By default, "jpegoptim" insanely *SILENTLY*
            #   overwrites the unoptimized input file! Yikes.
            #
            # Note that:
            # * The "--strip-all" ("-s") option removing *ALL* metadata is
            #   intentionally *NOT* passed, as "jpegoptim" already removes *ALL*
            #   metadata excluding colourspace metadata by default.
            # echo "Optimizing \"${src_filename}\" to \"${trg_filename}\"..."
            command jpegoptim \
                --max="${trg_quality}" \
                --stdout \
                "${src_filename}" > "${trg_filename}"
        done
    }
fi

# ....................{ FUNCTIONS ~ command : image : png  }....................
# If "pngquant" is in the current ${PATH}...
#
# Note that numerous PNG optimizers exist (e.g., "optipng", "pngcrush"), but
# that "pngquant" is well-known to be both the fastest and yield the most
# significant savings in filesize versus alternatives. See also:
#     https://medium.com/open-pbs/experimenting-with-png-and-jpg-optimization-d1428e24928c
#     https://willem.com/blog/2018-09-26_optimising-images-for-the-web-and-performance
if +command.is pngquant; then
    # str +png.optimize(str png_filename1, ...)
    #
    # Optimize each PNG-formatted image file with the passed filename into an
    # output file whose basename excluding filetype is suffixed by "-optim"
    # (e.g., "+png.optimize input1.png input2.png" produces "input1-optim.png"
    # and "input2-optim.png"), where optimization implies lossy compression
    # with no discernable reduction in subjective fidelity.
    function +png.optimize() {
        (( $# >= 1 )) || {
            echo 'Expected one or more PNG filenames.' 1>&2
            return 1
        }

        # Dismantled, this is:
        # * "--speed 1", maximizing resulting fidelity at a negligible cost in
        #   time complexity. Since "pngquant" is already when known to be the
        #   fastest PNG optimizer, this tradeoff is typically optimal.
        # echo "Optimizing \"${png_src_filename}\" to \"${png_trg_filename}\"..."
        command pngquant --ext '-optim.png' --speed 1 --verbose "${@}"
    }
fi

# ....................{ FUNCTIONS ~ command : net          }....................
# If the "curl" command is in the current ${PATH}...
if +command.is curl; then
    # void +curl.download(str url, str filename = '')
    #
    # Repeatedly attempt to download the remote file referenced by the passed
    # URL to the passed local filename (defaulting to the current working
    # directory suffixed by the basename of this URL if unpassed) until this
    # file is successfully downloaded.
    function +curl.download() {
        (( $# == 1 || $# == 2 )) || {
            echo 'Expected one input URL and one optional output filename.' 1>&2
            return 1
        }

        local url="${1}"

        # Array of shell words comprising the "curl" command to be run,
        # including command-line options.
        local -a curl_command; curl_command=(
            command curl
            --location
            --continue-at -
            --retry 999999
            --retry-delay 5
        )

        # If passed an optional output filename, append an option saving this
        # download to that filename.
        if (( $# == 2 )); then
            curl_command=( "${curl_command[@]}" --output "${2}" )
        # Else, append an option saving this download to a filename
        # concatenating the current working directory and this URL's basename.
        else
            curl_command=( "${curl_command[@]}" --remote-name )
        fi

        # Note that passing even "--retry*" options (as above) is insufficient
        # to guarantee that curl repeatedly retries the download until
        # successful. Indeed, without further guidance, curl routinely fails
        # with errors like:
        #     curl: (56) Recv failure: Connection reset by peer
        #
        # So, we additionally forcefully rerun curl until curl reports success.
        until "${curl_command[@]}" "${url}"; do
            echo 'Forcefully resuming prematurely aborted download...' 1>&2
            sleep 5
        done
    }
fi

# If the "nc" (i.e., "netcat") command is in the current ${PATH}...
if +command.is nc; then
    # str +net.inject_netcat_payload(
    #     str payload_filename, str ip_address, int port_number)
    #
    # Inject (i.e., transmit) the contents of the passed file as a payload over
    # the NetCat protocol into the remote machine at the passed IP address and
    # port number.
    function +net.inject_netcat_payload() {
        (( $# == 3 )) || {
            echo 'Expected one payload filename, one IP address, and one port number.' 1>&2
            return 1
        }
        local payload_filename="${1}" ip_address="${2}" port_number="${3}"

        # If this file does *NOT* exist, fail.
        [[ -f "${payload_filename}" ]] || {
            echo "Payload filename \"${payload_filename}\" not found." 1>&2
            return 1
        }
        # Else, this file exists.

        # Make it so for great justice. Dismantled, this is:
        # * "-w {timeout}", timing this operation out after the passed number of
        #   seconds of connection inactivity from the remote machine.
        command nc -w 60 \
            "${ip_address}" "${port_number}" < "${payload_filename}"
    }
fi

# ....................{ FUNCTIONS ~ command : net : rsync  }....................
# If the "rsync" command is in the current ${PATH}...
if +command.is rsync; then
    # void +rsync.sync_safe(str src_pathname, str trg_pathname)
    #
    # Synchronize the local or remote source path with the passed pathname to
    # the local or remote target path with the passed pathname via the "rsync"
    # protocol "safely" (i.e., by preserving rather than deleting extraneous
    # target paths that exist *ONLY* in this target but not source directory).
    #
    # By default, "rsync" encapsulates remote operations over the SSH protocol.
    # Remote hosts are supported in both the source *AND* target pathnames via
    # standard SSH syntax: e.g.,
    #     # Synchronize the remote ~leycec user directory on the remote machine
    #     # with this IP address to the corresponding local user directory.
    #     +rsync.safe leycec@192.168.1.191:/home/leycec /home/leycec
    function +rsync.safe() {
        (( $# == 2 )) || {
            echo 'Expected one source pathname and one target pathname.' 1>&2
            return 1
        }
        local src_pathname="${1}" trg_pathname="${2}"

        # If the source pathname is *NOT* the root directory, strip the trailing
        # "/" delimiter if any from this pathname. Why? Because the default
        # "rsync" behaviour interprets a trailing "/" delimiter in the source
        # pathname in a non-intuitively dangerous manner. See also this relevant
        # upstream Arch Linux Wiki section:
        #     https://wiki.archlinux.org/title/rsync#Trailing_slash_caveat
        [[ "${src_pathname}" != '/' ]] && src_pathname="${src_pathname%/}"
        print "Synchronizing \"${src_pathname}\" to \"${trg_pathname}\"..."

        # Array of shell words comprising the "rsync" command to be run,
        # including command-line options.
        local -a rsync_command; rsync_command=(
            command rsync

            # Ignore temporary directories.
            --exclude='/run'
            --exclude='/tmp'
            --exclude='/var/tmp'
            --exclude='.gvfs'

            # Ignore temporary files.
            --exclude='*.swp'

            # Ignore problematic directories, including:
            #
            # * ".PyCharm*", matching all PyCharm-specific dot directories,
            #   which "rsync" fails to synchronized with I/O timeout errors for
            #   unknown reasons.
            # * ".cache", matching the top-level "${HOME}/.cache" dot directory
            #   guaranteed to contain trivially recreatable temporary paths.
            # * "__pycache__", matching all CPython-specific bytecode cache
            #   directories.
            --exclude='.PyCharm*'
            --exclude='.cache'
            --exclude='__pycache__'

            # # Delete all paths found on the target but *NOT* the source.
            # --delete --delete-during

            # Synchronize device and special files as well as normal files.
            --devices --specials

            # Ignore spurious I/O errors (e.g., permission failure).
            --ignore-errors

            # Synchronize symbolic links.
            --links --keep-dirlinks --safe-links

            # Avoid crossing filesystem boundaries (i.e., synchronize only files
            # residing on filesystems to which the target URIs themselves are
            # mounted).
            # --one-file-system

            # Preserve partially transferred files.
            --partial

            # Attempt to preserve file permissions and ownership.
            --perms --group --owner
            --protect-args

            # Increase the I/O timeout from the default 30 seconds to 4 minutes.
            --timeout=240

            # Synchronize recursively.
            --recursive
            --sparse
            --times

            # Synchronize human-readably. Dismantled, this is:
            # * "stats1", displaying transfer statistics with verbosity level 1.
            # * "progress2", displaying total transfer progress (rather than
            #   per-file transfer progress as with "progress1").
            --human-readable
            --info=stats1,progress2
            --itemize-changes
            --progress
            --stats
        )

        # Note that, unlike curl, rsync has *NO* retry options. Ergo, we
        # additionally forcefully rerun rsync until rsync reports success.
        until "${rsync_command[@]}" "${src_pathname}" "${trg_pathname}"; do
            echo 'Forcefully resuming prematurely aborted synchronization...' 1>&2
            sleep 5
        done
    }

    #FIXME: Remove after no longer required, please.
    function +rsync.telynau() {
        +rsync.safe leycec@192.168.1.191:/home/leycec/pri /home/leycec/

#       for basename in note; do
        # for basename in audio; do
        # 	+rsync.safe \
        # 	    leycec@192.168.1.191:/home/leycec/pub/"${basename}" \
        # 	    /home/leycec/pub
        # done

#       for basename in {audio,code,demo,game,image,note,text,video}; do
#       	+rsync.safe \
#       	    leycec@192.168.1.191:/media/telynau/pub/"${basename}" \
#       	    /home/leycec/pub
#       done
#	    leycec@192.168.1.191:/home/leycec/"/pub/torrent/clearnet/[Anime Time] Code Geass Full Series [BD][Dual Audio][1080p][HEVC 10bit x265][AAC][Eng Sub]/Code Geass Season 1" \

#	+rsync.safe \
#	    leycec@192.168.1.191:/home/leycec/pub/new/'EP*' \
#	    /home/leycec/new/
    }
fi

# ....................{ FUNCTIONS ~ command : python       }....................
# If Python 3 is in the current ${PATH}...
if +command.is python3; then
    # str +python.profile_snippet(str setup_code, str profile_code)
    #
    # Profile (i.e., time) the second passed Python snippet by running that
    # snippet repeatedly *AFTER* running the first passed Python snippet once
    # via the stdlib "timeit" module. As examples:
    #     # Time the conversion of a NumPy array to a Python list:
    #     $ timeit 'import numpy as np; array = np.array(range(1000))' 'list(array)'
    #     Profiling code snippets...
    #     10000 loops, best of 5: 29.4 usec per loop
    #
    #     # Time the conversion of a NumPy array to a Python set:
    #     $ timeit 'import numpy as np; array = np.array(range(1000))' 'set(array)'
    #     Profiling code snippets...
    #     5000 loops, best of 5: 43.2 usec per loop
    function +python.profile_snippet() {
        (( $# == 2 )) || {
            echo 'Expected one setup code string and one non-setup code string: e.g.,'
            echo '    timeit "import numpy as np; array = np.array(range(1000))" "list(array)"'
            return 1
        }

        code_setup="${1}"
        code_timed="${2}"

        echo 'Profiling code snippets...'
        command python3 -m timeit -s "${code_setup}" "${code_timed}"
    }
fi

# If "pyenv" is in the current ${PATH}...
if +command.is pyenv; then
    # Initialize "pyenv" for use under the current shell. See also:
    #     https://github.com/pyenv/pyenv#b-set-up-your-shell-environment-for-pyenv
    export PYENV_ROOT="${HOME}/py/pyenv"
    export PATH="${PYENV_ROOT}/bin:${PATH}"
    eval "$(pyenv init - zsh)"

    # Space-delimited list of *ALL* actively maintained CPython versions.
    local _PYTHON_VERSIONS='3.9 3.10 3.11 3.12 3.13'

    # Alias common "pyenv" subcommands.
    alias pye='pyenv'
    alias pyei='pyenv install'

    # Define an alias (re)installing *ALL* actively maintained CPython versions.
    alias pyeia="pyenv install ${_PYTHON_VERSIONS}"

    # Define one shell alias "python{major}.{minor}" for each previously
    # installed Python version.
    #
    # Note that the most recently released CPython version is typically
    # available under the current Linux distribution as a similar command.
    # Nonetheless, we intentionally include that version as well in this list to
    # avoid polluting the system CPython interpreter with conflicting packages.
    pyenv global ${_PYTHON_VERSIONS}
fi

# ....................{ FUNCTIONS ~ command : python : ana }....................
# If Anaconda is installed to a predetermined user-specific directory...
if [[ -d "${HOME}/py/conda" ]]; then
    # str +python.enable_conda()
    #
    # Enable Anaconda. Specifically, this function:
    # * Prepends the Anaconda-specific executables directory (e.g.,
    #   "~/py/conda/bin/") to the current ${PATH}, temporarily overriding all
    #   system-wide Python executables with user-specific executables of the
    #   same name provided by Anaconda.
    # * Evaluates a number of shell scripts, including:
    #   * "~/py/conda/etc/profile.d/conda.sh".
    #   * "~/py/conda/etc/profile.d/mamba.sh".
    #
    # Note that there currently exists *NO* corresponding
    # +python.disable_conda() function. The effects of calling this function are
    # temporary and thus trivially undone by simply opening a new terminal.
    function +python.enable_conda() {
        (( $# == 0 )) || {
            echo 'Expected no arguments.' 1>&2
            return 1
        }

        # Inform the user of incoming strangeness with respect to Python.
        echo 'Enabling (Ana|Mini)conda integration...'

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$("${HOME}/py/conda/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/${HOME}/py/conda/etc/profile.d/conda.sh" ]; then
        . "/${HOME}/py/conda/etc/profile.d/conda.sh"
    else
        export PATH="/${HOME}/py/conda/bin:$PATH"
    fi
fi
unset __conda_setup

if [ -f "/${HOME}/py/conda/etc/profile.d/mamba.sh" ]; then
    . "/${HOME}/py/conda/etc/profile.d/mamba.sh"
fi
# <<< conda initialize <<<

        # Alias "python3" to "python". Oddly, Mambaforge defines the former but
        # *NOT* the latter -- the opposite of what Mambaforge should be doing.
        alias python3=python

        # If the current shell is zsh *AND* a zsh-specific shell script
        # implementing additional Anaconda-specific functionality required for
        # development of in-house projects exists (e.g., our core
        # +ionyou.update() function), evaluate that script as well.
        local IONYOU_CONDA_SCRIPT="${HOME}/py/ionyou/conda/dev/environment_funcs.zsh"
        [[ -n "${IS_ZSH}" && -f "${IONYOU_CONDA_SCRIPT}" ]] &&
            source "${IONYOU_CONDA_SCRIPT}"

        # Display metadata on the active Python interpreter for disambiguity.
        echo
        echo 'Python interpreter: '$(command python --version)' ['$(command python -c 'import sys; print(sys.executable)')']'
        echo 'Python site packages: '$(command python -c 'import site; print(site.getsitepackages())')
        echo

        # If Jupyter is in the current ${PATH}...
        #
        # Note that this function is intentionally defined *AFTER* enabling
        # Anaconda, as Jupyter is typically installed in Anaconda environments.
        if +command.is jupyter; then
            # str +jupyter()
            #
            # Run the Jupyter Lab daemon in the current terminal.
            function +jupyter() {
                (( $# == 0 )) || {
                    echo 'Expected no arguments.'
                    return 1
                }

                # Run the Jupyter Lab daemon under this interpreter.
                echo '[DEVELOPER] Running "conda"-based Jupyter Lab daemon...'
                command jupyter lab --notebook-dir="${HOME}/py/notebook"
            }
        fi
    }

    # If the current user is "pietakio", enable Anaconda by default.
    [[ "${USER}" == 'pietakio' ]] && +python.enable_conda
fi

# ....................{ FUNCTIONS ~ command : text         }....................
# If the "base64" command is in the current ${PATH}...
if +command.is base64; then
    # str +text.decode_base64(str text_base64_encoded)
    #
    # Decode the passed base64-encoded string.
    function +text.decode_base64() {
        (( $# == 1 )) || {
            echo 'Expected one base64-encoded string.' 1>&2
            return 1
        }

        # Make it so for great justice.
        echo "${1}" | command base64 --decode -
    }
fi

# ....................{ FUNCTIONS ~ command : text         }....................
# If the "gs" (i.e., GhostScript) command is in the current ${PATH}...
if +command.is gs; then
    # str +pdf.compact(str src_filename, str trg_filename)
    #
    # Reduce the filesize of the passed source PDF into a new target PDF: e.g.,
    #     $ compact_pdf.sh input.pdf output.pdf
    function +pdf.compact() {
        (( $# == 2 )) || {
            echo "Expected one source filename and one target filename." 1>&2
            return 1
        }

        # Input and output PDF filenames.
        local input_filename=${1}
        local output_filename=${2}

        # If the input files does *NOT* exist, fail.
        [[ -f "${input_filename}" ]] || {
            echo "Input filename \"${input_filename}\" not found." 1>&2
            return 1
        }

        # If either the input or output files are *NOT* PDFs, fail.
        [[ "${input_filename}" == *.pdf ]] || {
            echo "Input filename \"${input_filename}\" not a PDF." 1>&2
            return 1
        }
        [[ "${output_filename}" == *.pdf ]] || {
            echo "Output filename \"${output_filename}\" not a PDF." 1>&2
            return 1
        }

        # Reduce this input PDF into this output PDF.
        echo "Compacting \"${input_filename}\" to \"${output_filename}\"..."
        command gs\
            -sDEVICE=pdfwrite\
            -dCompatibilityLevel=1.4\
            -dUseCIEColor\
            -dPDFSETTINGS=/printer\
            -dNOPAUSE\
            -dQUIET\
            -dBATCH\
            -sOutputFile="${output_filename}"\
            "${input_filename}"
    }
fi

# ....................{ FUNCTIONS ~ command : wine         }....................
#FIXME: Add additional commands to enable performance-centric APIs, including:
#* VKD3D-Proton via:
#      $ WINEPREFIX=your-prefix setup_vkd3d_proton install
#* DXVK via:
#      $ WINEPREFIX=your-prefix setup_dxvk install

# If "winecfg" is in the current ${PATH}...
if +command.is winecfg; then
    # void +wine.conf_prefix(str prefix_dirname)
    #
    # Configure the existing 32- or 64-bit WINE prefix rooted at the directory
    # with the passed dirname.
    function +wine.conf_prefix() {
        (( $# == 1 )) || {
            echo 'Expected one WINE prefix dirname.' 1>&2
            return 1
        }

        # Canonicalize this dirname. Why? Because WINE explicitly prohibits
        # relative dirnames: e.g.,
        #     $ WINEPREFIX="." command winecfg
        #     wine: invalid directory . in WINEPREFIX: not an absolute path
        local prefix_dirname; prefix_dirname="$(+path.canonicalize "${1}")"

        # If this WINE prefix directory does *NOT* exist, fail.
        [[ -d "${prefix_dirname}" ]] || {
            echo 'WINE prefix directory "'${prefix_dirname}'" not found.' 1>&2
            return 1
        }
        # Else, this WINE prefix directory exists.

        # Configure this WINE prefix.
        echo 'Configuring WINE prefix "'${prefix_dirname}'"...'
        +wine.make_prefix_64 "${@}"
    }


    # void +wine.make_prefix_64(str prefix_dirname)
    #
    # Create a new 64-bit WINE prefix rooted at the directory with the passed
    # dirname.
    function +wine.make_prefix_64() {
        (( $# == 1 )) || {
            echo 'Expected one WINE prefix dirname.' 1>&2
            return 1
        }

        # Canonicalize this dirname. Why? Because WINE explicitly prohibits
        # relative dirnames: e.g.,
        #     $ WINEPREFIX="." command winecfg
        #     wine: invalid directory . in WINEPREFIX: not an absolute path
        local prefix_dirname; prefix_dirname="$(+path.canonicalize "${1}")"
        echo 'Creating WINE prefix "'${prefix_dirname}'"...'

        # When our one-liner powers combine!
        WINEPREFIX="${prefix_dirname}" command winecfg
    }


    # void +wine.make_prefix_32(str prefix_dirname)
    #
    # Create a new 32-bit WINE prefix rooted at the directory with the passed
    # dirname.
    function +wine.make_prefix_32() {
        # That's how the Unix shell was won.
        WINEARCH='win32' +wine.make_prefix_64 "${@}"
    }


    #FIXME: Improve, please. Ideally, it shouldn't be necessary to manually
    #specify the WINE prefix dirname. Instead, this script should be capable of
    #simply iterating up directories from the passed "executable_filename" until
    #it discovers a directory whose structure resembles that of a WINE prefix.

    # void +wine.run(str prefix_dirname, str executable_filename)
    #
    # Run the Windows-specific executable with the passed filename under the
    # WINE prefix rooted at the directory with the passed dirname.
    function +wine.run() {
        (( $# == 2 )) || {
            echo 'Expected one WINE prefix dirname and one Windows executable filename.' 1>&2
            return 1
        }

        # Canonicalize this dirname. Why? Because WINE explicitly prohibits
        # relative dirnames: e.g.,
        #     $ WINEPREFIX="." command winecfg
        #     wine: invalid directory . in WINEPREFIX: not an absolute path
        local prefix_dirname; prefix_dirname="$(+path.canonicalize "${1}")"
        local executable_filename="${2}"

        # If this WINE prefix directory does *NOT* exist, fail.
        [[ -d "${prefix_dirname}" ]] || {
            echo 'WINE prefix directory "'${prefix_dirname}'" not found.' 1>&2
            return 1
        }
        # Else, this WINE prefix directory exists.

        # Run this Windows executable in this WINE prefix.
        WINEPREFIX="${prefix_dirname}" command wine "${executable_filename}"
    }
fi

# ....................{ FUNCTIONS ~ command : x.org        }....................
# If "startx" is in the current ${PATH}...
if +command.is startx; then
    # str +x()
    #
    # Locally start X.org in a reasonably intelligent manner. Specifically,
    # this function (in order):
    #
    # * Starts the X.org server if needed.
    # * Starts a new X.org client, locally connected to this server.
    # * Creates a new X.org session under this client-server connection,
    #   typically defined by the "${XSESSION}" global in the "/etc/profile.env"
    #   file or a subsidiary thereof (e.g., "/etc/env/90xsession").
    # * Redirects all standard output and error from the "startx" command to
    #   the "~/.xorglog" dotfile.
    function +x() {
        (( $# == 0 )) || {
            echo 'Expected no arguments.' 1>&2
            return 1
        }

        # Start X.org, redirecting both stderr and stdout to a user-specific
        # dot logfile while preserving all terminal output.
        echo 'Starting X.org logged to "~/.xorglog"...'
        command startx 2>&1 | tee ~/.xorglog
    }
fi

# If "xset" is in the current ${PATH}...
if +command.is xset; then
    # str +x.disable_dpms()
    #
    # Disable both Display Power Management Signaling (DPMS) and DPMS-based
    # screen blanking for the current X.org session.
    function +x.disable_dpms() {
        (( $# == 0 )) || {
            echo 'Expected no arguments.' 1>&2
            return 1
        }

        # So it goes.
        echo 'Disabling X.org DPMS and DPMS-based screen blanking...'
        command xset s off -dpms
    }


    # str +x.enable_dpms()
    #
    # Enable both Display Power Management Signaling (DPMS) and DPMS-based
    # screen blanking for the current X.org session.
    function +x.enable_dpms() {
        (( $# == 0 )) || {
            echo 'Expected no arguments.' 1>&2
            return 1
        }

        # Make it so.
        echo 'Enabling X.org DPMS and DPMS-based screen blanking...'
        command xset s on -dpms
    }
fi


# If "xrandr" is in the current ${PATH}...
if +command.is xrandr; then
    # str +x.restore_screen()
    #
    # Restore the resolution and frequency of the current screen to its nominal
    # factory preset, typically after another misbehaving application harmfully
    # changed these settings.
    function +x.restore_screen() {
        (( $# == 0 )) || {
            echo 'Expected no arguments.' 1>&2
            return 1
        }

        # So it goes.
        echo 'Restoring X.org resolution and frequency...'
        command xrandr --output DVI-I-0 --mode 1920x1080 --rate 60
    }
fi

# ....................{ FUNCTIONS ~ command : gui          }....................
# For each GUI command invoked with CLI arguments in the current ${PATH},
# define an alias-like function passing those arguments to that command.
+command.is evince && function ev() {
    command evince "${@}" &!
}
+command.is okular && function ok() {
    command okular "${@}" &!
}

# ....................{ FUNCTIONS ~ linux : grub           }....................
# Functions conditionally dependent upon the GRUB2 boot loader.

# void +grub.install()
#
# Install the current GRUB2 configuration to the appropriate partition.
+command.is grub-mkconfig && function +grub.install() {
    (( $# == 0 )) || {
        echo 'Expected no arguments.' 1>&2
        return 1
    }

    # If the current user is *NOT* the superuser, fail.
    (( EUID == 0 )) || {
        echo '"${USER}" not root.' 1>&2
        return 1
    }

    echo 'Mounting boot partition...'
    mount /boot

    echo
    echo '(Re)configuring GRUB2...'
    grub-mkconfig -o /boot/grub/grub.cfg
}

# ....................{ FUNCTIONS ~ linux : kernel         }....................
# Functions conditionally dependent upon the Linux platform.

# If the canonical directory containing Linux kernel sources exists...
if [[ -d /usr/src/linux ]]; then
    # str +kernel()
    #
    # Compile the current Linux kernel (i.e., "/usr/src/linux") and set of all
    # currently enabled kernel modules, create the tarball containing this
    # compilation, copy this tarball into the boot directory, and configure
    # GRUB2 to load this tarball by default.
    function +kernel() {
        (( $# == 0 )) || {
            echo 'Expected no arguments.' 1>&2
            return 1
        }

        # If the current user is *NOT* the superuser, fail.
        (( EUID == 0 )) || {
            echo '"${USER}" not root.' 1>&2
            return 1
        }

        # If either no kernel exists or an unconfigured kernel exists, fail.
        [[ -f /usr/src/linux/.config ]] || {
            echo \
                'Kernel configuration "/usr/src/linux/.config" not found.' 1>&2
            return 1
        }

        # Isolate all requisite steps to a subshell process. If this is *NOT*
        # done (i.e., if these steps are performed in the current shell
        # process), then suspending this process would:
        # * Erroneously suspend only the current low-level step being performed
        #   rather than the entire high-level process.
        # * All subsequent steps that have yet to be performed would
        #   prematurely fail with non-zero exit status.
        (
            # Change to the directory defining the current kernel.
            pushd /usr/src/linux

            echo 'Mounting boot partition...'
            mount /boot

            echo '(Re)compiling kernel...'
            make -j3

            echo
            echo '(Re)compiling kernel modules (first-party)...'
            make -j3 modules_install

            echo
            echo '(Re)compiling kernel modules (third-party)...'
            emerge @module-rebuild

            echo
            echo '(Re)installing kernel...'
            make install

            # Install the current GRUB2 configuration to the appropriate partition.
            echo
            +grub.install

            # Revert to the prior directory.
            popd
        )
    }
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

# ....................{ ALIASES ~ coreutils               }....................
# Configure "coreutils"-based commands with sane defaults.
alias chmod='chmod --changes --preserve-root'
alias chown='chown --changes --preserve-root'
alias cp='cp --interactive --preserve --verbose'
alias df='df --human-readable'
alias du='du --human-readable --total'
alias mv='mv --interactive --verbose'
alias mkdir='mkdir --parents'
alias rm='rm --interactive --verbose'

# Colour "grep"-like commands with options defined above.
GREP_CORE_OPTIONS="--extended-regexp${_COLOR_OPTION}"
_GREP_OPTIONS="${GREP_CORE_OPTIONS} --binary-files=without-match --initial-tab --line-number"
alias grep="grep ${_GREP_OPTIONS}"
alias egrep="egrep ${_GREP_OPTIONS}"
alias fgrep="fgrep ${_GREP_OPTIONS}"

# Configure "ls"-like commands with options defined above.
_LS_OPTIONS="--all --group-directories-first --human-readable${_COLOR_OPTION}"
alias dir="dir ${_LS_OPTIONS}"
alias vdir="vdir ${_LS_OPTIONS}"

# ....................{ ALIASES ~ abbreviations           }....................
# One-letter abbreviations for brave brevity.
alias c='cp'
alias d='date'
alias e='echo'
alias f='fg'
alias j='jobs'
alias m='mv'
alias t='touch'

# Note that print() is a builtin under zsh but *NOT* bash, but that an alias
# defined below simply aliases "print" to "echo" under bash.
alias p='print'

# Two-letter abbreviations for great justice.
alias ca='cat'
alias cm='chmod'
alias co='chown'
alias cr='cp -R'
alias gi='git'
alias in='info'
alias le='less'
alias md='mkdir'
alias mo='mount'
alias rd='rmdir'

# Three-letter abbreviations for tepid tumescence.
alias cmr='chmod -R'
alias cor='chown -R'
alias lns='ln -s'
alias umo='umount'

# Four-letter abbreviations for fiery fenestration. Specifically:
#
# * "lram", recursively listing all metal albums sorted by mtime.
alias lram='+dir.list_subdirs_mtime_depth ~/pub/audio/metal 3'

# ....................{ ALIASES ~ cli                     }....................
# Abbreviations conditionally dependent upon external commands *NOT* guaranteed
# to be installed by default (i.e., not bundled with "coreutils").

# CLI-specific one-to-one abbreviations.
+command.is alsamixer && alias am='alsamixer'
+command.is fzf && alias fz='fzf'
+command.is btop && alias bt='btop'
+command.is htop && alias ht='htop'
+command.is ipython3 && alias ipy='ipython3'
+command.is links && alias li='links'
+command.is mangal && alias ml='mangal'
+command.is ncdu && alias du='ncdu'
+command.is ncmpcpp && alias n='ncmpcpp'  # the command whose name nobody knows
+command.is jupyter-notebook && alias nb='python3.9 -m notebook'
+command.is perldoc && alias poc='perldoc'
+command.is ping && alias pi='ping'

# CLI-specific one-to-many abbreviations.
if +command.is dmesg; then
    alias dm='dmesg'
    alias dmt='dmesg | tail --follow'  # this abbreviation is uncoincidental
fi

if +command.is ip; then
    alias ipa='ip addr'
fi

if +command.is pkgdev; then
    alias pd='pkgdev'
    alias pdm='pkgdev manifest'
fi

if +command.is vcsh; then
    alias vc='vcsh'
    alias vce='vcsh enter'
fi

# ....................{ ALIASES ~ cli : grep              }....................
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
# in order of largely anecdotal efficiency, create the following aliases for
# the first such command in the current ${PATH}:
#
# * "g", aliased to this command.
# * "gr", aliased to this command passed the standard "-r" option, performing
#   recursive operation.
# * "gri", aliased to this command passed the standard "-r" and "-i" options,
#   performing case-insensitive recursive operation.
for _GREP_COMMAND in rg ag sift ack pt grep; do
    # If this command exists...
    if +command.is "${_GREP_COMMAND}"; then
        # Alias "g" to this command.
        alias g="${_GREP_COMMAND}"

        # If this command is ripgrep...
        if [[ "${_GREP_COMMAND}" == 'rg' ]]; then
            # Configure ripgrep.
            alias rg="rg --heading --hidden --line-number --one-file-system${_COLOR_OPTION}"

            # Alias "gr" to the same command as well. By design, ripgrep
            # *ALWAYS* operates recursively.
            alias gr='g'
            alias gri='g --ignore-case'
        # Else, create all remaining aliases with short (i.e., non-GNU and
        # hence portable) options. Although these simplistic assumptions may
        # not always hold, they're certainly better than nothing.
        else
            alias gr='g -r'
            alias gri='g -ri'
        fi

        # Cease iteration.
        break
    fi
done

# ....................{ ALIASES ~ cli : list              }....................
# If an alternative "ls" command (e.g., eza) is available, alias the family of
# "l*" aliases to the most efficient such command.
if +command.is eza; then
    alias ls='eza -a1   --icons=auto' # short list
    alias  l='eza -alh  --icons=auto' # long list
    alias ld='eza -alhD --icons=auto' # long list dirs
    alias ll='eza -alh  --icons=auto --sort=name --group-directories-first' # long list all
    alias lr='ll --recurse' # long list all recursive
# Else, fallback to vanilla "ls" for sanity.
else
    alias ls="ls ${_LS_OPTIONS}"
    alias l='ls'
    alias ll='ls -l'
    alias lr='+dir.list_recursive'
fi

# ....................{ ALIASES ~ cli : linux              }....................
# Abbreviations conditionally dependent upon Linux-specific external commands.

# Configure Linux-specific commands with sane defaults.
+command.is lsblk && alias lsblk='lsblk --fs'

# ....................{ ALIASES ~ cli : linux : arch       }....................
# Abbreviations conditionally dependent upon Arch-specific external commands.

# If the "pacman" command is available, this is Arch Linux. In this case...
if +command.is pacman; then
    # In case a command is not found, try to find the package that has it
    function command_not_found_handler {
        local purple='\e[1;35m' bright='\e[0;1m' green='\e[1;32m' reset='\e[0m'
        printf 'zsh: command not found: %s\n' "$1"
        local entries=( ${(f)"$(/usr/bin/pacman -F --machinereadable -- "/usr/bin/$1")"} )
        if (( ${#entries[@]} )) ; then
            printf "${bright}$1${reset} may be found in the following packages:\n"
            local pkg
            for entry in "${entries[@]}" ; do
                local fields=( ${(0)entry} )
                if [[ "$pkg" != "${fields[2]}" ]] ; then
                    printf "${purple}%s/${bright}%s ${green}%s${reset}\n" "${fields[1]}" "${fields[2]}" "${fields[3]}"
                fi
                printf '    /%s\n' "${fields[4]}"
                pkg="${fields[2]}"
            done
        fi
        return 127
    }

    # Detect the AUR wrapper
    if pacman -Qi yay &>/dev/null ; then
       aurhelper="yay"
    elif pacman -Qi paru &>/dev/null ; then
       aurhelper="paru"
    fi

    function in {
        local pkg="$1"
        if pacman -Si "$pkg" &>/dev/null ; then
            sudo pacman -S "$pkg"
        else
            "$aurhelper" -S "$pkg"
        fi
    }

    # Helpful aliases
    # alias yar='$aurhelper -Rns' # uninstall package
    alias un='$aurhelper -Rns' # uninstall package
    alias up='$aurhelper -Syu' # update system/package/aur
    alias pl='$aurhelper -Qs' # list installed package
    alias pa='$aurhelper -Ss' # list availabe package
    alias pc='$aurhelper -Sc' # remove unused cache
    alias po='$aurhelper -Qtdq | $aurhelper -Rns -' # remove unused packages, also try > $aurhelper -Qqd | $aurhelper -Rsu --print -
fi

# ....................{ ALIASES ~ cli : linux : gentoo     }....................
# Abbreviations conditionally dependent upon Gentoo-specific external commands.

# If the "emerge" command is available, this is Gentoo Linux. In this case...
if +command.is emerge; then
    # void +gentoo.bump_world()
    #
    # Automagically update this Gentoo Linux system. Specifically (in order):
    # * Fetch the most recent copies of the official Portage tree *AND* all
    #   unofficial third-party overlays locally added to this system.
    # * Update all packages in the @world set.
    # * Update all relevant "eselect" modules.
    function +gentoo.bump_world() {
        (( $# == 0 )) || {
            echo 'Expected no arguments.' 1>&2
            return 1
        }

        # Isolate all requisite steps to a subshell process. If this is *NOT*
        # done (i.e., if these steps are performed in the current shell
        # process), then suspending this process would:
        # * Erroneously suspend only the current low-level step being performed
        #   rather than the entire high-level process.
        # * All subsequent steps that have yet to be performed would
        #   prematurely fail with non-zero exit status.
        (
            echo 'Bumping ebuild repositories...'
            command emerge --sync
            echo

            +gentoo.emerge_world
            echo
        )
    }

    # void +gentoo.emerge_world()
    #
    # Automagically update all packages in both the @world and
    # @preserved-rebuild package sets.
    function +gentoo.emerge_world() {
        (( $# == 0 )) || {
            echo 'Expected no arguments.' 1>&2
            return 1
        }

        # Update all locally installed packages that were previously installed
        # via an explicit invocation of the "emerge" command and thus implicitly
        # added by Portage to the @world set.
        echo 'Bumping @world packages...'
        command emerge \
            --deep \
            --newrepo \
            --newuse \
            --update \
            --verbose \
            @world
        echo

        # Update all locally installed packages requiring obsolete libraries.
        echo 'Bumping @preserved-rebuild packages...'
        command emerge --exclude dev-lang/python @preserved-rebuild
        echo

        +gentoo.bump_eselect
        echo

        # Update all shell variables updated by prior bumping. Note that this
        # exact command is advised when bumping numerous modules.
        echo 'Bumping shell variables...'
        . /etc/profile

        # Override system-wide shell variables with user-specific variants.
        . ~/.bashrc
    }

    # void +gentoo.bump_eselect()
    #
    # Automagically bump all "eselect" modules that we typically do *NOT*
    # actively manage to their most recent versions. Doing so is essential to
    # avoiding issues with obsolete package versions. For safety, this function
    # is automatically called after every world update. Note that:
    # * This is an automated alternative to "emerge --depclean --ask". While
    #   performing that command *WOULD* be preferable in the ideal world, doing
    #   so also:
    #   * Consumes excess spare time we simply do *NOT* have.
    #   * Destroys packages that may, in fact, be required. Filtering the list
    #     of packages to be depcleaned of packages that should *NEVER* be
    #     depcleaned is a considerable maintenance burden. See: "spare time."
    function +gentoo.bump_eselect() {
        (( $# == 0 )) || {
            echo 'Expected no arguments.' 1>&2
            return 1
        }

        echo 'Bumping "eselect" modules...'

        # Names of all safely bumpable "eselect" modules.
        local -a ESELECT_MODULE_NAMES=(
            binutils gcc java-vm lua ruby rust wine wxwidgets
        )

        # For the name of each such module...
        local eselect_module_name eselect_module_newest
        for eselect_module_name in "${ESELECT_MODULE_NAMES[@]}"; do
            echo "Bumping \"eselect ${eselect_module_name}\" module to:"

            # Last "eselect" entry for this module, typically (but *NOT*
            # necessarily always) corresponding to the most recently installed
            # stable package atom for this module. This line resembles:
            #      [4] x86_64-pc-linux-gnu-11.2.1
            #
            # Dismantled, this is:
            # * "sed ...", stripping all empty lines. The output of the "list"
            #   subcommand for most but *NOT* all "eselect" modules contains no
            #   empty lines. Exceptions include "eselect java-vm list", which
            #   oddly *ALWAYS* emits a trailing blank line. (It is what it is.)
            # * "tail ...", printing only the last line.
            eselect_module_newest_line="$(command eselect "${eselect_module_name}" list | \
                command sed '/^$/d' | \
                command tail -n 1)"
            echo "${eselect_module_newest_line}"

            # "eselect" list number parsed from this entry (e.g., "4" above).
            eselect_module_newest_index="$(echo "${eselect_module_newest_line}" | \
                command sed -r 's~^\s*\[([[:digit:]]+)\].*$~\1~')"

            #FIXME: Advise users to manually set their user Java VM as well.
            # If this is the non-standard "eselect java-vm" module, bump only
            # the system Java VMs to this entry.
            if [[ "${eselect_module_name}" == java-vm ]]; then
                command eselect "${eselect_module_name}" \
                    set system "${eselect_module_newest_index}"
            # Else, bump this module to this entry.
            else
                command eselect "${eselect_module_name}" \
                    set "${eselect_module_newest_index}"
            fi
        done
    }

    # Unconditional Gentoo Linux-specific aliases.
    alias eb='ebuild'
    alias em='emerge'
    alias em1='emerge --oneshot'
    alias eq='equery'
    alias es='eselect'
    alias rcs='rc-service'
    alias rcu='rc-update'

    # Alias "emnocc" to run the "emerge" command with "ccache"-based caching
    # temporarily disabled, for packages failing under that caching.
    alias emnocc='FEATURES="-ccache" emerge'

    # Alias "emsw" to update both Portage *AND* all locally installed packages.
    alias emsw='+gentoo.bump_world'

    # Alias "emw" to update all locally installed packages *WITHOUT* updating
    # Portage first.
    alias emw='+gentoo.emerge_world'

    # Conditional Gentoo Linux-specific aliases.
    +command.is dispatch-conf && alias di='dispatch-conf'
    +command.is pkgcheck && alias pcs='pkgcheck scan'
    +command.is repoman && alias re='repoman'

    # If this shell supports color, force "eix" to unconditionally emit ANSI
    # color sequences (even when piped to "less").
    +command.is eix && [[ -n "${_IS_COLOR}" ]] && alias eix='eix --force-color'
fi

# ....................{ ALIASES ~ cli : shell              }....................
# Abbreviations conditionally dependent upon the current shell.

# Alias:
#
# * "wh" to list the absolute filenames and/or definitions of all external
#   commands, shell aliases, and shell functions with the passed names.
# * "print" to "echo" under bash. Under zsh, the two are effectively synonyms
#   of one another for most intents and purposes.
if   [[ -n "${IS_ZSH}"  ]]; then
    alias wh='whence -acS -x 4'
elif [[ -n "${IS_BASH}" ]]; then
    alias wh='type -a'
    alias print='echo'
fi

# ....................{ ALIASES ~ cli : linux : systemd    }....................
# Abbreviations conditionally dependent upon Systemd-specific external commands.

# If the "systemctl" command is available, Systemd is available. In this case...
if +command.is systemctl; then
    # Manage system-wide Systemd units.
    alias sys='sudo systemctl'

    # Start the passed Systemd unit under the current user *AND* autostart this
    # unit under this user on *ALL* subsequent logins as this user.
    alias syue='systemctl enable --now --user'

    # Define an alias tailing the current system logfile. By default, the
    # "journalctl" command *HEADS* rather than *TAILS* this logfile -- a largely
    # useless default that only wastes already scarce time.
    alias jo='journalctl -e'
fi

# ....................{ ALIASES ~ daemon                   }....................
# Daemon-specific abbreviations, typically suffixed by "&!" to permit
# background daemons to be spawned in a detached manner from the current shell.

# Jupyter Notebook. Associating notebooks with specific Python interpreters and
# interpreter versions (or "kernels" in Jupyter jargon) is non-trivial.
#
# First, there exists a one-to-many mapping between each notebook and each
# kernel. Each notebook is associated with exactly one kernel at creation time;
# after creation, that association may be modified via the "Kernel" -> "Change
# kernel" menu item.
#
# Second, kernels are both created and configured with JSON-formatted
# configuration files in the following directories:
# * "/usr/share/jupyter/kernels", the system-wide kernel directory.
# * "~/.local/share/jupyter/kernels", the user-specific kernel directory.
#
# The latter takes precedence over the former. The basename of each
# subdirectory in each of these directories is the name of an available kernel.
# Ergo:
# * Deleting a kernel requires deleting all subdirectories whose basename is
#   the name of that kernel from all of these directories.
# * Creating a kernel requires creating a new subdirectory whose basename is
#   the name of that kernel in one or more of these directories.
#
# Third, each kernel is configured via the "kernel.json" file in its
# subdirectory of these directories.
#
# Fourth, the ambiguous "python3" kernel should typically be avoided. Why?
# Because that kernel is configured by the
# "/usr/share/jupyter/kernels/python3/kernel.json" file to refer to the most
# recent CPython version installed on the local machine -- which rarely
# coincides with the contents of "/etc/python-exec/python-exec.conf". Instead,
# consider creating version-specific Python kernels for disambiguity.
#
# Fifth, Jupyter should typically be run as a non-superuser rather than the
# superuser. Why? Beyond the obvious security concerns, the superuser is
# unlikely to have a sane "~/.local/share/jupyter/kernels" directory, in which
# case the only kernels available will be the default system-wide kernels
# (e.g., "python3") -- which should typically be avoided as above.
+command.is jupyter-notebook && alias jn='jupyter-notebook &!'

# ....................{ ALIASES ~ gui                     }....................
# GUI-specific abbreviations, typically suffixed by "&!" to permit windowed
# applications to be spawned in a detached manner from the current shell.
+command.is antimicrox && {
    alias ax='antimicrox &!'
    # alias and='antimicrox --daemon --profile ~/yml/kiseki-linux/lutris/2004-sora_no_kiseki_fc/sora-no-kiseki-fc-ps4.gamecontroller.amgp &!'
}
+command.is assistant    && alias ass='assistant &!'      # Don't judge me.
+command.is audacity     && alias aud='audacity &!'
+command.is chromium     && alias ch='chromium -incognito &!'
+command.is citra-qt     && alias cq='citra-qt &!'
+command.is clementine   && alias cl='clementine &!'
+command.is deadbeef     && alias de='deadbeef &!'
+command.is deluge-gtk   && alias dg='deluge-gtk &!'
+command.is fbreader     && alias fb='fbreader &!'
+command.is firefox      && alias ff='firefox &!'
+command.is filelight    && alias fl='filelight &!'
+command.is font-manager && alias fm='font-manager &!'
+command.is geeqie       && alias gq='geeqie &!'
+command.is gimp         && alias gm='gimp &!'
+command.is gparted      && alias gp='gparted &!'
+command.is libreoffice  && alias lo='libreoffice &!'
+command.is lutris       && alias lu='lutris &!'
+command.is mcomix       && alias mc='mcomix &!'
+command.is nicotine     && alias ni='nicotine &!'
+command.is playonlinux  && alias pol='playonlinux &!'
+command.is qtcreator    && alias qtc='qtcreator &!'
+command.is retroarch    && alias ra='retroarch &!'
+command.is rhythmbox    && alias hh='rhythmbox &!'
+command.is simple-scan  && alias sc='simple-scan &!'
+command.is strawberry   && alias sb='strawberry &!'
+command.is torbrowser-launcher && alias tb='torbrowser-launcher &!'

# If Calibre is installed...
if +command.is calibre; then
    # Alias "cb" to Calibre.
    alias cb='calibre &!'

    # Force Calibre to globally enable night mode by default, ignoring both
    # system- and user-specified themes and color schemes. Sadly, the Linux
    # port of Calibre currently fails to expose these settings in its UI. See:
    #     https://askubuntu.com/questions/1053497/how-do-i-get-a-dark-theme-night-mode-in-calibre-ebook-viewer
    export CALIBRE_USE_DARK_PALETTE=1
    export CALIBRE_USE_SYSTEM_THEME=0
fi

# ....................{ ALIASES ~ gui : args              }....................
# GUI-specific abbreviations accepting arguments and thus *NOT* trivially
# definable as one-line shell aliases, typically suffixed by "&!". (See above.)
+command.is antimicrox && {
    alias vl='+video.queue'

    # void +video.queue()
    #
    # Queue all of the passed video files (in the passed order) for sequential
    # playing with the VLC GUI.
    function +video.queue() {
        (( $# >= 1 )) || {
            echo 'Expected one or more video filenames.' 1>&2
            return 1
        }

        # Trivial one-liners for ultimate justice.
        command vlc "${@}" &!
    }
}

# ....................{ COMPLETIONS                        }....................
# If the current shell is zsh...
if [[ -n "${IS_ZSH}"  ]]; then
    # Enable all default completions.
    zstyle :compinstall filename "${HOME}/.zshrc"

    # Enable all Ubuntu-specific default completions. Since Ubuntu enables these
    # by default for new "zsh" installs, we politely assume they are sane.
    zstyle ':completion:*' auto-description 'specify: %d'
    zstyle ':completion:*' completer _expand _complete _correct _approximate
    zstyle ':completion:*' format 'Completing %d'
    zstyle ':completion:*' group-name ''
    zstyle ':completion:*' menu select=2
    eval "$(dircolors -b)"
    zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
    zstyle ':completion:*' list-colors ''
    zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
    zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
    zstyle ':completion:*' menu select=long
    zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
    zstyle ':completion:*' use-compctl false
    zstyle ':completion:*' verbose true

    zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
    zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

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

    # If bash support for Fuzzy File Finder (FZF) is available, do so. Note
    # that the corresponding zsh-specific test is intentionally performed in
    # the ".zshrc" script rather than this script. See that script for details.
    [[ -f ~/.fzf.bash ]] && source ~/.fzf.bash
fi

# ....................{ CUSTOMIZATIONS                     }....................
#FIXME; Sadly, the following command is Ubuntu-specific and hence fails under
#Gentoo with the following inscrutable error:
#    -bash: eval: line 171: syntax error near unexpected token `newline'
#    -bash: eval: line 171: `Usage: lesspipe <file>'
#The culprit is, of course, "lesspipe". As there appears to exist *NO*
#standardized "lesspipe" command, each Linux distribution ships its own
#distribution-specific mutually-incompatible variant of "lesspipe". Generalizing
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

# ....................{ LOGIN                             }....................
# str +login()
#
# (Re)perform login shell startup logic. Specifically:
#
# * If the "keychain" command is in the current ${PATH} *AND*:
#   * If no "ssh-agent" daemon is currently running:
#     * Spawn a long-running "ssh-agent" daemon.
#     * Cache passphrases for user-specific private keys with this agent.
#   * Else, reuse the passphrases previously cached with this agent.
# * Spawn a new user-specific "mpd" daemon if:
#   * The "mpd" command is in the current ${PATH}.
#   * A user-specific MPD configuration directory is found.
#   * *NO* "mpd" daemon is currently running.
function +login() {
    # Note that the current passphrase accepted by any private key can be
    # trivially validated manually by passing that key to the OpenSSH
    # "ssh-add" command: e.g.,
    #     $ ssh-add ~/.ssh/id_rsa
    if +command.is keychain; then
        eval "$( \
            keychain \
            --eval --ignore-missing --quick \
            ~/.ssh/id_dsa ~/.ssh/id_ecdsa ~/.ssh/id_ed25519 ~/.ssh/id_rsa \
        )"
    fi

    #FIXME: Currently disabled by "false &&".
    # If the "mpd" command is in the current ${PATH} *AND* no "mpd" daemon is
    # currently running...
    if false && +command.is mpd; then
    # if +command.is mpd; then
        # Absolute filename of the user-specific MPD configuration file if any
        # or the empty string otherwise, preferring "~/.mpd/mpd.conf" if that
        # file exists or falling back to "~/.config/mpd/mpd.conf" otherwise.
        mpd_conf_filename=~/.mpd/mpd.conf
        [[ -f "${mpd_conf_filename}" ]] || {
            mpd_conf_filename=~/.config/mpd/mpd.conf
            [[ -f "${mpd_conf_filename}" ]] || mpd_conf_filename=
        }

        # If a user-specific MPD configuration directory was found and *NO*
        # "mpd" daemon is currently running, spawn a new such daemon.
        #
        # Note that testing the existence of a non-zero "${MPD_HOME}/pid" file
        # tested would be insufficient, as the location of that file is
        # configurable via "${MPD_HOME}/mpd.conf".
        if [[ -n "${mpd_conf_filename}" ]] &&
           ! +process.has_basename 'mpd'; then
            echo 'Starting "mpd" from: '${mpd_conf_filename}
            command mpd "${mpd_conf_filename}"
        fi
    fi
}

# If this is a login shell, (re)perform login shell startup logic.
[[ "${_IS_LOGIN}" ]] && +login

# ....................{ CLEANUP                           }....................
# Export all variables defined above and referenced internally by aliases
# and/or functions defined below to subprocesses.
export IS_BASH IS_ZSH XDG_RUNTIME_DIR

# Prevent all remaining variables defined above from polluting the environment.
unset \
    _COLOR_OPTION \
    _GREP_COMMAND \
    _GREP_OPTIONS \
    _IS_COLOR \
    _IS_LOGIN \
    _LS_OPTIONS \
    _MPD_CONF_FILENAME

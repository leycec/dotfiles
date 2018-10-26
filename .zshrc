#!/usr/bin/env bash
# ====================[ .zshrc                            ]====================
#
# --------------------( LICENSE                           )--------------------
# Copyright 2008-2018 by Cecil Curry.
# See "LICENSE" for further details.
#
# --------------------( SYNOPSIS                          )--------------------
# User-specific startup script for non-login zsh shells.
#
# --------------------( SYNOPSIS                          )--------------------
# This file is sourced by *ALL* interactive zsh shells on startup, including
# numerous low-level fragile shells (e.g., "scp", "rcp") intolerate of output.
# To avoid spurious issues, both this script and all commands transitively run
# by this script *MUST* run silently (i.e., output nothing).

# ....................{ INTERACTIVE                       }....................
# If the current shell is non-interactive, silently reduce to a noop to avoid
# breaking low-level fragile shells (e.g., "scp", "rcp") intolerate of output.
[[ -o interactive ]] || return
# Else, the current shell is interactive. To quoth the Mario: "Let's a-go!"

# ....................{ UNEDITED                          }....................
#FIXME: Augment all of the following with sane commentary and structure.

HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt appendhistory autocd extendedglob nomatch notify
unsetopt beep
bindkey -v

zstyle :compinstall filename "${HOME}/.zshrc"

autoload -Uz compinit
compinit

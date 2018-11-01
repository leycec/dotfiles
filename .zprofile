#!/usr/bin/env zsh
# ====================[ .zprofile                         ]====================
#
# --------------------( LICENSE                           )--------------------
# Copyright 2008-2018 by Cecil Curry.
# See "LICENSE" for further details.
#
# --------------------( SYNOPSIS                          )--------------------
# User-specific startup script for login zsh shells.

# ....................{ MAIN                              }....................
# If a startup script for non-login zsh shells is defined for the current
# user, source this script as recommended by official "info" pages for zsh.
[[ -f ~/.zshrc ]] && source ~/.zshrc

#!/usr/bin/env bash
# ====================[ .bash_profile                      ]====================
#
# --------------------( LICENSE                            )--------------------
# Copyright 2008-2018 by Cecil Curry.
# See "LICENSE" for further details.
#
# --------------------( SYNOPSIS                           )--------------------
# User-specific startup script for login bash shells.

# ....................{ MAIN                               }....................
# If a startup script for non-login bash shells is defined for the current
# user, source this script as recommended by official "info" pages for bash.
[[ -f ~/.bashrc ]] && source ~/.bashrc

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

# ....................{ MAIN                              }....................
# Defer to the shell-agnostic startup script for non-login bash and zsh shells.
source ~/.bashrc

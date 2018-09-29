#!/usr/bin/env bash
# ====================[ .xinitrc                          ]====================
#
# --------------------( LICENSE                           )--------------------
# Copyright 2015-2018 by Cecil Curry.
# See "LICENSE" for further details.
#
# --------------------( SYNOPSIS                          )--------------------
# User-specific X.org initialization script.
#
# --------------------( PRECEDENCE                        )--------------------
# This script takes precedent over the system-wide analogue of this script,
# "/etc/X11/xinit/xinitrc". According to the "xinit" man-page, "To determine
# the client to run, startx first looks for a file called .xinitrc in the
# user's home directory. If that is not found, it uses the file xinitrc in
# the xinit library directory, /etc/X11/xinit/xinitrc."
#
# This script, therefore, must perform tasks -- such as importing the
# "/etc/X11/Xmodmap" file -- traditionally performed by that system-wide
# script.
#
# --------------------( PREFERENCES                       )--------------------
# Set X.org preferences prior to setting Xresources and Xmodmap preferences, as
# the X.org preferences depend on symbolic key mappings modified by the latter.

# ....................{ SETTINGS                          }....................
# Establish all X11-wide custom settings (e.g., monitor, keyboard).
source /home/leycec/bash/xorg_init

# ....................{ WINDOW MANAGER                    }....................
if [[ -n "$XSESSION" ]]; then
    XSESSION_SCRIPT="/etc/X11/Sessions/$XSESSION"

    if [[ -x "$XSESSION_SCRIPT" ]]; then
        exec "$XSESSION_SCRIPT"
    else
        echo ".xinitrc: no window manager found" 1>&2
        exit 1
    fi
else
    echo ".xinitrc: no \"XSESSION\" defined" 1>&2
    exit 1
fi

# --------------------( WASTELANDS                        )--------------------
#FUXME: Due to Kinesis remapping, neither of the following two will work. We
#need the keycodes of the physical keys we've mapped such logical keys to.

# Swap ":" with ";" and "`" with "~", the latter of which are more frequently
# used for both coding and shell use. While the default keycodes for such keys
# are 47 and 49 respectively for QWERTY keyboards, such keycodes do *NOT* apply
# to remappings performed by Kinesis keyboards. To find the latter, see "xev".
# command xmodmap -e "keycode 47 = colon semicolon"
# command xmodmap -e "keycode 49 = asciitilde grave"

# For the Samsung SyncMaster 943BWX, force the monitor to accept a higher
# refresh rate in Hz than its default rate of 60Hz.
# command xrandr --output VGA-0 --mode 1440x900 --rate 75 --dpi 89

# ....................{ COLOR TEMPERATURE                 }....................
# Implicitly adjust the color temperature of the current display given the
# current time of day and geophysical location. To avoid privacy-invasive
# lookups, consider explicitly specifying such location. Dismantled, this is:
#
# * "-l ${latitude}:${longitude}", where such latitude and longitude should
#   correspond to that of the current geophysical location.
# redshift -l 44.7667:-76.6833

# Run the "appropriate" window manager as specified by:
#source "/etc/rc.conf"
# echo ".xinitrc: no \"XSESSION\" defined in \"/etc/rc.conf\"!" 1>&2

#if   type -p "fluviola" &> /dev/null; then
#    exec     "fluviola"
#elif type -p "fvwm-crystal" &> /dev/null; then
#    exec     "fvwm-crystal"
#elif type -p "fvwm" &> /dev/null; then
#    exec     "fvwm"
#else

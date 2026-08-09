---@module 'hl'
-- --------------------( LICENSE                           )--------------------
-- Copyright 2025-2026 by Cecil Curry.
-- See "LICENSE" for further details.
--
-- --------------------( SYNOPSIS                          )--------------------
-- Hyprland configuration optimized for use with HYDE (HYperland Desktop
-- Environment). In other words:
--
-- █░█ █▀ █▀▀ █▀█   █▀█ █▀█ █▀▀ █▀▀ █▀
-- █▄█ ▄█ ██▄ █▀▄   █▀▀ █▀▄ ██▄ █▀░ ▄█
--
-- --------------------( COMMANDS                          )--------------------
-- Useful Hyprland-related commands include:
-- * Manually reload Hyprland *AFTER* modifying this configuration file:
--       $ hyprctl reload
--
-- --------------------( LUA                               )--------------------
-- Lua syntax shares only superficial similarities to Python. Whereas Python
-- largely prefers human-readable English words, Lua adopted the more typical
-- non-obvious syntax-based approach. For example:
-- * "A .. B", concatenates strings A and B: e.g.,
--        "Hello ".."World" == "Hello World"
-- * "#A", the length of container A: e.g.,
--        #"Hello" == 5
--
-- --------------------( SEE ALSO                          )--------------------
-- * Official documentation on Hyprland variables configurable via this file:
--   https://wiki.hypr.land/0.46.0/Configuring/Variables/#custom-accel-profiles
-- * Default HYDE "userprefs.conf" template:
--   https://github.com/prasanthrangan/hyprdots/blob/main/Configs/.config/hypr/userprefs.t2

-- ....................{ TODO                              }....................
--FIXME: Migrate to Lua! Super-non-trivial. What a complete mess:
--* We need to follow these instructions *EXTREMELY* closely:
--      https://github.com/HyDE-Project/HyDE/blob/master/MIGRATION-LUA.md

-- ....................{ VARIABLES ~ hyprland              }....................
-- Define Hyprland-specific global variables globally accessible to *ALL*
-- subsequently run Hyprland configuration files (including this file).

-- Absolute filename of the third-party "kittydrop" Bash script run below.
local kittydrop = "/home/leycec/bin/kittydrop"

-- Alias the "mainMod" global referenced throughout key bindings defined below
-- to the standard <Super> key (e.g., <Windows> key).
local mainMod = "SUPER"

--FIXME: Doesn't appear to do anything, sadly. *sigh*
-- Absolute or relative name of the command (i.e., executable file) responsible
-- for locking the screen on idle *OR* the empty string to disable locking. See
-- the "hypridle.conf" configuration file for the default value of this setting.
-- $IDLE =
local LOCKSCREEN = ""

-- ....................{ VARIABLES ~ shell                 }....................
-- Define POSIX-compliant shell environment variables globally accessible to
-- *ALL* subsequently run processes (including this process).
-- Define an obscure SSH-specific hack required to permissively cache *ALL* SSH
-- passwords on the first successful entry of those passwords for the duration
-- of the current boot cycle. See also these related configuration files:
--     ~/.config/systemd/user/ssh-agent.service
--     ~/.ssh/config

hl.env("SSH_AUTH_SOCK", os.getenv("XDG_RUNTIME_DIR") .. "/ssh-agent.socket")

-- ....................{ KEYS                              }....................
-- User-specific key bindings, overriding the default key bindings configured by
-- the "keybindings.conf" file. Note that HYDE silently replaces the contents of
-- the "keybindings.conf" file on each update, implying that file to *NOT* be
-- safely editable. Instead, configure key bindings in this file.

hl.config({
    binds = {
        -- Allow the Hyprland-specific "movefocus" command (bound by default to
        -- the four cardinal <Super-Arrow key> key bindings) to cycle between
        -- windows, even when the current window is full screen.
        movefocus_cycles_fullscreen = true,
    },
})

hl.config({
    input = {
        -- Disable <Numlock> by default. For some inane reason, Hyprland
        -- actually enables <Numlock> by default. *facepalm*
        numlock_by_default = false,
    },
})

-- ....................{ KEYS ~ windows                    }....................
-- Rebind default key bindings unbound below to alternate key bindings,
-- copy-pasted as is from the official "keybindings.conf" file.
-- First, unbind all existing bindings currently bound to these keys for safety.
hl.unbind("ALT + Return")
hl.unbind(mainMod .. " + Space")
hl.unbind(mainMod .. " + Backspace")
hl.unbind(mainMod .. " + Escape")
hl.unbind(mainMod .. " + W")

-- Bind <ALT+Enter> to toggle fullscreen mode for the current window.
--
-- Note that this used to be the Hyde default. For unknown reasons I personally
-- find suspicious, Hyde now binds this toggle to... <Shift-F11>!? Sheer madness.
hl.bind("ALT + Return", hl.dsp.window.fullscreen())

-- Bind <Super+Spacebar> to a Kuake-like workspace-specific Kitty terminal.
-- Specifically, toggle between either:
-- * If a unique Kitty terminal isolated to the current workspace is *NOT* the
--   currently focused window, focus this terminal.
-- * Else, this terminal is the currently focused window. In this case, focus
--   away from this terminal to the next window in this workspace.
hl.bind(
    mainMod .. " + Space",
    hl.dsp.exec_cmd("/home/leycec/bin/kittydrop")
)

-- Bind <Super+ALT+Delete> to immediately kill the current window.
hl.bind(
    mainMod .. " + ALT + Backspace",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/dontkillsteam.sh")  -- killactive, kill the window on focus
)

-- Bind <Super+ALT+Escape> to interactively shutdown the current session.
hl.bind(
    mainMod .. " + ALT + Escape",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/logoutlaunch.sh 1")  -- logout menu
)

-- Bind <Super+w> to toggle Waybar visibility on and off.
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("killall waybar || waybar")) -- toggle waybar

-- ....................{ KEYS ~ workspace                  }....................
-- Switch workspaces with <mainMod+[w-v]>. By default, Hyprland binds keys to
-- switch workspaces with <mainMod+[1-9]>. To reduce RSI, we strongly prefer
-- common key bindings to be situated about the home keys.
--
-- Note that:
-- * Alphabetic keys *MUST* be bound to their uppercase variants. Why? No idea.
--   Binding alphabetic keys to their lowercase variants fails to unbind the
--   default bindings bound to those keys. Presumably, this is because those
--   default bindings were bound to the uppercase variants of these keys and can
--   thus *ONLY* be unbound to the same uppercase variants. In other words:
--   * Key bindings are case-*INSENSITIVE.* However...
--   * Key unbindings are case-*SENSITIVE.* This smells like a Hyprland bug that
--     will probably never be resolved. Let's just roll with the punches, folks.

-- First, unbind all existing bindings currently bound to these keys for safety.
hl.unbind(mainMod .. " + E")
hl.unbind(mainMod .. " + U")
hl.unbind(mainMod .. " + P")  -- <-- unbinds default screen capture key binding
hl.unbind(mainMod .. " + period")
hl.unbind(mainMod .. " + comma")
hl.unbind(mainMod .. " + O")
hl.unbind(mainMod .. " + Q")  -- <-- unbinds default window killing key binding
hl.unbind(mainMod .. " + J")  -- <-- unbinds default window layout key binding
hl.unbind(mainMod .. " + K")  -- <-- unbinds default keyboard layout key binding

-- Next, rebind workspace switching to these keys.
--
-- Additionally, for each workspace, dynamically bind <Super+t> to transparently
-- open either a new Kitty terminal *OR* a previously opened Kitty terminal as a
-- Kuake-style dropdown isolated to this workspace.
--
-- Note that these dynamic bindings are effectively all trivial copy-pastes of
-- one another with only minute changes. Sadly, the Hyprland scripting language
-- isn't exactly Python. The result violates even the Don't Repeat Yourself
-- (DRY) Principle but is probably the best that can be done for now. We sigh.
hl.bind(mainMod .. " + E", hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + U", hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + P", hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + period", hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + comma", hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + O", hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + Q", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ workspace = 9 }))

-- ....................{ MOUSE                             }....................
-- General input configuration generically applicable to both keyboard and
-- mouse devices.

hl.config({
    input = {
        -- Mouse acceleration profile, defined as either:
        -- * "adaptive," the default dynamic acceleration profile.
        -- * "flat," a static acceleration profile that simply applies a
        --   constant factor to all device deltas, regardless of the speed of
        --   motion.
        -- * "custom," a custom acceleration profile defined by the user. See:
        --   https://wiki.hypr.land/0.46.0/Configuring/Variables/#custom-accel-profiles
        accel_profile = "adaptive",

        -- Mouse sensitivity in the inclusive floating-point range [-1.0, 1.0].
        sensitivity = 0.6,

        --FIXME: No idea, bro. *sigh*
        -- follow_mouse = 1
        -- follow_mouse = 0
        -- float_switch_override_focus = 1
        -- float_switch_override_focus = 0
    },
})

-- Mouse cursor configuration.
hl.config({
    cursor = {
        -- Number of seconds of mouse inactivity after which Hyprland hides the
        -- mouse cursor. The default of ~5s is a little long. So, we reduce this
        -- default.
        inactive_timeout = 1,

        -- Force Hyprland to render the mouse cursor with unaccelerated software
        -- (i.e., CPU-based) rather than accelerated hardware (i.e., GPU-based)
        -- routines. Although Hyprland understandably defaults to the latter,
        -- doing so currently fails to display a mouse cursor under full-screen
        -- WINE-emulated Windows applications or games. See also this issue:
        --    https://github.com/hyprwm/Hyprland/issues/6106
        -- no_hardware_cursors = true
    },
})

-- ....................{ VIDEO                             }....................
-- Miscellaneous configuration.

hl.config({
    misc = {
        -- Silently re-enable DPMS (i.e., disable screen blanking) on the first
        -- user input after silently disabling DPMS due to user inactivity
        -- above.
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,

        -- Preserve the fullscreen status of the currently focused window when
        -- refocusing from the current to a different window. For unknown (and
        -- presumably indefensible reasons), Hyprland >= 0.53 now silently drops
        -- fullscreen status by default. Why? Because this option defaults to
        -- "2". See also:
        --     https://wiki.hypr.land/Configuring/Variables
        on_focus_under_fullscreen = 1,
    },
})

-- Experimental configuration.
--
-- Enable experimental support for Wayland's color management protocol. Note
-- that:
-- * Valve's gamescope now requires this, making this effectively mandatory.
-- * This support is currently Potemkin. Hyprland currently lacks color
--   management support. Enabling this configuration setting only masquerades to
--   downstream clients (like gamescope) that Hyprland supports this protocol
--   *WITHOUT* actually doing so.

hl.config({
    debug = {
        full_cm_proto = true,
    },
})

-- ....................{ VIDEO ~ monitor                   }....................
-- This section should *ONLY* contain monitor-centric configuration commands of
-- the format:
--     monitor=name,resolution[@framerate],position,scale
--
-- Special human-readable keywords include:
-- * The empty string as the name, globally applying this monitor configuration
--   to *ALL* available monitors.
-- * "preferred" as the resolution, selecting the display’s preferred size.
-- * "auto" as the position, deferring the positioning decision to Hyprland.
-- * "auto" as the scale, deferring the scaling decision to Hyprland.
--
-- Examples include:
--     # Default *ALL* monitors to their default configurations.
--     monitor=,preferred,auto,auto
--
--     # Configure the monitor named "DP-1" as a a 1920x1080 display at 144Hz,
--     # positioned 0x0 from the top left corner, scaled to 1 (i.e., unscaled).
--     monitor=DP-1,1920x1080@144,0x0,1
--
-- Common monitor-centric Hyprland commands include:
-- * List all available monitors:
--       hyprctl monitors all
--

-- --------------------( SEE ALSO                          )--------------------
-- See also:
-- * Official upstream documentation on this file:
--   https://wiki.hyprland.org/Configuring/Monitors

-- Scale *ALL* monitors up by 150% (i.e., 1.5 times) for readability.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1.6667,
})

-- ....................{ WINDOW ~ idle                     }....................
-- Prevent "hypridle" from idling *ANY* fullscreened window. Since most games
-- run as fullscreened windows, this has the beneficial side effect of
-- preventing games from being improperly idled. See also this Reddit thread:
--     https://old.reddit.com/r/hyprland/comments/1q0h1vh/problems_with_windowrules_config

hl.window_rule({
    name  = "Idle Inhibit Fullscreen",
    match = {
        class = ".*",
    },
    idle_inhibit = "fullscreen",
})

-- ....................{ WINDOW ~ lock                     }....................
-- Prevent "hypridle" from locking the screen – *EVER*. Note that doing so
-- appears to be currently infeasible from within this Hyprland-centric
-- configuration file. Instead, the solution is trivial (albeit dumb):
-- * Uninstall "hyprlock" if currently installed:
--       yay -Rns hyprlock
-- * Define an executable "~/.local/bin/hyprlock" script reducing to a noop:
--       #!/usr/bin/env sh

-- ....................{ SCRATCH                           }....................
--FIXME: Donate this back to "hyprdots", please. Pretty much *EVERBODY* wants
--this, honestly. Requisite installation commands include:
--    yay -S swayidle sway-audio-idle-inhibit-git
--FIXME: Great -- except I currently lack sufficient time to configure this
--properly. The issue is gaming. "swayidle" works great *UNLESS* I'm currently
--gaming. At that point, "swayidle" insists on idling regardless of what I do.
--"gamemoderun" doesn't work. "wljoywake" doesn't work. It's incredibly
--frustrating. For now, avoid. It is sad.
-- Start the "swayidle" daemon on hyprland startup, configured to silently
-- disable Display Power Management Signaling (DPMS) (i.e., enable screen
-- blanking) after 300 seconds (i.e., 5 minutes) of user inactivity.
--exec-once = swayidle timeout 300 'hyprctl dispatcher dpms off'
-- Start the "sway-audio-idle-inhibit" daemon on hyprland startup, silently
-- disabling "swayidle" on detecting audio input and/or output. This effectively
-- prevents "swayidle" from blanking the screen while watching media.
--exec-once = sway-audio-idle-inhibit
-- Start the "wljoywake" daemon on hyprland startup, silently disabling
-- "swayidle" on detecting USB-based joypad input and/or output. This effectively
-- prevents "swayidle" from blanking the screen while gaming.
--exec-once = wljoywake &

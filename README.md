# Void Hyprland dotfiles

This is a Void Linux/runit rewrite of [binnewbs/arch-hyprland](https://github.com/binnewbs/arch-hyprland). It targets Hyprland 0.55 or newer, where the compositor configuration is Lua, and uses awww (the renamed successor to swww).

The visual design, Matugen palette, wallpapers, Waybar layouts, and upstream attribution are preserved. The session and helper layer has been made self-contained and Void-aware.

## What changed

- Hyprland's old hyprland.conf and sourced Hyprlang fragments were replaced by hyprland.lua and Lua modules.
- Keybinds use hl.bind and hl.dsp; external Waybar commands use the new hyprctl Lua dispatch syntax.
- Window rules, layer rules, tags, monitors, gestures, curves, and animations use the 0.55 Lua APIs.
- Matugen now emits both a Lua color module for Hyprland and a Hyprlang color file for Hyprlock.
- swww/swww-daemon were replaced by awww/awww-daemon.
- systemctl calls were removed. System services are enabled with runit symlinks.
- Suspend and hibernate use elogind's loginctl on Void, with zzz/ZZZ fallbacks. loginctl here comes from elogind, not systemd.
- Audio controls use PipeWire's wpctl.
- XBPS replaced the Arch/pacman updater and Fastfetch labels.
- Broken shebangs, missing scripts, non-executable helpers, undefined colors, and stale Waybar actions were repaired.

Hypridle and Hyprlock still use their own .conf syntax; Hyprland's Lua migration does not change those applications.

## Install on Void

Hyprland is not in Void's official repositories. The current [Hyprland installation guide](https://wiki.hypr.land/Getting-Started/Installation/#void-linux) documents a third-party XBPS repository. Review that repository before trusting it, then configure it as shown upstream:

    sudo cp /usr/share/xbps.d/00-repository-main.conf /etc/xbps.d/
    sudo sed -i "1i repository=https://mirror.black-hole.dev/$(xbps-uhelper arch)" /etc/xbps.d/00-repository-main.conf
    sudo xbps-install -S

Install, enable the runit services, and deploy the dots:

    chmod +x setup-void.sh
    ./setup-void.sh --all

Do not run the whole script with `sudo`. It deliberately exits when run as
root because `$HOME` would otherwise be `/root`, causing the dotfiles and their
backups to be installed there. The script requests `doas` or `sudo` itself only
for XBPS and runit operations.

The deploy step backs up every matching config directory under:

    ~/.local/state/void-hyprland/backups/<timestamp>/

Each deploy replaces `~/Pictures/wallpapers` with a fresh copy of the bundled
wallpapers. The previous directory is kept under the same timestamped backup.
The deploy also creates the active Waybar symlinks, fixes script permissions,
and installs the recommended per-user PipeWire drop-ins.

If you prefer to manage packages/services yourself:

    ./setup-void.sh --deploy

## Runit and session setup

The setup script enables these system services by linking their packaged service directories into /var/service:

- dbus
- NetworkManager
- bluetoothd

This follows the [Void runit service model](https://docs.voidlinux.org/config/services/index.html).
The `elogind` package remains installed for `XDG_RUNTIME_DIR`, seat/session
handling, and unprivileged power actions, but its runit service is not enabled
automatically. Void normally activates elogind through the system D-Bus. Do
not enable a second copy if elogind is already running; the symptom is:

    elogind is already running as PID ...

If D-Bus activation causes problems on a particular machine, enable the
packaged elogind service only after confirming there is not already another
elogind process.

When starting from a TTY, use the current Hyprland launcher inside a user
D-Bus session:

    exec dbus-run-session start-hyprland

`start-hyprland` is preferred over invoking the `Hyprland` binary directly.
`dbus-run-session` creates the user session bus used by Waybar, notifications,
portals, and other desktop applications. The
`dbus-update-activation-environment` command in `autostart.lua` updates that
existing bus with the Wayland/Hyprland variables; it cannot create the bus.
See the [Void session management guide](https://docs.voidlinux.org/config/session-management.html).

## Required fonts

The Waybar, Rofi, Foot, Kitty, SwayNC, Wlogout, and Hyprlock configurations use
JetBrains Mono Nerd Font names and Nerd Font icon glyphs. The installer tries
to install Void's `nerd-fonts` package plus `noto-fonts-emoji`.

Verify the fonts after installation:

    fc-match "JetBrainsMono Nerd Font"
    fc-match "JetBrainsMono Nerd Font Propo"

If icons are boxes or missing, install/reinstall the font package and rebuild
the font cache:

    sudo xbps-install -S nerd-fonts noto-fonts-emoji
    fc-cache -fv

Void also permits per-user fonts under `~/.local/share/fonts`. If using a
manually downloaded JetBrainsMono Nerd Font archive, extract its `.ttf` files
there and run `fc-cache -fv`.

## SDDM on Void

SDDM's greeter is Xorg-based by default even though the selected Hyprland
session is Wayland. Install SDDM, its X server requirements, and the Qt6
modules required by the Astronaut theme:

    sudo xbps-install -S \
        sddm xorg-minimal xorg-fonts mesa-dri \
        qt6-svg qt6-virtualkeyboard qt6-multimedia

The missing `xorg-minimal`, `xorg-fonts`, or `mesa-dri` packages can leave the
SDDM service running without displaying a greeter.

Ensure the system D-Bus and SDDM services are enabled:

    [ -e /var/service/dbus ] || sudo ln -s /etc/sv/dbus /var/service/dbus
    [ -e /var/service/sddm ] || sudo ln -s /etc/sv/sddm /var/service/sddm
    sudo sv up dbus sddm
    sudo sv status dbus sddm

Do not test SDDM by running `sudo sddm` directly. Use its runit service so it
is supervised and receives the packaged environment. SDDM may use a graphical
VT beyond the six TTYs that have text login prompts; that is normal.

### Hyprland session entry

On Void/runit, SDDM may authenticate the login without creating the user's
D-Bus session bus. If `DBUS_SESSION_BUS_ADDRESS` is empty after logging in,
Waybar and `notify-send` can fail with:

    Cannot autolaunch D-Bus without X11 $DISPLAY

Create `/usr/share/wayland-sessions/hyprland-void.desktop`:

    [Desktop Entry]
    Name=Hyprland (Void)
    Comment=Hyprland Wayland session with D-Bus
    Exec=/usr/bin/dbus-run-session /usr/bin/start-hyprland
    Type=Application
    DesktopNames=Hyprland
    Keywords=tiling;wayland;compositor;

Select **Hyprland (Void)** in SDDM. Do not wrap the command in a second
`dbus-run-session` anywhere else. After login, verify:

    printf '%s\n' "$DBUS_SESSION_BUS_ADDRESS"
    pgrep -af waybar

### Astronaut theme

The [SDDM Astronaut theme](https://github.com/Keyitdev/sddm-astronaut-theme)
installer supports `xbps-install` and runit:

    bash -c "$(curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh)"

Run that command as the normal user; let the script request `sudo` itself. It
installs the theme under
`/usr/share/sddm/themes/sddm-astronaut-theme`, copies its fonts, selects the
theme in `/etc/sddm.conf`, and can enable the SDDM runit service.

The visual preset is independent from the Hyprland launch command. Change the
preset in:

    /usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop

For example:

    ConfigFile=Themes/hyprland_kath.conf

Preview it without logging out:

    sddm-greeter-qt6 --test-mode \
        --theme /usr/share/sddm/themes/sddm-astronaut-theme/

### French keyboard in SDDM

SDDM's Xorg keyboard layout is separate from Hyprland's input configuration.
Create `/etc/X11/xorg.conf.d/00-keyboard.conf`:

    Section "InputClass"
        Identifier "French keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "fr"
    EndSection

Then restart the greeter:

    sudo sv restart sddm

Set Hyprland's own layout separately in
`.config/hypr/configs/input.lua` with `kb_layout = "fr"`.

### SDDM troubleshooting

Check the supervised service and its logs:

    sudo sv status sddm
    sudo tail -n 100 /var/log/sddm/current
    sudo tail -n 100 /var/log/Xorg.0.log

If `sv status` says `want down`, clear the packaged down marker and request
the service again:

    sudo rm -f /etc/sv/sddm/down
    sudo sv up sddm

## Waybar configuration

The deploy step creates these active links:

    ~/.config/waybar/config -> ~/.config/waybar/configs/[TOP] 0-Ja-0 Been modified
    ~/.config/waybar/style.css -> ~/.config/waybar/style/islands.css

Waybar falls back to `/etc/xdg/waybar` when its user configuration is missing.
The supplied startup and restart commands therefore pass both paths explicitly,
so a broken link produces an error instead of displaying the system-default bar.

After pulling an updated repository, repair the links by deploying again:

    ./setup-void.sh --deploy

Or recreate only the links manually:

    rm -f ~/.config/waybar/config ~/.config/waybar/style.css
    (
        cd ~/.config/waybar
        ln -s "configs/[TOP] 0-Ja-0 Been modified" config
        ln -s "style/islands.css" style.css
    )

Restart Waybar with `~/.config/hypr/scripts/wbrestart.sh`. Its diagnostic output
is stored in `~/.local/state/void-hyprland/waybar.log`.

The installer deliberately creates relative links and verifies both the link
text and resolved target. It also prints each successful link, making a failed
`--deploy` visible instead of letting Waybar silently use `/etc/xdg/waybar`.

## Foot terminal

Foot is now the default terminal and is installed by `--install-packages`.
Its configuration is under `~/.config/foot`. The initial palette mirrors the
Kitty configuration, using the same `JetBrainsMono NF Bold` family at Foot size
11 instead of Kitty size 12. Matugen writes wallpaper-derived colors to
`~/.config/foot/colors.ini` under Foot's current `[colors-dark]` section. Foot
reads that palette when a new window starts, so existing Foot windows keep
their currently loaded colors.

Kitty remains installed and its configuration is preserved as an alternative.
Change the `terminal` value in `keybinds.lua` and the `TERMINAL` environment
variable in `environment.lua` if you want to switch back globally.

## First-run adjustments

1. Edit .config/hypr/configs/monitors.lua. The preserved laptop default is eDP-1 at 1920x1080@60.
2. Put wallpapers in ~/Pictures/wallpapers or set WALLPAPER_DIR before running wppicker.sh.
3. Press Super+W to select a wallpaper. The picker passes
   `--source-color-index 0` so Matugen chooses the dominant color without
   opening a terminal-only prompt. Matugen then updates awww, Hyprland,
   Hyprlock, Waybar, Foot, Kitty, Rofi, GTK, and Cava colors.
4. If PipeWire has no devices, follow the [Void PipeWire setup](https://docs.voidlinux.org/config/media/pipewire.html) and re-login.
5. Run `hyprctl reload` to force a reload. Lua syntax and runtime failures are reported by Hyprland; `hyprctl repl` is available for interactive inspection.

## Main keybinds

- Super+T: Foot terminal
- Super+Shift+T: floating Foot terminal
- Super+D: application launcher
- Super+E: file manager
- Super+Tab / Super+Shift+Tab: next / previous open workspace
- Super+S: toggle the `scratchpad` special workspace
- Super+Ctrl+S: move the active window to `scratchpad`
- Super+W: wallpaper picker
- Super+L: lock
- Super+Q: close window
- Super+Shift+Q: force-kill window
- Super+Shift+S: region screenshot
- Super+Space: toggle tiling/floating; it is not fullscreen
- Super+Shift+F: toggle actual fullscreen
- Super+1..0: workspaces 1..10
- Super+Shift+1..0: move a window to a workspace

## Compatibility references

- [Hyprland 0.55 Lua config start page](https://wiki.hypr.land/Configuring/Start/)
- [Hyprland Lua dispatchers](https://wiki.hypr.land/Configuring/Basics/Dispatchers/)
- [awww project](https://codeberg.org/LGFae/awww)
- [awww manual](https://man.archlinux.org/man/awww.1.en)
- [Void runit services](https://docs.voidlinux.org/config/services/index.html)
- [Void zzz/ZZZ manual](https://man.voidlinux.org/zzz.8)

This rewrite was prepared against Hyprland source revision d7fc7240f4efd0abac1c1f23f09b78b30b4e0782 and the Void package collection available in July 2026.

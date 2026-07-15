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

The deploy step backs up every matching config directory under:

    ~/.local/state/void-hyprland/backups/<timestamp>/

It also copies the bundled wallpapers to ~/Pictures/wallpapers, creates the active Waybar symlinks, fixes script permissions, and installs the recommended per-user PipeWire drop-ins.

If you prefer to manage packages/services yourself:

    ./setup-void.sh --deploy

## Runit and session setup

The setup script enables these system services by linking their packaged service directories into /var/service:

- dbus
- NetworkManager
- bluetoothd
- elogind

This follows the [Void runit service model](https://docs.voidlinux.org/config/services/index.html). elogind supplies XDG_RUNTIME_DIR, seat/session handling, and unprivileged power actions. You can substitute turnstile plus seatd, but then adapt power.sh and ensure XDG_RUNTIME_DIR is created correctly.

When starting from a TTY, use a D-Bus session:

    dbus-run-session Hyprland

A display manager or turnstile-managed session may already provide the session bus. See the [Void session management guide](https://docs.voidlinux.org/config/session-management.html).

## First-run adjustments

1. Edit .config/hypr/configs/monitors.lua. The preserved laptop default is eDP-1 at 1920x1080@60.
2. Put wallpapers in ~/Pictures/wallpapers or set WALLPAPER_DIR before running wppicker.sh.
3. Press Super+W to select a wallpaper. Matugen updates awww, Hyprland, Hyprlock, Waybar, Kitty, Rofi, GTK, and Cava colors.
4. If PipeWire has no devices, follow the [Void PipeWire setup](https://docs.voidlinux.org/config/media/pipewire.html) and re-login.
5. Run `hyprctl reload` to force a reload. Lua syntax and runtime failures are reported by Hyprland; `hyprctl repl` is available for interactive inspection.

## Main keybinds

- Super+Return: terminal
- Super+D: application launcher
- Super+E: file manager
- Super+W: wallpaper picker
- Super+L: lock
- Super+Q: close window
- Super+Shift+Q: force-kill window
- Super+Shift+S: region screenshot
- Super+Space: toggle floating
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

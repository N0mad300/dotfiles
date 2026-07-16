local commands = {
    -- Void session services. PipeWire launches WirePlumber and pipewire-pulse
    -- when the example drop-ins installed by setup-void.sh are present.
    "pgrep -x pipewire >/dev/null || exec pipewire",

    "pgrep -x nm-applet >/dev/null || exec nm-applet",
    "pgrep -x blueman-applet >/dev/null || exec blueman-applet",
    "pgrep -x swaync >/dev/null || exec swaync",
    "pgrep -x waybar >/dev/null || exec waybar -c \"$HOME/.config/waybar/config\" -s \"$HOME/.config/waybar/style.css\"",
    "pgrep -x hyprpolkitagent >/dev/null || exec hyprpolkitagent",
    "pgrep -x hypridle >/dev/null || exec hypridle",
    "pgrep -x awww-daemon >/dev/null || exec awww-daemon",

    -- Void has no systemd user environment to import. Update the D-Bus
    -- activation environment directly instead.
    "dbus-update-activation-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE",
    "~/.config/hypr/scripts/wallpaper-restore.sh",
}

hl.on("hyprland.start", function()
    for _, command in ipairs(commands) do
        hl.exec_cmd(command)
    end
end)

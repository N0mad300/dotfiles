local function windowRule(name, match, effects)
    effects.name = name
    effects.match = match
    hl.window_rule(effects)
end

local function layerRule(name, namespace, effects)
    effects.name = name
    effects.match = { namespace = namespace }
    hl.layer_rule(effects)
end

windowRule("multimedia-video", { tag = "multimedia_video" }, {
    no_blur = true,
    opacity = "1.0",
    float = true,
    size = "900 506",
})

windowRule("settings", { tag = "settings" }, { opacity = "0.8", float = true })
windowRule("viewers", { tag = "viewer" }, { float = true })
windowRule("nautilus-opacity", { class = "^org\\.gnome\\.Nautilus$" }, { opacity = "0.8" })
windowRule("editors-opacity", { class = "^(gedit|org\\.gnome\\.TextEditor|mousepad)$" }, { opacity = "0.9" })
windowRule("kitty-opacity", { class = "^kitty$" }, { opacity = "0.9" })
windowRule("chat-opacity", { class = "^(discord|vesktop|org\\.telegram\\.desktop)$" }, {
    opacity = "0.85 override 0.7 override 1 override",
})
windowRule("spotify-opacity", { class = "^Spotify$" }, {
    opacity = "0.8 override 0.6 override 1 override",
})
windowRule("zen-opacity", { class = "^zen$" }, {
    opacity = "0.9 override 0.7 override 1 override",
})

windowRule("pavucontrol", { class = "^org\\.pulseaudio\\.pavucontrol$" }, {
    opacity = "0.9",
    float = true,
    size = "50% 60%",
})

windowRule("suppress-maximize", { class = ".*" }, { suppress_event = "maximize" })
windowRule("fix-xwayland-drag", {
    class = "^$",
    title = "^$",
    xwayland = true,
    float = true,
    fullscreen = false,
    pin = false,
}, { no_focus = true })

windowRule("file-dialogs", { title = "^(Save As|Save a File|Pick Files)$" }, {
    float = true,
    size = "50% 60%",
    center = true,
})
windowRule("open-files-dialog", { initial_title = "^Open Files$" }, {
    float = true,
    size = "70% 60%",
    center = true,
})

layerRule("waybar", "^waybar$", { blur = true, ignore_alpha = 0.5 })
layerRule("wlogout", "^logout_dialog$", { blur = true })
layerRule("swaync-control", "^swaync-control-center$", {
    blur = true,
    ignore_alpha = 0.5,
    xray = false,
})
layerRule("swaync-notifications", "^swaync-notification-window$", {
    blur = true,
    ignore_alpha = 0.5,
    xray = false,
})

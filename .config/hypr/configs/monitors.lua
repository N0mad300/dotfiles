-- Adjust this for your hardware. Use hyprctl monitors all to list outputs.
hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@60",
    position = "0x0",
    scale = "1",
})

-- Portable fallback for outputs not matched above.
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})

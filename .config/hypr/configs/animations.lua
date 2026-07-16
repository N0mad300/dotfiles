hl.config({
    animations = {
        enabled = true,
    },
})

hl.curve("myBezier",   { type = "bezier", points = { { 0.05, 0.90 }, { 0.10, 1.05 } } })
hl.curve("been",       { type = "bezier", points = { { 0.24, 0.90 }, { 0.25, 0.91 } } })
hl.curve("been2",      { type = "bezier", points = { { 0.00, 0.94 }, { 0.50, 0.99 } } })
hl.curve("menu_decel", { type = "bezier", points = { { 0.10, 1.00 }, { 0.00, 1.00 } } })
hl.curve("linear",     { type = "bezier", points = { { 0.00, 0.00 }, { 1.00, 1.00 } } })
hl.curve("wind",       { type = "bezier", points = { { 0.05, 0.90 }, { 0.10, 1.05 } } })
hl.curve("winIn",      { type = "bezier", points = { { 0.10, 1.10 }, { 0.10, 1.10 } } })
hl.curve("winOut",     { type = "bezier", points = { { 0.30, -0.30 }, { 0.00, 1.00 } } })
hl.curve("slow",       { type = "bezier", points = { { 0.00, 0.85 }, { 0.30, 1.00 } } })
hl.curve("overshot",   { type = "bezier", points = { { 0.70, 0.60 }, { 0.10, 1.10 } } })
hl.curve("bounce",     { type = "bezier", points = { { 1.10, 1.60 }, { 0.10, 0.85 } } })
hl.curve("sligshot",   { type = "bezier", points = { { 1.00, -1.00 }, { 0.15, 1.25 } } })
hl.curve("nice",       { type = "bezier", points = { { 0.00, 2.00 }, { 0.50, -2.00 } } })

hl.animation({ leaf = "windowsIn",   enabled = true, speed = 5, bezier = "slow",     style = "popin" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 7, bezier = "been",     style = "popin 70%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "wind",     style = "slide" })
hl.animation({ leaf = "border",      enabled = true, speed = 1, bezier = "linear" })
hl.animation({ leaf = "fade",        enabled = true, speed = 5, bezier = "overshot" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 5, bezier = "wind" })
hl.animation({ leaf = "windows",     enabled = true, speed = 5, bezier = "bounce",   style = "popin" })

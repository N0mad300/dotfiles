local colors = {
<* for name, value in colors *>
    {{name}} = "#{{value.default.hex_stripped}}ff",
<* endfor *>
}

return colors

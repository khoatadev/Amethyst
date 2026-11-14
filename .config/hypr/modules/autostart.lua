-- See https://wiki.hypr.land/configuring/core/autostart/

hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/xdg-portal-hyprland")
end)

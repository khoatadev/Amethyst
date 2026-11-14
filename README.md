# Luminous

Dotfiles cho desktop Gentoo + Hyprland của Khoa. Cấu hình bằng Lua module hoá, commit message tiếng Việt.

## Thành phần

| Thành phần | Đường dẫn | Ghi chú |
|---|---|---|
| Hyprland | `.config/hypr/` | entrypoint `hyprland.lua`, tách module: env, permissions, monitors, autostart, appearance, animations, layouts, input, keybinds, rules |
| Kitty | `.config/kitty/` | theme neon magenta `#ff2ec4`, cursor block blink, font ComicShannsMono Nerd Font |

## Yêu cầu

Cài sẵn trước khi dùng:

- `hyprland` (kèm `hyprland-lua` / Hyprland bản hỗ trợ config Lua)
- `kitty`
- `nerd-fonts` (ComicShannsMono Nerd Font)
- `networkmanager` (keybind + module wifi dùng NetworkManager)

Gentoo: package tương ứng trong `gui-wm/hyprland`, `x11-terms/kitty`, `media-fonts/nerd-fonts`, `net-misc/networkmanager`.

## Cài đặt

```bash
./install.sh
```

Script copy `.config/hypr` và `.config/kitty` vào `~/.config`. File cũ trên máy (nếu có) được backup thành `*.bak.<timestamp>` trước khi bị đè — không đè mất dữ liệu.

## Restore

```bash
mv ~/.config/hypr/hyprland.lua.bak.<timestamp> ~/.config/hypr/hyprland.lua
```

Làm tương tự với file `.bak` nào cần lấy lại.

## Cấu trúc

```
.config/
├── hypr/
│   ├── hyprland.lua        # entrypoint, require các module
│   └── modules/            # env, keybinds, rules...
└── kitty/
    └── kitty.conf
```

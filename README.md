# Amethyst 💜

> Dotfiles cho Gentoo Linux theo theme **amethyst (thạch anh tím)** — màu tím bản sắc Gentoo.

Repo mirror cấu trúc `$HOME` từ gốc repo: một file trong repo nằm đúng vị trí của nó trên máy — `.config/mango/appearance.toml` trong repo tương ứng `~/.config/mango/appearance.toml` trên hệ thống.

## Quickstart

```bash
git clone git@github.com:khoatadev/Amethyst.git
cd Amethyst
```

⚠️ Repo đang được **xây lại từ đầu** — hiện tại mới có đặc tả theme; cấu hình các component sẽ được bổ sung dần theo tiến độ bên dưới.

## Cấu trúc

| Đường dẫn | Nội dung |
| --- | --- |
| `AMETHYST.md` | Đặc tả theme: palette chính thức, quy tắc tương phản, mapping component |
| `.config/` | Cấu hình ứng dụng, mirror từ `$HOME` (đang xây lại) |
| `.config/kitty/` | Cấu hình Kitty — theme `amethyst` trong `themes/amethyst.conf` |

## Theme: Amethyst

Palette gốc và quy tắc áp màu nằm trong [AMETHYST.md](AMETHYST.md). Tiến độ áp dụng theo component:

| Component | Trạng thái |
| --- | --- |
| mangowc | ⏳ |
| kitty | ✅ |
| waybar | ⏳ |
| rofi | ⏳ |
| GTK / Qt | ⏳ |
| wallpaper | ⏳ |

## Môi trường

- OS: Gentoo Linux (OpenRC)
- Compositor: mangoWC
- Terminal: kitty (font ComicShannsMono Nerd Font)
- Theme: amethyst — xem [AMETHYST.md](AMETHYST.md)

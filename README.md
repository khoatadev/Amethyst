# Amethyst

> Dotfiles cho Gentoo Linux — theme **Graphite**: tối giản, nền than gần đen, một accent duy nhất.

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
| `.config/` | Cấu hình ứng dụng, mirror từ `$HOME` (đang xây lại) |

## Theme: Graphite

Đơn sắc + một accent (xám xanh sương nhạt) — nền tối trung tính, tối dung lượng chi tiết. Tiến độ áp dụng:

| Component | Trạng thái |
| --- | --- |
| mangowc | ✅ |
| kitty | ✅ |
| waybar | ⏳ |
| rofi | ⏳ |
| GTK / Qt | ⏳ |
| wallpaper | ⏳ |

## Môi trường

- OS: Gentoo Linux (OpenRC)
- Compositor: mangoWC
- Terminal: kitty
- Theme: Graphite (tối giản — đơn sắc + một accent)

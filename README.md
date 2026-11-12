# 💎 Amethyst

> Bộ cấu hình dotfiles tối giản, thanh lịch và mượt mà dành cho **Gentoo Linux** (Wayland / OpenRC).

---

## 🖥️ Môi trường & Hệ thống

| Thành phần | Công nghệ / Ứng dụng | Mô tả |
| :--- | :--- | :--- |
| **Hệ điều hành** | [Gentoo Linux](https://www.gentoo.org/) | OpenRC init system |
| **Compositor** | [mangoWC](https://github.com/DreamMaoMao/mango) | Wayland compositor linh hoạt, nhẹ & hiệu năng cao |
| **Terminal** | [kitty](https://sw.kovidgoyal.net/kitty/) | Terminal GPU-accelerated với font ligatures |
| **App Launcher** | [Quickshell](https://quickshell.outfoxxed.me/) | Dynamic Island mép dưới màn hình, hiệu ứng co dãn vệt trượt Kitty Cursor Trail |
| **File Manager** | [yazi](https://github.com/sxyazi/yazi) | Trình quản lý file TUI siêu tốc |
| **Status Bar** | [Quickshell](https://quickshell.outfoxxed.me/) | Thanh trạng thái QML dọc mượt mà với hiệu ứng động (ripple, glow, bounce, ring indicator) |
| **Bảng màu (Palette)**| **Tokyo Night Moon** | Tông màu đêm dịu mắt, huyền bí |
| **Font chữ** | `ComicShannsMono Nerd Font` | Font lập trình cá tính, hỗ trợ đầy đủ Nerd Font icons |

---

## 📌 Trạng thái các thành phần

| Thành phần | Thư mục cấu hình | Trạng thái | Ghi chú |
| :--- | :--- | :---: | :--- |
| **mangoWC** | `.config/mango/` | ✅ Hoàn thành | Quản lý cửa sổ, hiệu ứng chuyển động, gaps, keybinds, autostart & remap Caps Lock sang Escape |
| **kitty** | `.config/kitty/` | ✅ Hoàn thành | Theme Tokyo Night Moon, background opacity 0.90 |
| **rofi** | `.config/rofi/` | 📦 Dự phòng | Cấu hình Rofi dự phòng (đã thay thế chính bằng Quickshell Launcher) |
| **quickshell** | `.config/quickshell/` | ✅ Hoàn thành | Thanh dọc trái 54px (nền gradient, viền mờ dần), Clock capsule, Workspaces với indicator stretch + glow + bounce + ripple, Controls với ring tiến độ khi hover, glow đỏ pulse khi mute/pin yếu, Dynamic Island Launcher mép dưới, Cava underbar (thanh chữ nhật bo tròn, decay attack/release nảy mạnh, peak caps rơi theo trọng lực, mirror reflection + glow + sàn sáng theo năng lượng), Wallpaper Island (gallery thumbnail bay vào staggered, hover glow accent, chấm xanh pulse đánh dấu wallpaper hiện tại, chọn xong thumbnail phóng tràn màn hình đúng nhịp awww transition ngẫu nhiên) |
| **GTK / Qt** | `.config/` | ⏳ Đang làm | Đồng bộ theme ứng dụng đồ họa |
| **Wallpaper** | `~/Pictures/Wallpapers/` (ngoài repo) | ✅ Hoàn thành | Quản lý qua Wallpaper Island `Super+W`; daemon `awww` với transition ngẫu nhiên (grow/wave/wipe/fade) |

---

## ⌨️ Phím tắt cơ bản (Keybindings)

Các phím tắt chính được cấu hình trong compositor mangoWC (`Mod = Super` / `Windows`):

| Phím tắt | Tác vụ |
| :--- | :--- |
| `Super + D` | Mở App Launcher (**Quickshell Launcher**) |
| `Super + W` | Mở **Wallpaper Island** (menu chọn wallpaper + hiệu ứng transition awww) |
| `Super + T` | Mở Terminal (**Kitty**) |
| `Super + E` | Mở File Manager (**Yazi** trong Kitty) |
| `Super + Z` | Mở trình duyệt web (**Zen Browser**) |
| `Super + P` | Chụp màn hình vùng chọn (`grim` + `slurp`) |
| `Super + Shift + P` | Chụp toàn màn hình |
| `Super + R` | Nạp lại cấu hình mangoWC (**Reload**) |
| `Caps Lock` | Hoạt động như phím `Escape` (`caps:escape`), tiện lợi chuyển về Normal mode |

---

## 🚀 Cài đặt & Triển khai

### 1. Yêu cầu tiên quyết
- **Font chữ:** Cài đặt font `ComicShannsMono Nerd Font`.
- **Gói phần mềm:** `mango-bin` / `mangoWC`, `quickshell`, `kitty`, `rofi` (hỗ trợ Wayland), `fcitx5`, `awww`, `brightnessctl`, `pipewire`, `wireplumber`, `power-profiles-daemon`.

### 2. Sao chép cấu hình

```bash
# Clone kho lưu trữ
git clone git@github.com:khoatadev/Amethyst.git ~/Projects/Amethyst
cd ~/Projects/Amethyst

# Đồng bộ vào thư mục cá nhân ~/.config
cp -r .config/* ~/.config/
```

---

## 📝 Giấy phép
Cấu hình thuộc quyền sở hữu cá nhân của [khoatadev](https://github.com/khoatadev). Tự do tham khảo và tùy biến theo nhu cầu!

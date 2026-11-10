# 💎 Amethyst

> Bộ cấu hình dotfiles tối giản, thanh lịch và mượt mà dành cho **Gentoo Linux** (Wayland / OpenRC).

---

## 🖥️ Môi trường & Hệ thống

| Thành phần | Công nghệ / Ứng dụng | Mô tả |
| :--- | :--- | :--- |
| **Hệ điều hành** | [Gentoo Linux](https://www.gentoo.org/) | OpenRC init system |
| **Compositor** | [mangoWC](https://github.com/DreamMaoMao/mango) | Wayland compositor linh hoạt, nhẹ & hiệu năng cao |
| **Terminal** | [kitty](https://sw.kovidgoyal.net/kitty/) | Terminal GPU-accelerated với font ligatures |
| **App Launcher** | [rofi](https://github.com/davatorium/rofi) | Chế độ `drun` tối giản, tìm kiếm mờ (fuzzy search) |
| **File Manager** | [yazi](https://github.com/sxyazi/yazi) | Trình quản lý file TUI siêu tốc |
| **Bảng màu (Palette)**| **Tokyo Night Moon** | Tông màu đêm dịu mắt, huyền bí |
| **Font chữ** | `ComicShannsMono Nerd Font` | Font lập trình cá tính, hỗ trợ đầy đủ Nerd Font icons |

---

## 📌 Trạng thái các thành phần

| Thành phần | Thư mục cấu hình | Trạng thái | Ghi chú |
| :--- | :--- | :---: | :--- |
| **mangoWC** | `.config/mango/` | ✅ Hoàn thành | Quản lý cửa sổ, hiệu ứng chuyển động, gaps & keybinds |
| **kitty** | `.config/kitty/` | ✅ Hoàn thành | Theme Tokyo Night Moon, background opacity 0.90 |
| **rofi** | `.config/rofi/` | ✅ Hoàn thành | Floating card ở trung tâm, chỉ bật `drun`, icon app |
| **waybar** | `.config/waybar/` | ⏳ Đang làm | Thanh trạng thái |
| **GTK / Qt** | `.config/` | ⏳ Đang làm | Đồng bộ theme ứng dụng đồ họa |
| **Wallpaper** | `assets/wallpapers/` | ⏳ Đang làm | Hình nền đồng bộ bảng màu |

---

## ⌨️ Phím tắt cơ bản (Keybindings)

Các phím tắt chính được cấu hình trong compositor mangoWC (`Mod = Super` / `Windows`):

| Phím tắt | Tác vụ |
| :--- | :--- |
| `Super + D` | Mở App Launcher (**Rofi**) |
| `Super + T` | Mở Terminal (**Kitty**) |
| `Super + E` | Mở File Manager (**Yazi** trong Kitty) |
| `Super + Z` | Mở trình duyệt web (**Zen Browser**) |
| `Super + P` | Chụp màn hình vùng chọn (`grim` + `slurp`) |
| `Super + Shift + P` | Chụp toàn màn hình |
| `Super + R` | Nạp lại cấu hình mangoWC (**Reload**) |

---

## 🚀 Cài đặt & Triển khai

### 1. Yêu cầu tiên quyết
- **Font chữ:** Cài đặt font `ComicShannsMono Nerd Font`.
- **Gói phần mềm:** `mango-bin` / `mangoWC`, `kitty`, `rofi` (hỗ trợ Wayland).

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

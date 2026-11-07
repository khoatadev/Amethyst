# THEME — Theme spec cho dotfiles

> **Nguồn chuẩn duy nhất** cho màu sắc và phong cách của bộ dotfiles. Agent **Rice** đọc file này trước khi áp dụng màu vào bất kỳ component nào.

## Ý tưởng

Bộ rice theo hướng **tối giản**: nền gần đen trung tính, text mờ nhẹ, và đúng **một** accent dịu. Không trang trí thừa, không màu rực, không gradient — mọi thứ phục vụ việc đọc và tập trung.

Tên theme: **Graphite** (than chì) — từ khóa nhận diện: `graphite`.

## Palette chính thức

### Màu nền & text

| Tên | Hex | Vai trò |
| --- | --- | --- |
| `bg` | `#101113` | Nền chính — xám than gần đen, trung tính |
| `bg-raised` | `#181A1D` | Nền nổi: panel, popup, tab |
| `bg-active` | `#232629` | Selection, hover, element active |
| `line` | `#2E3134` | Viền, phân cách |
| `text` | `#E8EAED` | Text chính |
| `text-muted` | `#9AA0A6` | Text phụ, comment, icon mờ |
| `accent` | `#93B1C6` | **Duy nhất một accent** — xám xanh sương, nhẹ |

Quy ước: không có màu thứ hai. Nơi nào cần điểm nhấn đều dùng `accent`; cần phân cấp thì tăng/giảm độ sáng của xám chứ không thêm hue mới.

### Palette terminal (16 màu)

Hue giữ vai trò chuẩn (red = lỗi, green = ok) nhưng đều làm nhạt bão hòa để nằm trong tổng thể xám:

```text
bg            #101113     fg            #E8EAED     cursor #93B1C6
black         #232629     bright-black   #3A3E43
red           #C98A8A     bright-red     #DBA2A2
green         #96B58F     bright-green   #B3CBAE
yellow        #C4B689     bright-yellow  #D6CBAA
blue          #8FA3C0     bright-blue    #A7B8CF
magenta       #B394BE     bright-magenta #C5ADD0
cyan          #8FB8B5     bright-cyan    #A9CCC9
white         #C9CCD1     bright-white   #E8EAED
selection-bg  #2E3134
```

## Quy tắc tương phản (bắt buộc)

1. Nền luôn tối và trung tính — không dùng nền có ngầm màu rõ rệt.
2. Text chính `text` trên `bg` phải đạt tương phản ≥ 4.5:1.
3. `accent` chỉ chiếm ~5–10% diện tích: cursor, viền active, dòng trạng thái — không tô mảng lớn.
4. Thứ tự độ sáng khi xếp từ nền ra chữ: `bg` < `bg-raised` < `bg-active` < `line` < `text-muted` < `accent` < `text`.
5. Cần một sắc độ mới: **thêm vào bảng trên trước** (tên + vai trò), rồi mới dùng trong config. Không hardcode hex ngoài spec.

## Mapping component

| Component | Cách áp dụng | Ghi chú |
| --- | --- | --- |
| mangowc | `~/.config/mango/appearance.toml` — các key màu dạng `0xRRGGBBAA` (`root_color`, `border_color`, `focus_color`, ...) | Chuyển đổi: `#101113` → `0x101113ff` (thêm alpha) |
| kitty | file `~/.config/kitty/themes/graphite.conf` từ bảng terminal, `kitty.conf` tham chiếu | — |
| waybar | `@define-color` ở đầu `style.css`, rule dùng `@tên` | waybar dùng GTK CSS |
| rofi | biến màu trong block `* { ... }` của `config.rasi` | rasi hỗ trợ biến |
| GTK / Qt | theme xám trung tính có sẵn hoặc tự chỉnh css | ưu tiên khớp `bg` / `accent` |
| wallpaper | tối giản tuyệt đối: màu phẳng, texture mờ hoặc ảnh đen trắng | không dùng ảnh nhiều màu |

## Trạng thái áp dụng

- [ ] mangowc (`appearance.toml` + bar)
- [ ] kitty
- [ ] waybar
- [ ] rofi
- [ ] GTK / Qt
- [ ] wallpaper
- [ ] Khác (fastfetch, dunst/mako, ...)

## Dành cho agent Rice

- Đây là **nguồn màu duy nhất**: đọc trước, áp dụng sau. Mọi hex xuất hiện trong config phải có trong spec — nếu thiếu, cập nhật spec trước rồi mới dùng.
- Giữ từ khóa `graphite` khi đặt tên theme, file màu và commit liên quan đến theme.
- Sau khi áp dụng một component: reload + verify, tick dòng tương ứng trong **Trạng thái áp dụng**, sync git theo mục *Dotfiles Sync* trong prompt của bạn.
- Đổi tên theme sau này: chỉ cần sửa tiêu đề + từ khóa nhận diện trong file này.

#!/bin/bash
# =====================================================================
# Chụp màn hình (grim + slurp)
# Dùng:
#   screenshot.sh region  - chụp vùng chọn (Esc để hủy)
#   screenshot.sh full    - chụp toàn màn hình
# Ảnh lưu tại: ~/Pictures/Screenshot
# =====================================================================

dir="$HOME/Pictures/Screenshot"
mkdir -p "$dir"
file="$dir/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"

case "$1" in
    # Chụp vùng: quét chọn bằng chuột
    region)
        region="$(slurp)" || exit 0
        grim -g "$region" "$file"
        ;;
    # Chụp toàn bộ màn hình
    full)
        grim "$file"
        ;;
    *)
        echo "Dùng: $0 region|full" >&2
        exit 1
        ;;
esac

#!/data/data/com.termux/files/usr/bin/bash

# Hàm hiển thị menu
show_menu() {
    clear
    echo "===== MENU KIỂM TRA IP BLACKLIST ====="
    echo "1. Kiểm tra IP trong blacklist"
    echo "2. Thoát"
    echo "====================================="
    echo -n "Chọn một tùy chọn (1-2): "
}

# Hàm kiểm tra IP blacklist
check_blacklist() {
    echo -n "Nhập địa chỉ IP cần kiểm tra: "
    read IP

    # Kiểm tra định dạng IP chính xác hơn
    if ! echo "$IP" | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}$" > /dev/null || \
       ! echo "$IP" | awk -F'.' '$1<=255 && $2<=255 && $3<=255 && $4<=255' > /dev/null; then
        echo "IP không hợp lệ! Vui lòng nhập định dạng đúng (ví dụ: 192.168.1.1)."
        sleep 2
        return
    fi

    # Danh sách các blacklist phổ biến
    BLACKLISTS=(
        "zen.spamhaus.org"
        "bl.spamcop.net"
        "cbl.abuseat.org"
        "dnsbl.sorbs.net"
        "b.barracudacentral.org"
    )

    # Đảo ngược IP
    REVERSED_IP=$(echo "$IP" | awk -F'.' '{print $4"."$3"."$2"."$1}')

    # Kiểm tra từng blacklist
    echo "Đang kiểm tra IP $IP..."
    FOUND=0
    for BL in "${BLACKLISTS[@]}"; do
        # Sử dụng dig với timeout để tránh treo
        RESULT=$(dig +short +timeout=5 "$REVERSED_IP.$BL" 2>/dev/null)
        if [ -n "$RESULT" ] && echo "$RESULT" | grep -q "^127\."; then
            echo "IP $IP bị liệt kê trong $BL (Kết quả: $RESULT)"
            FOUND=1
        else
            echo "IP $IP không bị liệt kê trong $BL"
        fi
    done

    if [ $FOUND -eq 0 ]; then
        echo "Không tìm thấy IP $IP trong bất kỳ blacklist nào."
    fi
    echo -n "Nhấn Enter để quay lại menu..."
    read
}

# Kiểm tra xem dig có được cài đặt không
if ! command -v dig >/dev/null 2>&1; then
    echo "Lỗi: 'dig' chưa được cài đặt. Vui lòng chạy: pkg install dnsutils"
    exit 1
fi

# Vòng lặp chính cho menu
while true; do
    show_menu
    read choice

    case $choice in
        1)
            check_blacklist
            ;;
        2)
            echo "Đang thoát..."
            sleep 1
            exit 0
            ;;
        *)
            echo "Tùy chọn không hợp lệ! Vui lòng chọn lại."
            sleep 2
            ;;
    esac
done

#!/data/data/com.termux/files/usr/bin/bash

# Hàm hiển thị menu
show_menu() {
    clear
    echo "===== MENU KIỂM TRA IP BLACKLIST ====="
    echo "1. Kiểm tra một IP"
    echo "2. Kiểm tra nhiều IP (cách nhau bằng khoảng trắng)"
    echo "3. Thoát"
    echo "====================================="
    echo -n "Chọn một tùy chọn (1-3): "
}

# Hàm kiểm tra định dạng IP
validate_ip() {
    local ip=$1
    if echo "$ip" | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}$" > /dev/null && \
       echo "$ip" | awk -F'.' '$1<=255 && $2<=255 && $3<=255 && $4<=255' > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Hàm kiểm tra blacklist cho một IP
check_ip_blacklist() {
    local IP=$1
    BLACKLISTS=(
        "zen.spamhaus.org"
        "bl.spamcop.net"
        "cbl.abuseat.org"
        "dnsbl.sorbs.net"
        "b.barracudacentral.org"
    )
    REVERSED_IP=$(echo "$IP" | awk -F'.' '{print $4"."$3"."$2"."$1}')
    local FOUND=0
    local OUTPUT=""

    for BL in "${BLACKLISTS[@]}"; do
        RESULT=$(dig +short +timeout=5 "$REVERSED_IP.$BL" 2>/dev/null)
        if [ -n "$RESULT" ] && echo "$RESULT" | grep -q "^127\."; then
            OUTPUT="$OUTPUT\nIP $IP bị liệt kê trong $BL (Kết quả: $RESULT)"
            FOUND=1
        else
            OUTPUT="$OUTPUT\nIP $IP không bị liệt kê trong $BL"
        fi
    done
    echo -e "$OUTPUT"
    return $FOUND
}

# Hàm kiểm tra một IP
check_single_ip() {
    echo -n "Nhập địa chỉ IP cần kiểm tra: "
    read IP
    if ! validate_ip "$IP"; then
        echo "IP không hợp lệ! Vui lòng nhập định dạng đúng (ví dụ: 192.168.1.1)."
        sleep 2
        return
    fi
    echo "Đang kiểm tra IP $IP..."
    check_ip_blacklist "$IP"
    echo -n "Nhấn Enter để quay lại menu..."
    read
}

# Hàm kiểm tra nhiều IP và thống kê (tách bằng khoảng trắng)
check_multiple_ips() {
    echo -n "Nhập danh sách IP (cách nhau bằng khoảng trắng, ví dụ: 8.8.8.8 1.2.3.4): "
    read -r IP_LIST

    # Tách chuỗi IP thành mảng
    IFS=' ' read -r -a IPS <<< "$IP_LIST"

    if [ ${#IPS[@]} -eq 0 ]; then
        echo "Không có IP nào được nhập!"
        sleep 2
        return
    fi

    TOTAL_IPS=${#IPS[@]}
    BLACKLISTED_IPS=0
    OUTPUT=""

    echo "Đang kiểm tra $TOTAL_IPS IP..."
    for IP in "${IPS[@]}"; do
        if ! validate_ip "$IP"; then
            OUTPUT="$OUTPUT\nIP $IP: Không hợp lệ, bỏ qua."
            continue
        fi
        RESULT=$(check_ip_blacklist "$IP")
        OUTPUT="$OUTPUT\n$RESULT"
        if check_ip_blacklist "$IP" >/dev/null 2>&1; then
            ((BLACKLISTED_IPS++))
        fi
    done

    # Thống kê
    echo -e "\n===== THỐNG KÊ ====="
    echo "Tổng số IP kiểm tra: $TOTAL_IPS"
    echo "Số IP bị liệt kê trong blacklist: $BLACKLISTED_IPS"
    echo "Số IP không bị liệt kê: $((TOTAL_IPS - BLACKLISTED_IPS))"
    echo -e "\n===== CHI TIẾT ====="
    echo -e "$OUTPUT"
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
            check_single_ip
            ;;
        2)
            check_multiple_ips
            ;;
        3)
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

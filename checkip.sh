#!/data/data/com.termux/files/usr/bin/bash

# Hàm hiển thị menu
show_menu() {
    clear
    echo "===== MENU KIỂM TRA IP BLACKLIST ====="
    echo "1. Kiểm tra một IP"
    echo "2. Kiểm tra nhiều IP (cách nhau bằng khoảng trắng)"
    echo "3. Kiểm tra một dãy IP"
    echo "4. Thoát"
    echo "====================================="
    echo -n "Chọn một tùy chọn (1-4): "
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

# Hàm kiểm tra blacklist cho một IP và trả về kết quả
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
    local BLACKLISTED_IN=""

    for BL in "${BLACKLISTS[@]}"; do
        RESULT=$(dig +short +timeout=5 "$REVERSED_IP.$BL" 2>/dev/null)
        if [ -n "$RESULT" ] && echo "$RESULT" | grep -q "^127\."; then
            OUTPUT="$OUTPUT\n  - Bị liệt kê trong $BL (Kết quả: $RESULT)"
            BLACKLISTED_IN="$BLACKLISTED_IN    - $BL\n"
            FOUND=1
        else
            OUTPUT="$OUTPUT\n  - Không bị liệt kê trong $BL"
        fi
    done
    echo -e "$OUTPUT"
    if [ $FOUND -eq 1 ]; then
        echo -e "$IP:\n$BLACKLISTED_IN"
    fi
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
    echo -e "Kết quả cho IP $IP:"
    check_ip_blacklist "$IP"
    echo -n "Nhấn Enter để quay lại menu..."
    read
}

# Hàm kiểm tra nhiều IP (cách nhau bằng khoảng trắng)
check_multiple_ips() {
    echo -n "Nhập danh sách IP (cách nhau bằng khoảng trắng, ví dụ: 8.8.8.8 1.2.3.4): "
    read -r IP_LIST

    IFS=' ' read -r -a IPS <<< "$IP_LIST"
    if [ ${#IPS[@]} -eq 0 ]; then
        echo "Không có IP nào được nhập!"
        sleep 2
        return
    fi

    TOTAL_IPS=${#IPS[@]}
    BLACKLISTED_IPS=0
    BLACKLISTED_DETAILS=""

    echo "Đang kiểm tra $TOTAL_IPS IP..."
    echo -e "\n===== KẾT QUẢ KIỂM TRA ====="
    for IP in "${IPS[@]}"; do
        if ! validate_ip "$IP"; then
            echo "IP $IP: Không hợp lệ, bỏ qua."
            continue
        fi
        echo -e "Kết quả cho IP $IP:"
        RESULT=$(check_ip_blacklist "$IP")
        echo -e "$RESULT" | grep -v "^$IP:"
        BLACKLISTED_RESULT=$(echo -e "$RESULT" | grep "^$IP:")
        if [ -n "$BLACKLISTED_RESULT" ]; then
            BLACKLISTED_DETAILS="$BLACKLISTED_DETAILS\n$BLACKLISTED_RESULT"
            ((BLACKLISTED_IPS++))
        fi
    done

    echo -e "\n===== THỐNG KÊ CÁC IP BỊ BLACKLIST ====="
    if [ $BLACKLISTED_IPS -eq 0 ]; then
        echo "Không có IP nào bị liệt kê trong blacklist."
    else
        echo "Tổng số IP bị liệt kê: $BLACKLISTED_IPS / $TOTAL_IPS"
        echo -e "Danh sách IP bị blacklist trên các trang web:\n$BLACKLISTED_DETAILS"
    fi
    echo -n "Nhấn Enter để quay lại menu..."
    read
}

# Hàm kiểm tra một dãy IP
check_ip_range() {
    echo -n "Nhập IP bắt đầu (ví dụ: 192.168.1.1): "
    read START_IP
    if ! validate_ip "$START_IP"; then
        echo "IP bắt đầu không hợp lệ!"
        sleep 2
        return
    fi

    echo -n "Nhập IP kết thúc (ví dụ: 192.168.1.10): "
    read END_IP
    if ! validate_ip "$END_IP"; then
        echo "IP kết thúc không hợp lệ!"
        sleep 2
        return
    fi

    # Tách các octet của IP
    IFS='.' read -r s1 s2 s3 s4 <<< "$START_IP"
    IFS='.' read -r e1 e2 e3 e4 <<< "$END_IP"

    # Chuyển thành số để so sánh
    START_NUM=$((s1 * 256**3 + s2 * 256**2 + s3 * 256 + s4))
    END_NUM=$((e1 * 256**3 + e2 * 256**2 + e3 * 256 + e4))

    if [ $START_NUM -gt $END_NUM ]; then
        echo "IP bắt đầu phải nhỏ hơn hoặc bằng IP kết thúc!"
        sleep 2
        return
    fi

    # Tạo danh sách IP trong dãy
    IPS=()
    for ((i = START_NUM; i <= END_NUM; i++)); do
        OCT1=$((i / 256**3))
        OCT2=$(((i / 256**2) % 256))
        OCT3=$(((i / 256) % 256))
        OCT4=$((i % 256))
        IP="$OCT1.$OCT2.$OCT3.$OCT4"
        IPS+=("$IP")
    done

    TOTAL_IPS=${#IPS[@]}
    BLACKLISTED_IPS=0
    BLACKLISTED_DETAILS=""

    echo "Đang kiểm tra $TOTAL_IPS IP trong dãy từ $START_IP đến $END_IP..."
    echo -e "\n===== KẾT QUẢ KIỂM TRA ====="
    # Kiểm tra tất cả IP trước
    for IP in "${IPS[@]}"; do
        echo -e "Kết quả cho IP $IP:"
        RESULT=$(check_ip_blacklist "$IP")
        echo -e "$RESULT" | grep -v "^$IP:"
        BLACKLISTED_RESULT=$(echo -e "$RESULT" | grep "^$IP:")
        if [ -n "$BLACKLISTED_RESULT" ]; then
            BLACKLISTED_DETAILS="$BLACKLISTED_DETAILS\n$BLACKLISTED_RESULT"
            ((BLACKLISTED_IPS++))
        fi
    done

    # Thống kê sau khi kiểm tra xong
    echo -e "\n===== THỐNG KÊ CÁC IP BỊ BLACKLIST TRÊN CÁC TRANG WEB ====="
    if [ $BLACKLISTED_IPS -eq 0 ]; then
        echo "Không có IP nào trong dãy bị liệt kê trong blacklist."
    else
        echo "Tổng số IP bị liệt kê: $BLACKLISTED_IPS / $TOTAL_IPS"
        echo -e "Danh sách IP bị blacklist trên các trang web:\n$BLACKLISTED_DETAILS"
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
            check_single_ip
            ;;
        2)
            check_multiple_ips
            ;;
        3)
            check_ip_range
            ;;
        4)
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

#!/data/data/com.termux/files/usr/bin/bash

# Hàm hiển thị menu
show_menu() {
    clear
    echo "===== MENU KIỂM TRA IP BLACKLIST ====="
    echo "1. Kiểm tra một IP trong blacklist"
    echo "2. Kiểm tra một dãy IP trong blacklist"
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

    for BL in "${BLACKLISTS[@]}"; do
        # Debug: hiển thị truy vấn DNS
        echo "Debug: Truy vấn $REVERSED_IP.$BL"
        RESULT=$(dig +short +timeout=5 "$REVERSED_IP.$BL" 2>/dev/null)
        if [ -n "$RESULT" ] && echo "$RESULT" | grep -q "^127\."; then
            echo "IP $IP bị liệt kê trong $BL (Kết quả: $RESULT)"
            FOUND=1
        else
            echo "IP $IP không bị liệt kê trong $BL"
        fi
    done
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
    local FOUND=$?
    if [ $FOUND -eq 0 ]; then
        echo "Không tìm thấy IP $IP trong bất kỳ blacklist nào."
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
    FOUND_ANY=0

    echo "Đang kiểm tra $TOTAL_IPS IP trong dãy từ $START_IP đến $END_IP..."
    for IP in "${IPS[@]}"; do
        check_ip_blacklist "$IP"
        local FOUND=$?
        if [ $FOUND -eq 1 ]; then
            FOUND_ANY=1
        fi
        echo "-------------------------"
    done

    if [ $FOUND_ANY -eq 0 ]; then
        echo "Không tìm thấy bất kỳ IP nào trong dãy bị liệt kê trong blacklist."
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
            check_ip_range
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

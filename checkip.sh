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

    # Kiểm tra định dạng IP cơ bản
    if ! [[ $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "IP không hợp lệ! Vui lòng nhập lại."
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
    REVERSED_IP=$(echo $IP | awk -F'.' '{print $4"."$3"."$2"."$1}')

    # Kiểm tra từng blacklist
    echo "Đang kiểm tra IP $IP..."
    for BL in "${BLACKLISTS[@]}"; do
        RESULT=$(dig +short $REVERSED_IP.$BL)
        if [ -n "$RESULT" ]; then
            echo "IP $IP bị liệt kê trong $BL: $RESULT"
        else
            echo "IP $IP không bị liệt kê trong $BL"
        fi
    done
    echo -n "Nhấn Enter để quay lại menu..."
    read
}

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

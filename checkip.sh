#!/data/data/com.termux/files/usr/bin/bash

# Danh sách các DNSBL phổ biến
BLACKLISTS=(
    "check.spamhaus.org"
    "bl.spamcop.net"
    "dnsbl.sorbs.net"
    "b.barracudacentral.org"
    "cbl.abuseat.org"
)

# Biến để đếm IP bị blacklist
declare -A blacklisted_ips
total_checked=0
blacklisted_count=0

# Hàm kiểm tra IP hợp lệ
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a octets <<< "$ip"
        for octet in "${octets[@]}"; do
            if [ "$octet" -gt 255 ] || [ "$octet" -lt 0 ]; then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

# Hàm kiểm tra blacklist cho một IP
check_blacklist() {
    local IP=$1
    REVERSED_IP=$(echo "$IP" | awk -F. '{print $4"."$3"."$2"."$1}')
    echo "Đang kiểm tra IP: $IP"
    echo "--------------------------------"
    is_blacklisted=0
    for BL in "${BLACKLISTS[@]}"; do
        RESULT=$(dig +short "$REVERSED_IP.$BL")
        if [ -n "$RESULT" ]; then
            echo -e "\e[31mIP $IP bị liệt kê trong $BL: $RESULT\e[0m"
            is_blacklisted=1
        else
            echo -e "\e[32mIP $IP không bị liệt kê trong $BL\e[0m"
        fi
    done
    echo "--------------------------------"
    ((total_checked++))
    if [ $is_blacklisted -eq 1 ]; then
        blacklisted_ips["$IP"]=1
        ((blacklisted_count++))
    fi
}

# Hàm tạo dãy IP từ start đến end
generate_ip_range() {
    local start_ip=$1
    local end_ip=$2
    IFS='.' read -r -a start_octets <<< "$start_ip"
    IFS='.' read -r -a end_octets <<< "$end_ip"

    start_num=$(( (start_octets[0] << 24) + (start_octets[1] << 16) + (start_octets[2] << 8) + start_octets[3] ))
    end_num=$(( (end_octets[0] << 24) + (end_octets[1] << 16) + (end_octets[2] << 8) + end_octets[3] ))

    if [ $start_num -gt $end_num ]; then
        echo "Lỗi: IP bắt đầu phải nhỏ hơn hoặc bằng IP kết thúc."
        return 1
    fi

    for ((i = start_num; i <= end_num; i++)); do
        echo "$(( (i >> 24) & 255 )).$(( (i >> 16) & 255 )).$(( (i >> 8) & 255 )).$(( i & 255 ))"
    done
}

# Hàm hiển thị thống kê
show_stats() {
    echo "===== THỐNG KÊ ====="
    echo "Tổng số IP đã kiểm tra: $total_checked"
    echo "Số IP bị blacklist: $blacklisted_count"
    if [ $blacklisted_count -gt 0 ]; then
        echo "Danh sách IP bị blacklist:"
        for ip in "${!blacklisted_ips[@]}"; do
            echo "- $ip"
        done
    else
        echo "Không có IP nào bị blacklist."
    fi
    echo "===================="
}

# Hàm hiển thị menu
show_menu() {
    clear
    echo "===== MENU KIỂM TRA IP BLACKLIST ====="
    echo "1. Kiểm tra một địa chỉ IP"
    echo "2. Kiểm tra dãy IP"
    echo "3. Thoát"
    echo "====================================="
}

# Hàm xử lý lựa chọn
main() {
    while true; do
show_menu
        read -p "Chọn một tùy chọn (1-3): " choice
        case $choice in
            1)
                read -p "Nhập địa chỉ IP: " IP
                if validate_ip "$IP"; then
                    total_checked=0
                    blacklisted_count=0
                    unset blacklisted_ips
                    declare -A blacklisted_ips
                    check_blacklist "$IP"
                    show_stats
                else
                    echo "Lỗi: '$IP' không phải là địa chỉ IP hợp lệ."
                fi
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            2)
                read -p "Nhập dãy IP (ví dụ: 192.168.1.1-192.168.1.10): " RANGE
                START_IP=$(echo "$RANGE" | cut -d'-' -f1)
                END_IP=$(echo "$RANGE" | cut -d'-' -f2)
                if validate_ip "$START_IP" && validate_ip "$END_IP"; then
                    total_checked=0
                    blacklisted_count=0
                    unset blacklisted_ips
                    declare -A blacklisted_ips
                    IPS=$(generate_ip_range "$START_IP" "$END_IP")
                    if [ $? -eq 0 ]; then
                        for IP in $IPS; do
                            check_blacklist "$IP"
                        done
                        show_stats
                    fi
                else
                    echo "Lỗi: Dãy IP không hợp lệ. Vui lòng nhập đúng định dạng."
                fi
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            3)
                echo "Thoát chương trình. Tạm biệt!"
                exit 0
                ;;
            *)
                echo "Lựa chọn không hợp lệ, vui lòng thử lại."
                read -p "Nhấn Enter để tiếp tục..."
                ;;
        esac
    done
}

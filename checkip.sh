#!/data/data/com.termux/files/usr/bin/bash

# Hàm hiển thị menu
show_menu() {
    clear
    echo "===== MENU KIỂM TRA IP BLACKLIST ====="
    echo "1. Kiểm tra một IP"
    echo "2. Kiểm tra nhiều IP"
    echo "3. Kiểm tra một dãy IP"
    echo "4. Kiểm tra nhiều dãy IP"
    echo "5. Xóa IP blacklist khỏi barracudacentral.org"
    echo "6. Xóa dãy IP blacklist khỏi barracudacentral.org"
    echo "7. Xóa IP blacklist khỏi spamcop.net"
    echo "8. Xóa dãy IP blacklist khỏi spamcop.net"
    echo "9. Thoát"
    echo "====================================="
    echo -n "Chọn một tùy chọn (1-9): "
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
            OUTPUT="$OUTPUT  - Bị liệt kê trong $BL"
            FOUND=1
        fi
    done
    if [ $FOUND -eq 1 ]; then
        echo -e "$OUTPUT"
        echo -e "$IP:$BLACKLISTED_IN"
    else
        echo "√ Không bị Blacklist"
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
    echo -n "Kết quả cho IP $IP:"
    check_ip_blacklist "$IP" | grep -v "^$IP"
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
        echo -n "Kết quả cho IP $IP: "
        RESULT=$(check_ip_blacklist "$IP")
        echo -e "$RESULT" | grep -v "^$IP"
        BLACKLISTED_RESULT=$(echo -e "$RESULT" | grep "^$IP")
        if [ -n "$BLACKLISTED_RESULT" ]; then
            BLACKLISTED_DETAILS="$BLACKLISTED_DETAILS \n$RESULT" 
            ((BLACKLISTED_IPS++))
        fi
    done

    echo -e "\n===== THỐNG KẾ CÁC IP BỊ BLACKLIST ====="
    if [ $BLACKLISTED_IPS -eq 0 ]; then
        echo "Không có IP nào bị liệt kê trong blacklist."
    else
        echo "Tổng số IP bị liệt kê: $BLACKLISTED_IPS / $TOTAL_IPS"
        echo -e "Danh sách IP bị blacklist:\n$BLACKLISTED_DETAILS"
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

    IFS='.' read -r s1 s2 s3 s4 <<< "$START_IP"
    IFS='.' read -r e1 e2 e3 e4 <<< "$END_IP"

    START_NUM=$((s1 * 256**3 + s2 * 256**2 + s3 * 256 + s4))
    END_NUM=$((e1 * 256**3 + e2 * 256**2 + e3 * 256 + e4))

    if [ $START_NUM -gt $END_NUM ]; then
        echo "IP bắt đầu phải nhỏ hơn hoặc bằng IP kết thúc!"
        sleep 2
        return
    fi

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
    for IP in "${IPS[@]}"; do
        echo -n "Kết quả cho IP $IP: "
        RESULT=$(check_ip_blacklist "$IP")
        echo -e "$RESULT" | grep -v "^$IP"
        BLACKLISTED_RESULT=$(echo -e "$RESULT" | grep "^$IP")
        if [ -n "$BLACKLISTED_RESULT" ]; then
            BLACKLISTED_DETAILS="$BLACKLISTED_DETAILS \n$RESULT" 
            ((BLACKLISTED_IPS++))
        fi
    done

    echo -e "\n===== THỐNG KẾ CÁC IP BỊ BLACKLIST ====="
    if [ $BLACKLISTED_IPS -eq 0 ]; then
        echo "Không có IP nào trong dãy bị liệt kê trong blacklist."
    else
        echo "Tổng số IP bị liệt kê: $BLACKLISTED_IPS / $TOTAL_IPS"
        echo -e "Danh sách IP bị blacklist:$BLACKLISTED_DETAILS"
    fi
    echo -n "Nhấn Enter để quay lại menu..."
    read
}

# Hàm kiểm tra nhiều dãy IP
check_multiple_ip_ranges() {
    echo "Nhập các dãy IP (mỗi dãy gồm IP bắt đầu và IP kết thúc, cách nhau bằng khoảng trắng, ví dụ: 192.168.1.1 192.168.1.5 10.0.0.1 10.0.0.10)"
    echo -n "Nhập danh sách dãy IP: "
    read -r RANGE_LIST

    IFS=' ' read -r -a RANGES <<< "$RANGE_LIST"
    if [ ${#RANGES[@]} -eq 0 ] || [ $(( ${#RANGES[@]} % 2 )) -ne 0 ]; then
        echo "Danh sách dãy IP không hợp lệ! Phải nhập số chẵn IP (mỗi dãy có IP bắt đầu và kết thúc)."
        sleep 2
        return
    fi

    TOTAL_IPS=0
    BLACKLISTED_IPS=0
    BLACKLISTED_DETAILS=""

    echo -e "\n===== KIỂM TRA NHIỀU DÃY IP ====="
    for ((i=0; i<${#RANGES[@]}; i+=2)); do
        START_IP=${RANGES[$i]}
        END_IP=${RANGES[$i+1]}

        if ! validate_ip "$START_IP" || ! validate_ip "$END_IP"; then
            echo "Dãy IP $START_IP - $END_IP không hợp lệ, bỏ qua."
            continue
        fi

        IFS='.' read -r s1 s2 s3 s4 <<< "$START_IP"
        IFS='.' read -r e1 e2 e3 e4 <<< "$END_IP"

        START_NUM=$((s1 * 256**3 + s2 * 256**2 + s3 * 256 + s4))
        END_NUM=$((e1 * 256**3 + e2 * 256**2 + e3 * 256 + e4))

        if [ $START_NUM -gt $END_NUM ]; then
            echo "Dãy IP $START_IP - $END_IP không hợp lệ (IP bắt đầu lớn hơn IP kết thúc), bỏ qua."
            continue
        fi

        IPS=()
        for ((j = START_NUM; j <= END_NUM; j++)); do
            OCT1=$((j / 256**3))
            OCT2=$(((j / 256**2) % 256))
            OCT3=$(((j / 256) % 256))
            OCT4=$((j % 256))
            IP="$OCT1.$OCT2.$OCT3.$OCT4"
            IPS+=("$IP")
        done

        ((TOTAL_IPS+=${#IPS[@]}))

        echo "Đang kiểm tra dãy từ $START_IP đến $END_IP (${#IPS[@]} IP)..."
        echo -e "\n===== KẾT QUẢ KIỂM TRA ====="
        for IP in "${IPS[@]}"; do
            echo -e "Kết quả cho IP $IP: "
            RESULT=$(check_ip_blacklist "$IP")
            echo -e "$RESULT" | grep -v "^$IP"
            BLACKLISTED_RESULT=$(echo -e "$RESULT" | grep "^$IP")
            if [ -n "$BLACKLISTED_RESULT" ]; then
                BLACKLISTED_DETAILS="$BLACKLISTED_DETAILS \n$RESULT" 
                ((BLACKLISTED_IPS++))
            fi
        done
    done

    echo -e "\n===== THỐNG KẾ CÁC IP BỊ BLACKLIST ====="
    if [ $BLACKLISTED_IPS -eq 0 ]; then
        echo "Không có IP nào trong các dãy bị liệt kê trong blacklist."
    else
        echo "Tổng số IP bị liệt kê: $BLACKLISTED_IPS / $TOTAL_IPS"
        echo -e "Danh sách IP bị blacklist:\n$BLACKLISTED_DETAILS"
    fi
    echo -n "Nhấn Enter để quay lại menu..."
    read
}

# Hàm gửi yêu cầu xóa nhiều IP khỏi barracudacentral.org
remove_from_barracuda() {
    echo -n "Nhập danh sách IP cần xóa khỏi blacklist (cách nhau bằng khoảng trắng, ví dụ: 192.168.1.1 8.8.8.8): "
    read -r IP_LIST

    IFS=' ' read -r -a IPS <<< "$IP_LIST"
    if [ ${#IPS[@]} -eq 0 ]; then
        echo "Không có IP nào được nhập!"
        sleep 2
        return
    fi

    TOTAL_IPS=${#IPS[@]}
    echo "Đang xử lý $TOTAL_IPS IP..."

    # Thông tin cố định
    EMAIL="doantt@vntt.com.vn"
    PHONE="0705056081"
    REASON="My ip is spam mail, i fixed this error, i need support remove blacklist. Many thanks."

    echo -e "\n===== KẾT QUẢ XỬ LÝ ====="
    for IP in "${IPS[@]}"; do
        if ! validate_ip "$IP"; then
            echo "IP $IP: Không hợp lệ, bỏ qua."
            continue
        fi

        # Kiểm tra xem IP có bị liệt kê trong barracudacentral.org không
        REVERSED_IP=$(echo "$IP" | awk -F'.' '{print $4"."$3"."$2"."$1}')
        RESULT=$(dig +short +timeout=5 "$REVERSED_IP.b.barracudacentral.org" 2>/dev/null)
        if [ -n "$RESULT" ] && echo "$RESULT" | grep -q "^127\."; then
            echo "IP $IP: Bị liệt kê trong barracudacentral.org."
            echo "Đang gửi yêu cầu xóa..."

            # Gửi yêu cầu xóa với các trường cố định
            RESPONSE=$(curl -s -w "\n%{http_code}" \
                --data-urlencode "ip=$IP" \
                --data-urlencode "email=$EMAIL" \
                --data-urlencode "phone=$PHONE" \
                --data-urlencode "reason=$REASON" \
                --data-urlencode "submit=Submit" \
                "https://barracudacentral.org/rbl/removal-request/$IP")
            
            # Tách nội dung và mã trạng thái
            RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')
            HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

            if [ "$HTTP_CODE" -eq 200 ] && echo "$RESPONSE_BODY" | grep -q "request has been submitted"; then
                echo "IP $IP: Yêu cầu xóa đã được gửi thành công."
            else
                echo "Yêu cầu xóa đã được gửi thành công."
            fi
        else
            echo "IP $IP: Không bị liệt kê trong barracudacentral.org."
        fi
    done

    echo -n "Nhấn Enter để quay lại menu..."
    read
}

# Hàm xóa một dãy IP khỏi barracudacentral.org
remove_ip_range_barracuda() {
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

    IFS='.' read -r s1 s2 s3 s4 <<< "$START_IP"
    IFS='.' read -r e1 e2 e3 e4 <<< "$END_IP"

    START_NUM=$((s1 * 256**3 + s2 * 256**2 + s3 * 256 + s4))
    END_NUM=$((e1 * 256**3 + e2 * 256**2 + e3 * 256 + e4))

    if [ $START_NUM -gt $END_NUM ]; then
        echo "IP bắt đầu phải nhỏ hơn hoặc bằng IP kết thúc!"
        sleep 2
        return
    fi

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
    SUCCESSFUL_REQUESTS=0

    # Thông tin cố định cho yêu cầu xóa
    EMAIL="doantt@vntt.com.vn"
    PHONE="0705056081"
    REASON="My ip is spam mail, i fixed this error, i need support remove blacklist. Many thanks."

    echo "Đang kiểm tra và xử lý $TOTAL_IPS IP trong dãy từ $START_IP đến $END_IP..."
    echo -e "\n===== KẾT QUẢ KIỂM TRA VÀ XÓA ====="
    for IP in "${IPS[@]}"; do
        # Kiểm tra xem IP có bị liệt kê trong barracudacentral.org không
        REVERSED_IP=$(echo "$IP" | awk -F'.' '{print $4"."$3"."$2"."$1}')
        RESULT=$(dig +short +timeout=5 "$REVERSED_IP.b.barracudacentral.org" 2>/dev/null)
        
        if [ -n "$RESULT" ] && echo "$RESULT" | grep -q "^127\."; then
            echo "IP $IP: Bị liệt kê trong barracudacentral.org"
            BLACKLISTED_DETAILS="$BLACKLISTED_DETAILS\n$IP: Bị liệt kê trong barracudacentral.org"
            ((BLACKLISTED_IPS++))

            # Gửi yêu cầu xóa
            echo "Đang gửi yêu cầu xóa IP $IP..."
            RESPONSE=$(curl -s -w "\n%{http_code}" \
                --data-urlencode "ip=$IP" \
                --data-urlencode "email=$EMAIL" \
                --data-urlencode "phone=$PHONE" \
                --data-urlencode "reason=$REASON" \
                --data-urlencode "submit=Submit" \
                "https://barracudacentral.org/rbl/removal-request/$IP")
            
            # Tách nội dung và mã trạng thái
            RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')
            HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

            if [ "$HTTP_CODE" -eq 200 ] && echo "$RESPONSE_BODY" | grep -q "request has been submitted"; then
                echo "IP $IP: Yêu cầu xóa đã được gửi thành công."
                ((SUCCESSFUL_REQUESTS++))
            else
                echo "Yêu cầu xóa đã được gửi thành công."
            fi
        else
            echo "IP $IP: Không bị liệt kê trong barracudacentral.org."
        fi
    done

    echo -e "\n===== THỐNG KẾ ====="
    if [ $BLACKLISTED_IPS -eq 0 ]; then
        echo "Không có IP nào trong dãy bị liệt kê trong barracudacentral.org."
    else
        echo "Tổng số IP bị liệt kê: $BLACKLISTED_IPS / $TOTAL_IPS"
        echo -e "Danh sách IP bị blacklist:\n$BLACKLISTED_DETAILS"
    fi
    echo -n "Nhấn Enter để quay lại menu..."
    read
}

# Hàm gửi yêu cầu xóa nhiều IP khỏi spamcop.net
remove_from_spamcop() {
    echo -n "Nhập danh sách IP cần xóa khỏi blacklist (cách nhau bằng khoảng trắng, ví dụ: 192.168.1.1 8.8.8.8): "
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
    MAX_IPS=65536  # Giới hạn số lượng IP tối đa trong một dãy

    echo "Đang xử lý $TOTAL_IPS IP..."
    echo -e "\n===== KẾT QUẢ XỬ LÝ ====="
    for IP in "${IPS[@]}"; do
        if ! validate_ip "$IP"; then
            echo "IP $IP: Không hợp lệ, bỏ qua."
            continue
        fi

        # Kiểm tra xem IP có bị liệt kê trong bl.spamcop.net không
        REVERSED_IP=$(echo "$IP" | awk -F'.' '{print $4"."$3"."$2"."$1}')
        RESULT=$(dig +short +timeout=5 "$REVERSED_IP.bl.spamcop.net" 2>/dev/null)
        if [ -n "$RESULT" ] && echo "$RESULT" | grep -q "^127\."; then
            echo "IP $IP: Bị liệt kê trong spamcop.net."
            BLACKLISTED_DETAILS="$BLACKLISTED_DETAILS\nIP $IP: Bị liệt kê trong spamcop.net"
            ((BLACKLISTED_IPS++))
            # Cung cấp URL để xóa IP
            DELIST_URL="https://spamcop.net/bl.shtml?ip=$IP"
            echo "Lưu ý: Xác nhận CAPTCHA) trên trang web, truy cập: $DELIST_URL hoàn thành các bước thủ công Để xóa IP khỏi spamcop.net"
        else
            echo "IP $IP: ."
        fi
    done

    echo -e "\n===== THỐNG KẾ ====="
    if [ $BLACKLISTED_IPS -eq 0 ]; then
        echo "Không có IP nào được liệt kê trong spamcop.net."
    else
        echo "Tổng số IP bị liệt kê: $BLACKLISTED_IPS / $TOTAL_IPS"
        echo -e "Danh sách IP bị blacklist:\n$BLACKLISTED_DETAILS"
    fi
    echo -e "\nLưu ý: Quá trình xóa khỏi SpamCop thường yêu cầu truy cập URL và hoàn thành các bước thủ công. Vui lòng kiểm tra lại sau khi thực hiện."
    echo -n "Nhấn Enter để quay lại menu..."
    read
}

# Hàm xóa một dãy IP khỏi spamcop.net
remove_ip_range_spamcop() {
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

    IFS='.' read -r s1 s2 s3 s4 <<< "$START_IP"
    IFS='.' read -r e1 e2 e3 e4 <<< "$END_IP"

    START_NUM=$((s1 * 256**3 + s2 * 256**2 + s3 * 256 + s4))
    END_NUM=$((e1 * 256**3 + e2 * 256**2 + e3 * 256 + e4))

    if [ $START_NUM -gt $END_NUM ]; then
        echo "IP bắt đầu phải nhỏ hơn hoặc bằng IP kết thúc!"
        sleep 2
        return
    fi

    # Kiểm tra giới hạn số lượng IP trong dãy
    if [ $((END_NUM - START_NUM + 1)) -gt $MAX_IPS ]; then
        echo "Dãy IP quá lớn! Giới hạn là $MAX_IPS địa chỉ."
        sleep 2
        return
    fi

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

    echo "Đang kiểm tra và xử lý $TOTAL_IPS IP trong dãy từ $START_IP đến $END_IP..."
    echo -e "\n===== KẾT QUẢ KIỂM TRA VÀ XÓA ====="
    for IP in "${IPS[@]}"; do
        # Kiểm tra xem IP có bị liệt kê trong bl.spamcop.net không
        REVERSED_IP=$(echo "$IP" | awk -F'.' '{print $4"."$3"."$2"."$1}')
        RESULT=$(dig +short +timeout=5 "$REVERSED_IP.bl.spamcop.net" 2>/dev/null)
        
        if [ -n "$RESULT" ] && echo "$RESULT" | grep -q "^127\."; then
            echo "IP $IP: Bị liệt kê trong spamcop.net"
            BLACKLISTED_DETAILS="$BLACKLISTED_DETAILS\n$IP: Bị liệt kê trong spamcop.net"
            ((BLACKLISTED_IPS++))
            # Cung cấp URL để xóa IP
            DELIST_URL="https://spamcop.net/bl.shtml?ip=$IP"
             echo "Lưu ý: Xác nhận CAPTCHA) trên trang web, truy cập: $DELIST_URL hoàn thành các bước thủ công Để xóa IP khỏi spamcop.net"
        else
            echo "IP $IP: ."
        fi
    done

    echo -e "\n===== THỐNG KẾ ====="
    if [ $BLACKLISTED_IPS -eq 0 ]; then
        echo "Không có IP nào trong dãy bị liệt kê trong spamcop.net."
    else
        echo "Tổng số IP bị liệt kê: $BLACKLISTED_IPS / $TOTAL_IPS"
        echo -e "Danh sách IP bị blacklist:\n$BLACKLISTED_DETAILS"
    fi
    echo -e "\nLưu ý: Quá trình xóa khỏi SpamCop thường yêu cầu truy cập URL và hoàn thành các bước thủ công. Vui lòng kiểm tra lại sau khi thực hiện."
    echo -n "Nhấn Enter để quay lại menu..."
    read
}

# Kiểm tra xem dig và curl có được cài đặt không
if ! command -v dig >/dev/null 2>&1; then
    echo "Lỗi: 'dig' chưa được cài đặt. Vui lòng chạy: pkg install dnsutils"
    exit 1
fi
if ! command -v curl >/dev/null 2>&1; then
    echo "Lỗi: 'curl' chưa được cài đặt. Vui lòng chạy: pkg install curl"
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
            check_multiple_ip_ranges
            ;;
        5)
            remove_from_barracuda
            ;;
        6)
            remove_ip_range_barracuda
            ;;
        7)
            remove_from_spamcop
            ;;
        8)
            remove_ip_range_spamcop
            ;;
        9)
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

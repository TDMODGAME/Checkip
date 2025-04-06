#!/data/data/com.termux/files/usr/bin/bash

# File tạm để lưu danh sách IP bị blacklist
blacklist_file="/data/data/com.termux/files/home/blacklisted_ips.txt"
touch "$blacklist_file"

# Hàm hiển thị tiêu đề
show_header() {
    clear
    echo "=================================="
    echo "   Công Cụ Kiểm Tra IP Blacklist  "
    echo "=================================="
}

# Hàm kiểm tra một IP
check_ip_blacklist() {
    local ip=$1
    local reversed_ip=$(echo $ip | awk -F'.' '{print $4"."$3"."$2"."$1}')
    local blacklists=("check.spamhaus.org" "bl.spamcop.net" "b.barracudacentral.org" "dnsbl.sorbs.net" "dnsbl-1.uceprotect.net" "dnsbl-2.uceprotect.net" "dnsbl-3.uceprotect.net")
    local is_blacklisted=0
    
    echo "Đang kiểm tra IP: $ip"
    echo "-------------------"
    for bl in "${blacklists[@]}"; do
        result=$(host -t A "$reversed_ip.$bl" 2>/dev/null)
        if [[ $result =~ "127.0.0" ]]; then
            echo "  [!] $ip bị liệt trong $bl"
            is_blacklisted=1
        else
            echo "  [✓] $ip không bị liệt trong $bl"
        fi
    done
    echo "-------------------"
    if [ $is_blacklisted -eq 1 ]; then
        echo "$ip" >> "$blacklist_file"
    fi
}

# Hàm kiểm tra dãy IP
check_ip_range() {
    local start_ip=$1
    local end_ip=$2
    start=$(echo $start_ip | awk -F'.' '{print ($1*256^3)+($2*256^2)+($3*256)+$4}')
    end=$(echo $end_ip | awk -F'.' '{print ($1*256^3)+($2*256^2)+($3*256)+$4}')
    
    for ((i=start; i<=end; i++)); do
        current_ip=$(printf "%d.%d.%d.%d" $((i>>24&255)) $((i>>16&255)) $((i>>8&255)) $((i&255)))
        check_ip_blacklist "$current_ip"
    done
}

# Hàm thống kê IP bị blacklist
show_blacklist_stats() {
    show_header
    if [ -s "$blacklist_file" ]; then
        echo "Danh sách IP bị blacklist:"
        echo "-------------------"
        sort "$blacklist_file" | uniq | while read -r ip; do
            echo "  - $ip"
        done
        echo "-------------------"
        total=$(sort "$blacklist_file" | uniq | wc -l)
        echo "Tổng số IP bị blacklist: $total"
    else
        echo "Chưa có IP nào bị blacklist!"
    fi
    echo "-------------------"
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm tự động báo cáo xóa IP khỏi blacklist
auto_report_remove() {
    show_header
    if [ ! -s "$blacklist_file" ]; then
        echo "Chưa có IP nào bị blacklist để báo cáo!"
        read -p "Nhấn Enter để tiếp tục..."
        return
    fi

    echo "Tự động báo cáo xóa IP khỏi blacklist..."
    echo "-------------------"
    sort "$blacklist_file" | uniq | while read -r ip; do
        echo "Đang xử lý IP: $ip"
        # Giả lập gửi yêu cầu xóa (thay bằng API hoặc email thực tế nếu có)
        # Ví dụ: Gửi email tới Spamhaus (cần cấu hình mailx hoặc curl với API)
        echo "Yêu cầu xóa $ip đã được gửi (giả lập)." 
        # Thực tế: Dùng curl để gửi yêu cầu tới form web hoặc API nếu dịch vụ hỗ trợ
        # curl -X POST "https://example.com/remove" -d "ip=$ip" (cần API key)
    done
    echo "-------------------"
    echo "Quá trình báo cáo hoàn tất (giả lập)."
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm hiển thị menu
show_menu() {
    show_header
    echo "1. Kiểm tra một IP"
    echo "2. Kiểm tra dãy IP"
    echo "3. Thống kê các IP bị blacklist"
    echo "4. Tự động báo cáo xóa IP khỏi blacklist"
    echo "5. Thoát"
    echo "=================================="
    read -p "Chọn tùy chọn (1-5): " choice
}

# Vòng lặp chính
while true; do
    show_menu
    case $choice in
        1)
            show_header
            read -p "Nhập địa chỉ IP (ví dụ: 192.168.1.1): " ip
            if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                check_ip_blacklist "$ip"
            else
                echo "IP không hợp lệ!"
            fi
            read -p "Nhấn Enter để tiếp tục..."
            ;;
        2)
            show_header
            read -p "Nhập IP bắt đầu (ví dụ: 192.168.1.1): " start_ip
            read -p "Nhập IP kết thúc (ví dụ: 192.168.1.10): " end_ip
            if [[ $start_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ && $end_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                check_ip_range "$start_ip" "$end_ip"
            else
                echo "IP không hợp lệ!"
            fi
            read -p "Nhấn Enter để tiếp tục..."
            ;;
        3)
            show_blacklist_stats
            ;;
        4)
            auto_report_remove
            ;;
        5)
            show_header
            echo "Cảm ơn bạn đã sử dụng công cụ!"
            rm -f "$blacklist_file"
            exit 0
            ;;
        *)
            echo "Tùy chọn không hợp lệ!"
            read -p "Nhấn Enter để tiếp tục..."
            ;;
    esac
done
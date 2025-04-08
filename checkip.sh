#!/data/data/com.termux/files/usr/bin/bash

# Cài đặt màu sắc cho giao diện
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Hàm hiển thị menu
show_menu() {
    clear
    echo -e "${YELLOW}=== TOOL CHECK IP BLACKLIST ===${NC}"
    echo "1. Kiểm tra một IP"
    echo "2. Kiểm tra dãy IP(thống kê)"
    echo "3. Kiểm tra nhiều IP khác nhau (thống kê)"
    echo "4. Kiểm tra nhiều dãy IP (thống kê)"
    echo "5. Thoát"
    echo -e "${YELLOW}============================${NC}"
}

# Hàm kiểm tra một IP
check_single_ip() {
    echo -e "${YELLOW}Nhập IP cần kiểm tra (ví dụ: 8.8.8.8):${NC}"
    read -p "IP: " IP
    if [ -z "$IP" ]; then
        echo -e "${RED}Vui lòng nhập một IP hợp lệ!${NC}"
    else
        echo -e "${GREEN}Đang kiểm tra IP: $IP${NC}"
        check_ip_blacklist "$IP"
    fi
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm kiểm tra IP có trong blacklist không
check_ip_blacklist() {
    local ip=$1
    echo -e "${YELLOW}Đang kiểm tra $ip trong blacklist...${NC}"
    RESPONSE=$(curl -s "http://dnsbl.info/check.php?ip=$ip" "https://spamrats.com/lookup.php?ip=$ip" "https://b.barracudacentral.org" "https://spamcop.net/w3m?action=checkblock&ip=$ip" "https://check.spamhaus.org/results?query=$ip")
    if echo "$RESPONSE" | grep -q "listed"; then
        echo -e "${RED}IP $ip bị liệt kê trong blacklist!${NC}"
        echo "$ip" >> blacklist_ips.txt
    else
        echo -e "${GREEN}IP $ip không có trong blacklist.${NC}"
    fi
}

# Hàm kiểm tra một dãy IP bị blacklist và thống kê
check_ip_range() {
    echo -e "${YELLOW}Nhập dãy IP (ví dụ: 192.168.1.0-192.168.1.255):${NC}"
    read -p "Dãy IP: " range
    IFS='-' read -r start_ip end_ip <<< "$range"
    
    start=$(echo $start_ip | awk -F'.' '{print ($1*256^3)+($2*256^2)+($3*256)+$4}')
    end=$(echo $end_ip | awk -F'.' '{print ($1*256^3)+($2*256^2)+($3*256)+$4}')
    
    echo -e "${GREEN}Đang kiểm tra dãy IP từ $start_ip đến $end_ip...${NC}"
    for ((i=start; i<=end; i++)); do
        current_ip=$(printf "%d.%d.%d.%d" $((i>>24&255)) $((i>>16&255)) $((i>>8&255)) $((i&255)))
        check_ip_blacklist "$current_ip"
        sleep 1
    done
    echo -e "${GREEN}Đã kiểm tra xong dãy IP.${NC}"
    show_stats
}

# Hàm kiểm tra nhiều IP khác nhau và thống kê
check_multiple_ips() {
    echo -e "${YELLOW}Nhập các IP cần kiểm tra (cách nhau bằng dấu cách, ví dụ: 8.8.8.8 1.1.1.1):${NC}"
    read -p "Danh sách IP: " ip_list
    echo -e "${GREEN}Đang kiểm tra các IP...${NC}"
    
    for ip in $ip_list; do
        check_ip_blacklist "$ip"
        sleep 1
    done
    echo -e "${GREEN}Đã kiểm tra xong các IP.${NC}"
    show_stats
}

# Hàm kiểm tra nhiều dãy IP và thống kê
check_multiple_ranges() {
    echo -e "${YELLOW}Nhập các dãy IP (cách nhau bằng dấu cách, ví dụ: 192.168.1.0-192.168.1.10 10.0.0.0-10.0.0.5):${NC}"
    read -p "Danh sách dãy IP: " range_list
    echo -e "${GREEN}Đang kiểm tra các dãy IP...${NC}"
    
    for range in $range_list; do
        IFS='-' read -r start_ip end_ip <<< "$range"
        start=$(echo $start_ip | awk -F'.' '{print ($1*256^3)+($2*256^2)+($3*256)+$4}')
        end=$(echo $end_ip | awk -F'.' '{print ($1*256^3)+($2*256^2)+($3*256)+$4}')
        
        echo -e "${GREEN}Kiểm tra dãy từ $start_ip đến $end_ip...${NC}"
        for ((i=start; i<=end; i++)); do
            current_ip=$(printf "%d.%d.%d.%d" $((i>>24&255)) $((i>>16&255)) $((i>>8&255)) $((i&255)))
            check_ip_blacklist "$current_ip"
            sleep 1
        done
    done
    echo -e "${GREEN}Đã kiểm tra xong các dãy IP.${NC}"
    show_stats
}

# Hàm hiển thị thống kê
show_stats() {
    echo -e "${YELLOW}=== Thống kê IP bị blacklist ===${NC}"
    if [ -f "blacklist_ips.txt" ]; then
        total=$(wc -l < blacklist_ips.txt)
        echo -e "Tổng số IP bị blacklist: ${GREEN}$total${NC}"
        echo -e "${YELLOW}Danh sách IP bị blacklist:${NC}"
        cat blacklist_ips.txt
    else
        echo -e "${RED}Chưa có IP nào được ghi nhận trong blacklist.${NC}"
    fi
    read -p "Nhấn Enter để tiếp tục..."
}

# Vòng lặp chính
while true; do
    show_menu
    read -p "Chọn một tùy chọn (1-5): " choice
    case $choice in
        1) check_single_ip ;;
        2) check_ip_range ;;
        3) check_multiple_ips ;;
        4) check_multiple_ranges ;;
        5) echo -e "${GREEN}Tạm biệt!${NC}"; exit 0 ;;
        *) echo -e "${RED}Lựa chọn không hợp lệ!${NC}"; sleep 1 ;;
    esac
done

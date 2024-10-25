#!/bin/bash

# --------------------------------------------
# Author: banglcb
# Title: Script cài đặt và quản lý MicroK8s
# Description: Script hỗ trợ cài đặt MicroK8s, quản lý node và addon
# --------------------------------------------

if [ "$EUID" -ne 0 ]; then
    echo "Vui lòng chạy script này với quyền root."
    exit 1
fi

declare -A ADDONS=(
    [cert-manager]="Quản lý chứng chỉ gốc đám mây"
    [cis-hardening]="Áp dụng quy trình cứng hóa CIS cho K8s"
    [community]="Kho addons của cộng đồng"
    [dashboard]="Bảng điều khiển Kubernetes"
    [dns]="Cung cấp dịch vụ DNS cho cluster"
    [gpu]="Alias cho addon nvidia"
    [ha-cluster]="Cấu hình khả năng cao trên node hiện tại"
    [helm]="Trình quản lý gói cho Kubernetes"
    [helm3]="Trình quản lý gói cho Kubernetes phiên bản 3"
    [host-access]="Cho phép Pods kết nối đến các dịch vụ của Host một cách trơn tru"
    [hostpath-storage]="Lớp lưu trữ; phân bổ lưu trữ từ thư mục trên host"
    [kube-ovn]="Một mạng lưới nâng cao cho Kubernetes"
    [mayastor]="OpenEBS MayaStor"
    [metallb]="Bộ cân bằng tải cho cluster Kubernetes của bạn"
    [metrics-server]="Máy chủ Metrics K8s để truy cập API vào các chỉ số dịch vụ"
    [minio]="Lưu trữ đối tượng MinIO"
    [nvidia]="Hỗ trợ phần cứng NVIDIA (GPU và mạng)"
    [observability]="Một stack observability nhẹ cho logs, traces và metrics"
    [prometheus]="Trình quản lý Prometheus để giám sát và ghi log"
    [registry]="Đăng ký hình ảnh riêng được công khai trên localhost:32000"
    [rook-ceph]="Lưu trữ Ceph phân tán sử dụng Rook"
    [rbac]="Kiểm soát truy cập dựa trên vai trò"
    [storage]="Alias cho addon hostpath-storage, đã bị loại bỏ"
    [ingress]="Bộ điều khiển Ingress cho truy cập từ bên ngoài"
)

install() {
    echo "$USER - $EUID"
    echo "Cập nhật và nâng cấp hệ thống..."
    sudo apt update -y && apt upgrade -y

    # Kiểm tra và cài đặt nano nếu cần
    command -v nano >/dev/null || {
        read -p "Cài đặt nano? (y/n): " yn
        [[ "$yn" =~ ^[Yy]$ ]] && sudo apt install nano -y
    }

    echo "Cài đặt MicroK8s..."
    sudo snap install microk8s --classic
    sudo microk8s.status --wait-ready

    sudo snap alias microk8s.kubectl kubectl

    if ! id -nG "$USER" | grep -qw "microk8s"; then
        sudo usermod -aG microk8s $USER
        sudo mkdir -p $HOME/.kube
        sudo chown -R $USER:$USER $HOME/.kube
        sudo microk8s.kubectl config view --raw > $HOME/.kube/config
        manage_addons
    fi
}

main_menu() {
    clear
    echo "========================================="
    echo "  Sofware Evolution Vietnam Corporation  "
    echo "-----------------------------------------"
    echo "            MicroK8s Management          "
    echo "========================================="
    if ! command -v microk8s &>/dev/null; then
        install
    else
        microk8s status --wait-ready
        echo "1. Thêm node"
        echo "2. Quản lý addon"
        echo "3. Thoát"
        read -p "Lựa chọn của bạn: " choice
        case $choice in
        1) microk8s add-node ;;
        2) manage_addons ;;
        3) exit 0 ;;
        *) echo "Không hợp lệ!" ;;
        esac
    fi
}

manage_addons() {
    echo "1. Bật addon"
    echo "2. Tắt addon"
    echo "3. Thoát"
    read -p "Lựa chọn của bạn: " action_choice

    case $action_choice in
    1) action="enable" ;;
    2) action="disable" ;;
    3) return ;;
    *)
        echo "Không hợp lệ!"
        continue
        ;;
    esac

    addon_keys=("${!ADDONS[@]}")

    while true; do
        echo "Chọn 1 trong các addon sau để $action:"
        count=1
        for addon in "${addon_keys[@]}"; do
            echo "$count) $addon - ${ADDONS[$addon]}"
            ((count++))
        done

        read -p "Chọn addon cần $action (số): " choice
        if [[ "$choice" -ge 1 && "$choice" -lt "$count" ]]; then
            selected_addon="${addon_keys[$((choice - 1))]}"
            echo "Đang $action $selected_addon (${ADDONS[$selected_addon]})..."
            sudo microk8s "$action" "$selected_addon"
        else
            echo "Không hợp lệ!"
        fi

        read -p "Bạn có muốn $action addon khác không? (y/n): " continue_choice
        if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
            break
        fi
    done
}
main_menu

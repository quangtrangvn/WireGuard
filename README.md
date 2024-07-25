# Script setup WireGuard VPN on ubuntu server 22.04 TLS.
#### Chuẩn bị 1 VPS ubuntu 22.04 TLS.
1. **SSH vào VPS bằng terminal hoặc các phần mèm chuyên dụng: ssh user@you-ip**
2. **Cập nhật hệ thống:**
   - **Lệnh**:
     ```bash
     sudo apt-get update -y
     ```
     ```bash
     sudo apt update && sudo apt upgrade -y && sudo apt full-upgrade -y && sudo apt autoremove -y
     ```
3. **Script cài đặt:**
   - **Lệnh**:
     ```bash
     sudo apt-get install wget -y
     ```
     ```bash
     wget -qO- https://raw.githubusercontent.com/quangtrangvn/WireGuard/main/wireguard-install.sh -O wireguard-install.sh
     ```
      ```bash
     sudo bash wireguard-install.sh
     ```
4. **Để tạo nhiều client một lần thay vì tạo từng client một, bạn có thể tùy chỉnh script WireGuard để tạo nhiều cấu hình client tự động:**
   - Script cài đặt WireGuard và tạo nhiều client
Lưu ý: Đảm bảo rằng bạn đã cài đặt WireGuard trước khi chạy script này.
Tạo file script 
   - **Lệnh**:
     ```bash
     nano create-multiple-clients.sh
     ```
      ```bash
     #!/bin/bash

# Số lượng client cần tạo
NUM_CLIENTS=5  # Thay đổi số này theo nhu cầu của bạn

# Thư mục chứa các file cấu hình WireGuard
WG_DIR="/etc/wireguard"
CLIENT_DIR="$WG_DIR/clients"

# Tạo thư mục chứa file cấu hình client nếu chưa tồn tại
sudo mkdir -p $CLIENT_DIR

# Đọc khóa công khai của server
SERVER_PUBLIC_KEY=$(sudo cat $WG_DIR/server_public.key)
SERVER_IP=$(curl -s ifconfig.me)
SERVER_PORT=51820

# Hàm tạo client
create_client() {
  local CLIENT_NUM=$1
  local CLIENT_NAME="client${CLIENT_NUM}"
  local CLIENT_PRIVATE_KEY=$(wg genkey)
  local CLIENT_PUBLIC_KEY=$(echo $CLIENT_PRIVATE_KEY | wg pubkey)
  local CLIENT_IP="10.0.0.$((CLIENT_NUM+1))/24"

  # Tạo file cấu hình cho client
  sudo bash -c "cat > $CLIENT_DIR/$CLIENT_NAME.conf <<EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_IP:$SERVER_PORT
AllowedIPs = 0.0.0.0/0, ::/0
EOF"

  # Thêm cấu hình client vào server
  sudo bash -c "cat >> $WG_DIR/wg0.conf <<EOF
[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = ${CLIENT_IP%%/*}/32
EOF"

  echo "Client $CLIENT_NAME created."
}

# Tạo các client
for i in $(seq 1 $NUM_CLIENTS)
do
  create_client $i
done

# Khởi động lại dịch vụ WireGuard để áp dụng cấu hình mới
sudo systemctl restart wg-quick@wg0

echo "Đã tạo $NUM_CLIENTS client. Các file cấu hình client được lưu tại $CLIENT_DIR"

     ```   
   - **Cấp quyền thực thi cho script:**:
     ```bash
     chmod +x create-multiple-clients.sh
     ```

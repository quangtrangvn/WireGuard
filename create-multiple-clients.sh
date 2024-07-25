#!/bin/bash

# Số lượng client cần tạo
NUM_CLIENTS=5  # Thay đổi số này theo nhu cầu của bạn

# Thư mục chứa các file cấu hình WireGuard
WG_DIR="/etc/wireguard"
CLIENT_DIR="$WG_DIR/clients"

# Tạo thư mục chứa file cấu hình client nếu chưa tồn tại
sudo mkdir -p $CLIENT_DIR

# Đọc khóa công khai của server từ cấu hình WireGuard
SERVER_PUBLIC_KEY=$(sudo wg show wg0 public-key)
SERVER_IP=$(curl -s ifconfig.me)
SERVER_PORT=51820

# Hàm tạo client
create_client() {
  local CLIENT_NUM=$1
  local CLIENT_NAME="client${CLIENT_NUM}"
  local CLIENT_PRIVATE_KEY=$(wg genkey)
  local CLIENT_PUBLIC_KEY=$(echo $CLIENT_PRIVATE_KEY | wg pubkey)
  local CLIENT_PRESHARED_KEY=$(wg genpsk)
  local CLIENT_IP="10.7.0.$((CLIENT_NUM+1))/24"  # Sử dụng dải IP 10.7.0.x/24

  # Tạo file cấu hình cho client
  sudo bash -c "cat > $CLIENT_DIR/$CLIENT_NAME.conf <<EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
PresharedKey = $CLIENT_PRESHARED_KEY
Endpoint = $SERVER_IP:$SERVER_PORT
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF"

  # Thêm cấu hình client vào server
  sudo bash -c "cat >> $WG_DIR/wg0.conf <<EOF
[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
PresharedKey = $CLIENT_PRESHARED_KEY
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

# Kiểm tra trạng thái dịch vụ WireGuard
sudo systemctl status wg-quick@wg0

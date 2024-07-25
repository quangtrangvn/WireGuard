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

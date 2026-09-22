# 🔐 Enhanced OpenVPN Server Installer v2.0

**Một script setup OpenVPN hoàn thiện với bảo mật tối đa và hỗ trợ đầy đủ cho Ubuntu Server 22.04 LTS**

> Fork & Enhanced từ [quangtrangvn/openVPN](https://github.com/quangtrangvn/openVPN)

---

## 📋 Yêu cầu hệ thống

### Hardware
- **VPS / Cloud Server**: Digital Ocean, AWS, Linode, Vultr, Hetzner, v.v...
- **RAM**: Tối thiểu 512MB (khuyến nghị 1GB+)
- **Storage**: Tối thiểu 1GB free space
- **Network**: Kết nối Internet ổn định

### Operating System
✅ **Ubuntu**: 16.04 LTS, 18.04 LTS, 20.04 LTS, **22.04 LTS** (recommended)  
✅ **Debian**: 9+, 10, 11  
✅ **CentOS**: 7, 8  
✅ **Fedora**: Latest  
✅ **Amazon Linux**: 2  
✅ **Oracle Linux**: 8  
✅ **Rocky Linux**: 8+  
✅ **AlmaLinux**: 8+  
✅ **Arch Linux**: Latest  

---

## 🚀 Cài đặt nhanh (Quick Start)

### 1️⃣ SSH vào VPS của bạn
```bash
ssh root@your-vps-ip
# hoặc
ssh user@your-vps-ip
```

### 2️⃣ Cập nhật hệ thống
```bash
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
```

### 3️⃣ Tải script
```bash
curl -O https://raw.githubusercontent.com/quangtrangvn/openVPN/main/openvpn-install.sh
chmod +x openvpn-install.sh
```

### 4️⃣ Chạy script
```bash
sudo ./openvpn-install.sh
```

### 5️⃣ Trả lời các câu hỏi
Script sẽ hỏi bạn các thông số:
- IP address
- Port (mặc định 1194)
- Protocol (UDP hoặc TCP)
- **DNS** (có thêm AdGuard Family)
- Compression options
- Encryption settings

### 6️⃣ Download client config
```bash
# File client config nằm tại:
/root/client.ovpn
# hoặc
/etc/openvpn/client.ovpn
```

---

## 🎯 Tùy chọn DNS (DNS Options)

Script cung cấp **14 tùy chọn DNS**:

| #  | DNS Provider | Loại | Tốc độ | Bảo mật | Ad-block |
|:--:|---|---|:---:|:---:|:---:|
| 1  | System DNS | System | ⭐⭐⭐ | ⭐⭐⭐ | ❌ |
| 2  | Unbound | Self-hosted | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ |
| 3  | Cloudflare | Anycast | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ❌ |
| 4  | Quad9 | Anycast | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ |
| 5  | Quad9 Uncensored | Anycast | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⚠️ |
| 6  | FDN | France | ⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ |
| 7  | DNS.WATCH | Germany | ⭐⭐⭐ | ⭐⭐⭐⭐ | ❌ |
| 8  | OpenDNS | Anycast | ⭐⭐⭐ | ⭐⭐⭐ | ✅ |
| 9  | Google | Anycast | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ❌ |
| 10 | Yandex Basic | Russia | ⭐⭐⭐ | ⭐⭐ | ✅ |
| 11 | AdGuard DNS | Anycast | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ✅✅ |
| **12** | **AdGuard Family** | **Anycast** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | **✅✅✅** |
| 13 | NextDNS | Anycast | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ |
| 14 | Custom | Custom | Custom | Custom | Custom |

### 🌟 Khuyến nghị
- **Cho gia đình/trẻ em**: **Option 12 - AdGuard Family** ✅ (chặn adult content)
- **Cho hiệu suất max**: **Option 3 - Cloudflare** ✅
- **Cho bảo mật cao**: **Option 4 - Quad9** ✅
- **Tự host DNS**: **Option 2 - Unbound** ✅

---

## 🔒 Tính năng bảo mật (Security Features)

### ✅ Mã hóa hiện đại
- **AES-128/192/256-GCM** (AEAD - Authenticated Encryption)
- **AES-128/192/256-CBC** (với HMAC authentication)
- Mặc định: **AES-128-GCM** (nhanh & an toàn)

### ✅ Xác thực chứng chỉ
- **ECDSA** (mặc định - hiệu suất cao)
- **RSA** (tùy chọn - tương thích tốt hơn)
- Đường cong: **prime256v1**, secp384r1, secp521r1

### ✅ Thoả thuận khóa
- **ECDH** (mặc định - nhanh)
- **DH** (tùy chọn - hỗ trợ rộng)
- Key size: 2048, 3072, 4096 bits

### ✅ Bảo vệ Control Channel
- **tls-crypt** (mặc định - mã hóa + xác thực)
- **tls-auth** (xác thực chỉ)

### ✅ HMAC Authentication
- SHA-256 (mặc định)
- SHA-384, SHA-512 (tùy chọn)

### ✅ Tính năng khác
- IPv6 support (NAT)
- Compression (LZ4-v2, LZ4, LZO) - optional
- Client-to-client communication
- Multiple client connections (duplicate-cn)
- Logging & monitoring

---

## 📝 Hướng dẫn từng bước (Detailed Guide)

### Bước 1: Chuẩn bị VPS

```bash
# Nếu bạn là user không phải root, sử dụng sudo
sudo su -

# Cập nhật packages
apt update
apt upgrade -y
apt full-upgrade -y
apt autoremove -y

# Cài curl (nếu chưa có)
apt install curl -y
```

### Bước 2: Tải script

```bash
# Option A: Từ GitHub
curl -O https://raw.githubusercontent.com/quangtrangvn/openVPN/main/openvpn-install.sh

# Option B: Nếu GitHub bị chặn, sử dụng mirror
# wget -O openvpn-install.sh https://mirror.example.com/openvpn-install.sh
```

### Bước 3: Cấp quyền thực thi
```bash
chmod +x openvpn-install.sh
```

### Bước 4: Chạy script
```bash
sudo ./openvpn-install.sh
```

Hoặc nếu đã là root:
```bash
./openvpn-install.sh
```

### Bước 5: Trả lời các câu hỏi

#### 🔹 IP Address
```
IP address [detected-ip]: (nhấn Enter để chấp nhận)
```
Nếu VPS behind NAT:
```
Public IPv4 address or hostname: your-public-ip.com
```

#### 🔹 IPv6 Support
```
Do you want to enable IPv6 support? [y/n]: n (hoặc y)
```

#### 🔹 Port
```
Port choice [1-3]: 
1) Default: 1194
2) Custom
3) Random

-> Chọn 1 (mặc định là tốt nhất)
```

#### 🔹 Protocol
```
Protocol [1-2]:
1) UDP (nhanh hơn - khuyến nghị)
2) TCP

-> Chọn 1
```

#### 🔹 DNS
```
DNS [1-14]:
1) System DNS
2) Unbound
3) Cloudflare (⭐ khuyến nghị)
4) Quad9
...
11) AdGuard DNS
12) AdGuard Family (⭐ cho gia đình)
13) NextDNS
14) Custom

-> Chọn 3 (Cloudflare) hoặc 12 (AdGuard Family)
```

#### 🔹 Multiple Simultaneous Connections
```
Allow multiple clients? [1-2]:
1) Yes (Multiple devices can use same account) - RECOMMENDED
2) No (Only 1 device at a time)

-> Chọn 1 (nếu muốn share account cho nhiều người/device)
-> Chọn 2 (nếu chỉ 1 người/device dùng)
```

**⚠️ QUAN TRỌNG:**
- **Option 1 (Yes)**: Cài `duplicate-cn` vào config → Cho phép **vô hạn device** dùng cùng 1 certificate
- **Option 2 (No)**: Không cài `duplicate-cn` → Chỉ **1 device** có thể dùng certificate này

#### 🔹 Compression
```
Enable compression? [y/n]: n (khuyến nghị disabled)
```

#### 🔹 Encryption
```
Customize encryption settings? [y/n]: n (dùng default tốt)
```

#### 🔹 Xác nhận
```
Press any key to continue...
```

### Bước 6: Script sẽ tự động

- Cài OpenVPN
- Cài easy-rsa
- Tạo CA certificate
- Tạo server certificate & key
- Tạo client certificate & key
- Cấu hình firewall
- Enable IP forwarding
- Khởi động service

Quá trình mất khoảng **2-5 phút**.

### Bước 7: Download client config

Sau khi cài xong, file client config nằm tại:

```bash
# Đường dẫn 1
/root/client.ovpn

# Đường dẫn 2 (theo tên client)
/etc/openvpn/client.ovpn

# Copy ra home nếu cần
cp /root/client.ovpn ~/
```

**Download file này về máy của bạn** (sử dụng SCP, SFTP, hoặc download qua SSH)

```bash
# Trên máy local, sử dụng scp
scp root@your-vps-ip:/root/client.ovpn ~/Downloads/

# Hoặc sử dụng SFTP client (FileZilla, WinSCP...)
```

---

## 💻 Sử dụng OpenVPN Client

### Windows
1. Tải [OpenVPN GUI](https://openvpn.net/community-downloads/)
2. Cài đặt
3. Copy file `client.ovpn` vào thư mục `C:\Program Files\OpenVPN\config`
4. Chuột phải OpenVPN GUI → Connect

### macOS
1. Cài [Tunnelblick](https://tunnelblick.net/)
2. Kéo thả `client.ovpn` vào Tunnelblick
3. Click Connect

### Linux
```bash
# Cài OpenVPN
sudo apt install openvpn

# Kết nối
sudo openvpn --config client.ovpn

# Hoặc sử dụng GUI
sudo apt install network-manager-openvpn network-manager-openvpn-gnome
# Sau đó import qua Network Manager
```

### iOS / Android
1. Cài OpenVPN Connect (app chính thức)
2. Mở file `client.ovpn` (hoặc import via email)
3. App sẽ tự import config
4. Tap "Add" để kết nối

### Router
1. Vào settings router
2. Tìm VPN hoặc OpenVPN
3. Import file config
4. Enable VPN

---

## 📱 Multiple Client Connections (Kết nối đồng thời)

### Hiểu về `duplicate-cn`

**`duplicate-cn`** là option trong OpenVPN để cho phép **nhiều kết nối từ cùng 1 certificate**.

#### ✅ Nếu **CÓ** `duplicate-cn` (Option 1 - Recommended)
```bash
# Server config
duplicate-cn
```

**Kết quả:**
- ✅ **Vô hạn device** có thể kết nối với cùng 1 certificate
- ✅ Có thể **share certificate** cho bạn bè / gia đình
- ✅ Một người có thể dùng trên **laptop, phone, tablet cùng lúc**
- ✅ Multiple devices từ cùng 1 account
- ✅ **Tốt cho:** Family VPN, shared accounts, development teams

**Ví dụ:**
```
Certificate: family.ovpn
Người A: Dùng trên Phone
Người B: Dùng trên Laptop
Người C: Dùng trên Tablet
→ Tất cả kết nối được cùng lúc ✅
```

#### ❌ Nếu **KHÔNG** `duplicate-cn` (Option 2)
```bash
# Server config - không có duplicate-cn
# duplicate-cn option is disabled
```

**Kết quả:**
- ⚠️ Chỉ **1 device** có thể kết nối với certificate này
- ⚠️ Nếu device 2 kết nối, device 1 sẽ bị **disconnect**
- ❌ Không thể share certificate
- ✅ **Tốt cho:** One-time use, security-sensitive environments, corporate

**Ví dụ:**
```
Certificate: company.ovpn
Người A: Kết nối trên Laptop ✅
Người B: Cố gắng kết nối → Người A bị disconnect ❌
```

---

### Thay đổi `duplicate-cn` sau khi cài

#### Thêm `duplicate-cn` (Allow multiple clients)
```bash
# Edit config
sudo nano /etc/openvpn/server.conf

# Thêm dòng này vào cuối file:
duplicate-cn

# Lưu (Ctrl+X, Y, Enter)

# Restart
sudo systemctl restart openvpn-server@server
```

#### Xóa `duplicate-cn` (Disable multiple clients)
```bash
# Edit config
sudo nano /etc/openvpn/server.conf

# Tìm & xóa dòng:
duplicate-cn

# Hoặc comment out:
# duplicate-cn

# Lưu (Ctrl+X, Y, Enter)

# Restart
sudo systemctl restart openvpn-server@server

# Clients hiện tại sẽ bị disconnect
```

---

### Kiểm tra hiện tại có `duplicate-cn` không

```bash
# Kiểm tra
grep "duplicate-cn" /etc/openvpn/server.conf

# Nếu có output → duplicate-cn is ENABLED
# Nếu không output → duplicate-cn is DISABLED
```

---

### Số device có thể kết nối

| Setting | Devices | Ví dụ |
|---------|---------|------|
| **WITH duplicate-cn** | **∞ (vô hạn)** | 10, 100, 1000+ devices cùng account |
| **WITHOUT duplicate-cn** | **1 device** | Chỉ 1 laptop được kết nối |

---

### Recommendation 🎯

| Use Case | Setting | Lý do |
|----------|---------|------|
| **Gia đình** | ✅ `duplicate-cn` | Share account cho toàn bộ gia đình |
| **Cá nhân** | ✅ `duplicate-cn` | Dùng trên laptop + phone cùng lúc |
| **Team/Organization** | ⚠️ No `duplicate-cn` | Control access, 1 user = 1 certificate |
| **High Security** | ⚠️ No `duplicate-cn` | Prevent unauthorized sharing |
| **Development** | ✅ `duplicate-cn` | Flexibility for testing |

---

## 🔧 Lệnh quản lý (Management Commands)

### Kiểm tra trạng thái
```bash
# Xem status
sudo systemctl status openvpn-server@server

# Xem đang chạy không
sudo systemctl is-active openvpn-server@server

# Xem enabled không
sudo systemctl is-enabled openvpn-server@server
```

### Khởi động/Dừng/Khởi động lại
```bash
# Khởi động
sudo systemctl start openvpn-server@server

# Dừng
sudo systemctl stop openvpn-server@server

# Khởi động lại
sudo systemctl restart openvpn-server@server

# Reload config (không tắt server)
sudo systemctl reload openvpn-server@server
```

### Xem logs
```bash
# Xem logs real-time
sudo tail -f /var/log/openvpn/server.log

# Xem logs qua journalctl
sudo journalctl -u openvpn-server@server -f

# Xem logs theo số dòng
sudo journalctl -u openvpn-server@server -n 50
```

### Kiểm tra kết nối
```bash
# Xem file status
cat /etc/openvpn/openvpn-status.log

# Xem clients đang kết nối
ss -tupn | grep 1194

# Hoặc
netstat -tupn | grep 1194
```

---

## ➕ Thêm client mới (Add More Clients)

Sau khi cài xong, để thêm client mới:

```bash
cd /etc/openvpn/easy-rsa

# Tạo certificate mới cho client
./easyrsa build-client-full USERNAME nopass

# Nếu muốn có passphrase:
./easyrsa build-client-full USERNAME

# Tạo inline config
sudo bash -c 'cat > /etc/openvpn/USERNAME.ovpn << "EOF"
client
dev tun
proto udp
remote YOUR_PUBLIC_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun

<ca>
EOF
cat /etc/openvpn/easy-rsa/pki/ca.crt >> /etc/openvpn/USERNAME.ovpn
echo "</ca>" >> /etc/openvpn/USERNAME.ovpn
echo "<cert>" >> /etc/openvpn/USERNAME.ovpn
cat /etc/openvpn/easy-rsa/pki/issued/USERNAME.crt >> /etc/openvpn/USERNAME.ovpn
echo "</cert>" >> /etc/openvpn/USERNAME.ovpn
echo "<key>" >> /etc/openvpn/USERNAME.ovpn
cat /etc/openvpn/easy-rsa/pki/private/USERNAME.key >> /etc/openvpn/USERNAME.ovpn
echo "</key>" >> /etc/openvpn/USERNAME.ovpn'

# Copy file
sudo cp /etc/openvpn/USERNAME.ovpn /root/
sudo chmod 600 /root/USERNAME.ovpn

# Download file này
# scp root@your-ip:/root/USERNAME.ovpn ~/Downloads/
```

---

## 🔄 Sửa đổi DNS sau khi cài (Change DNS Later)

Nếu bạn muốn đổi DNS sau khi cài:

```bash
# Sửa file config
sudo nano /etc/openvpn/server.conf

# Tìm dòng push "dhcp-option DNS"
# Thay thế bằng DNS mới:

# Ví dụ 1: Cloudflare
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 1.0.0.1"

# Ví dụ 2: AdGuard Family
push "dhcp-option DNS 94.140.14.15"
push "dhcp-option DNS 94.140.15.16"

# Ví dụ 3: Quad9
push "dhcp-option DNS 9.9.9.9"
push "dhcp-option DNS 149.112.112.112"

# Lưu (Ctrl+X, Y, Enter)

# Khởi động lại
sudo systemctl restart openvpn-server@server
```

---

## 📊 Kiểm tra kết nối (Test Connection)

### Trên client
```bash
# Xem IP hiện tại (phải là VPN IP)
curl https://api.ipify.org

# Hoặc
dig -x $(dig +short myip.opendns.com @resolver1.opendns.com)

# Xem DNS hiện tại
nslookup google.com
```

### Trên server
```bash
# Xem clients kết nối
sudo tail -f /etc/openvpn/openvpn-status.log

# Hoặc
cat /etc/openvpn/openvpn-status.log | grep -v "HEADER"

# Xem realtime
watch -n 1 'tail -20 /etc/openvpn/openvpn-status.log'
```

---

## 🆘 Troubleshooting

### Vấn đề: Cannot connect to VPN
```bash
# Kiểm tra service đang chạy?
sudo systemctl status openvpn-server@server

# Kiểm tra port đang listen?
sudo ss -tupn | grep 1194

# Xem logs
sudo journalctl -u openvpn-server@server -n 50
```

### Vấn đề: DNS không hoạt động
```bash
# Kiểm tra DNS trong config
grep "dhcp-option DNS" /etc/openvpn/server.conf

# Test DNS
nslookup google.com 94.140.14.15  # AdGuard
nslookup google.com 1.1.1.1       # Cloudflare
```

### Vấn đề: Slow connection
```bash
# Kiểm tra compression có enabled?
grep "compress" /etc/openvpn/server.conf

# Tắt compression (nếu enabled)
# Comment out dòng "compress" hoặc đổi thành "comp-lzo no"
```

### Vấn đề: TUN/TAP device error
```bash
# Kiểm tra TUN available?
test -c /dev/net/tun && echo "TUN is available" || echo "TUN NOT available"

# Nếu không có:
# - Liên hệ hosting provider (cần enable TUN)
# - Hoặc đổi hosting
```

### Vấn đề: Firewall issues
```bash
# Check UFW
sudo ufw status
sudo ufw allow 1194/udp
sudo ufw reload

# Hoặc firewall-cmd
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --add-port=1194/udp
sudo firewall-cmd --reload

# Hoặc iptables
sudo iptables -L -n | grep 1194
```

---

## 📈 Hiệu suất & Tối ưu (Performance Tuning)

### Tăng tốc độ
1. **Dùng UDP thay TCP**
   ```bash
   proto udp  # Already default
   ```

2. **Tắt compression**
   ```bash
   comp-lzo no  # Already default
   ```

3. **Dùng Cloudflare DNS**
   ```bash
   push "dhcp-option DNS 1.1.1.1"
   ```

4. **Tăng buffer size** (Edit /etc/openvpn/server.conf)
   ```bash
   sndbuf 524288
   rcvbuf 524288
   ```

5. **Tăng number of threads** (Nếu dùng Unbound)
   ```bash
   # Edit /etc/unbound/unbound.conf
   num-threads: 4  # Thay bằng số CPU cores
   ```

### Giảm latency
- Đổi DNS sang **Cloudflare** hoặc **Quad9**
- Đổi port từ default nếu ISP throttle

### Kiểm tra performance
```bash
# Speed test từ server
curl -s https://speed.cloudflare.com/__down | head -c 1000000 | wc -c

# Hoặc dùng speedtest
apt install speedtest-cli
speedtest
```

---

## 🔐 Best Practices

### Security
✅ **Luôn sử dụng HTTPS hoặc TLS**  
✅ **Bật firewall & chỉ mở port cần thiết**  
✅ **Cập nhật OS thường xuyên**  
✅ **Sử dụng passphrase cho private keys**  
✅ **Backup certificates & keys**  
✅ **Monitor logs thường xuyên**  
✅ **Disable password auth, dùng SSH key**  

### Performance
✅ **Dùng UDP thay TCP**  
✅ **Tắt compression**  
✅ **Chọn DNS nhanh (Cloudflare)**  
✅ **Giới hạn số concurrent connections nếu cần**  

### Monitoring
```bash
# Tạo cron job để check logs
sudo crontab -e
# Add: */5 * * * * tail -100 /var/log/openvpn/server.log | mail -s "OpenVPN Log" admin@example.com
```

---

## 📞 Hỗ trợ (Support)

### Script gốc
- **GitHub**: https://github.com/quangtrangvn/openVPN
- **Telegram**: @quangtrangvn
- **Email**: ad@networkz.vn

### Issues & Bugs
Nếu gặp vấn đề:
1. Kiểm tra logs: `sudo journalctl -u openvpn-server@server`
2. Cấu hình firewall
3. Kiểm tra TUN device: `test -c /dev/net/tun && echo OK || echo FAIL`
4. Liên hệ support với logs & cấu hình

---

## 📜 License & Attribution

**Original Script**: [quangtrangvn/openVPN](https://github.com/quangtrangvn/openVPN)

**Enhanced Version**: 
- ✅ Added AdGuard Family DNS option
- ✅ Improved error handling
- ✅ Better logging system
- ✅ Dependency checking
- ✅ Config backups
- ✅ Enhanced documentation

---

## 🙏 Cảm ơn!

Cảm ơn bạn đã sử dụng script này. Nếu hữu ích, hãy:
- ⭐ Star trên GitHub
- 📢 Share cho bạn bè
- 💬 Feedback & suggestions
- 🐛 Report bugs

**Happy VPN! 🚀**

---

**Last Updated**: 2024  
**Version**: 2.0 Enhanced  
**Ubuntu Support**: 22.04 LTS ✅

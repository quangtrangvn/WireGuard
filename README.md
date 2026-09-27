# Cài WireGuard trên VPS Linux

Script hỏi đáp dựa trên cách dùng của bản năm 2024. Bản hiện tại đã thử trực tiếp trên **Ubuntu Server 22.04 (`spx`)**; các distro khác có nhánh cài package nhưng chưa được kiểm thử thực tế. Hỗ trợ systemd trên Ubuntu/Debian, RHEL/Rocky/Alma/Fedora, Arch/Manjaro và openSUSE nếu repository của distro cung cấp `wireguard-tools` và `nftables`. Script dừng nếu không có module WireGuard, systemd hoặc package cần thiết. Alpine/OpenRC và mọi phiên bản Linux khác chưa được hỗ trợ.

## 1. Chuẩn bị

- VPS có quyền root/sudo, kernel có WireGuard và mạng Internet.
- Dải `10.7.0.0/24` chưa được sử dụng. Nếu máy đã có `/etc/wireguard/wg0.conf`, script từ chối cài đè.
- Mở cổng UDP được chọn trong Cloud Firewall/Security Group của nhà cung cấp VPS (mặc định `51820`).
- Giữ phiên SSH hiện tại mở trong lúc cài.

Trên **máy tính của bạn**, đăng nhập VPS (thay địa chỉ):

```bash
ssh root@IP_CUA_VPS
```

## 2. Tải và chạy trên VPS

```bash
sudo apt-get update
sudo apt-get install -y curl
curl -fL https://raw.githubusercontent.com/quangtrangvn/WireGuard/main/wireguard-install.sh -o wireguard-install.sh
bash -n wireguard-install.sh
sudo bash wireguard-install.sh
```

Nếu không dùng Debian/Ubuntu, cài `curl` theo package manager của distro trước bước tải. Script hỏi lần lượt IP public/tên miền, cổng UDP, tên client đầu tiên, DNS và xác nhận. Nếu VPS sau NAT, hãy nhập IP public hoặc tên miền trỏ về VPS. Bản này cài VPN IPv4 và không in QR hoặc khóa riêng lên terminal.

Script tạo `wg0`, cấu hình NAT/firewall trong table nftables **riêng**, và bật IPv4 forwarding. Nó không sửa cấu hình hoặc profile OpenVPN. Nếu dịch vụ đang chạy khác dùng dải `10.7.0.0/24`, đừng cài cho đến khi giải quyết xung đột.

## 3. Kiểm tra và tải client

Trên **VPS**:

```bash
sudo bash wireguard-install.sh status
sudo systemctl status wg-quick@wg0 --no-pager
```

Nếu đặt tên client là `client`, file được tạo tại `/root/client-wg.conf`. File chứa private key, quyền `600`. Trên **máy tính cá nhân**, tải file (thay IP):

```bash
scp root@IP_CUA_VPS:/root/client-wg.conf .
```

Hoặc dùng WinSCP/SFTP. Import `.conf` vào ứng dụng WireGuard và thử từ mạng bên ngoài VPS. Chỉ khi thiết bị bắt tay và có mạng qua VPN mới xác nhận đường truyền hoạt động.

## 4. Thêm client

Chạy lại script trên VPS, chọn **1) Thêm client**, nhập tên mới. Mỗi thiết bị nên có file client riêng; script thêm peer vào `wg0` mà không restart OpenVPN hoặc WireGuard. File mới là `/root/TENCLIENT-wg.conf`.

Script phụ `create-multiple-clients.sh` là công cụ cũ: chỉ dùng khi đã đối chiếu cổng, dải IP và peer; với dịch vụ mới hãy ưu tiên menu của `wireguard-install.sh`.

Không gửi file `.conf`, `/etc/wireguard/wg0.conf`, private key hoặc QR chứa cấu hình vào chat/GitHub. Nếu gặp lỗi, gửi **thông báo lỗi đã che secret** và trạng thái `sudo systemctl status wg-quick@wg0 --no-pager`.

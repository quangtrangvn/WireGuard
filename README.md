# Cài WireGuard trên Ubuntu Server 22.04

## 1. Chuẩn bị VPS

SSH vào VPS từ máy tính (thay IP):

```bash
ssh root@IP_CUA_VPS
```

Mở UDP 51820 trong firewall của nhà cung cấp VPS nếu chọn cổng mặc định. Giữ phiên SSH mở trong lúc cài.

## 2. Tải và chạy script

Trên VPS:

```bash
sudo apt-get update
sudo apt-get install -y curl
curl -fL https://raw.githubusercontent.com/quangtrangvn/WireGuard/main/wireguard-install.sh -o wireguard-install.sh
bash -n wireguard-install.sh
sudo bash wireguard-install.sh
```

Trả lời các câu hỏi trên màn hình. Script `wireguard-install.sh` của repo vẫn là script WireGuard gốc, không phải OpenVPN. Sau cài đặt, ghi lại vị trí file client mà script in ra.

## 3. Kiểm tra và tải client

Trên VPS:

```bash
sudo systemctl status wg-quick@wg0 --no-pager
sudo wg show
```

File `.conf` của client chứa **private key**. Tải riêng về máy tính bằng SFTP/WinSCP hoặc `scp`, rồi import vào ứng dụng WireGuard. Không gửi file client lên GitHub hoặc chat. Kết nối thật trên điện thoại/máy tính và kiểm tra lưu lượng trước khi coi là hoàn tất.

## 4. Tạo thêm client

Bạn có thể chạy lại `sudo bash wireguard-install.sh` để dùng menu quản lý client của script. Script phụ `create-multiple-clients.sh` của bản 2024 tạo hàng loạt client; chỉ dùng sau khi đã kiểm tra dải IP/cổng của `wg0` và sao lưu cấu hình. Không chạy nó trên máy đang vận hành khi chưa đối chiếu các peer hiện có.

Nếu gặp lỗi, chụp thông báo và kết quả `sudo systemctl status wg-quick@wg0 --no-pager`; đừng chụp nội dung `wg0.conf` hoặc file client vì chứa private key.

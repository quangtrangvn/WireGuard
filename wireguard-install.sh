#!/usr/bin/env bash
# Interactive WireGuard installer based on the repository's 2024 question flow.
# Server and firewall changes are confined to installer-owned files and nft tables.
set -Eeuo pipefail
umask 077

WG_DIR=/etc/wireguard
WG_CONF=$WG_DIR/wg0.conf
STATE_DIR=/var/lib/wg-installer
STATE=$STATE_DIR/state.env
FW_DIR=/usr/local/lib/wg-installer
VPN_NET=10.7.0.0/24
VPN_SERVER=10.7.0.1/24

err(){ printf 'Lỗi: %s\n' "$*" >&2; exit 1; }
[[ $EUID == 0 ]] || err 'Hãy chạy: sudo bash wireguard-install.sh'
command -v systemctl >/dev/null && [[ -d /run/systemd/system ]] || err 'Bản này yêu cầu systemd; chưa hỗ trợ OpenRC.'

os_family(){
  . /etc/os-release
  case " ${ID:-} ${ID_LIKE:-} " in
    *ubuntu*|*debian*|*linuxmint*|*raspbian*) echo apt ;;
    *fedora*|*rhel*|*centos*|*rocky*|*almalinux*|*ol*) echo rpm ;;
    *arch*|*manjaro*) echo pacman ;;
    *suse*|*opensuse*) echo zypper ;;
    *) err "Linux ${ID:-unknown} chưa được hỗ trợ; không thay đổi hệ thống." ;;
  esac
}

validate_ip(){
  local a part
  [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  IFS=. read -r -a a <<< "$1"
  for part in "${a[@]}"; do (( ${#part} <= 3 && 10#$part <= 255 )) || return 1; done
}

validate_name(){ [[ $1 =~ ^[a-zA-Z][a-zA-Z0-9_-]{0,31}$ ]]; }

pick_dns(){
  local choice
  printf 'DNS client: 1) Cloudflare  2) Google  3) Quad9  4) AdGuard  5) Tự nhập\n'
  while :; do
    read -r -p 'Chọn [1]: ' choice
    case "${choice:-1}" in
      1) DNS='1.1.1.1, 1.0.0.1'; return ;;
      2) DNS='8.8.8.8, 8.8.4.4'; return ;;
      3) DNS='9.9.9.9, 149.112.112.112'; return ;;
      4) DNS='94.140.14.14, 94.140.15.15'; return ;;
      5)
        local first second
        read -r -p 'DNS IPv4 thứ nhất: ' first
        read -r -p 'DNS IPv4 thứ hai: ' second
        if validate_ip "$first" && validate_ip "$second"; then DNS="$first, $second"; return; fi
        printf 'DNS không hợp lệ.\n' ;;
      *) printf 'Chọn từ 1 đến 5.\n' ;;
    esac
  done
}

check_preflight(){
  [[ ! -e $WG_CONF && ! -e $STATE ]] || err 'Đã có WireGuard hoặc state. Không ghi đè; dùng menu quản lý.'
  command -v ip >/dev/null && command -v ss >/dev/null || err 'Thiếu iproute2.'
  OUT_IF=$(ip -4 route show default | awk 'NR==1 {for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1);exit}}')
  [[ -n $OUT_IF ]] || err 'Không tìm thấy interface Internet.'
  ip -4 route get 10.7.0.1 | grep -q ' local ' && err 'Dải 10.7.0.0/24 đã được sử dụng.'
  ip -4 route | awk '$1=="10.7.0.0/24" {found=1} END {exit !found}' && err 'Dải 10.7.0.0/24 đã có route.'
  command -v modprobe >/dev/null && modprobe -n wireguard >/dev/null 2>&1 || err 'Kernel chưa có WireGuard. Không tải binary ngoài repository.'
  [[ ! -e /etc/nftables.d/wg-installer.nft ]] || err 'Đã có cấu hình WireGuard khác; dừng lại.'
}

install_packages(){
  local family
  family=$(os_family)
  case $family in
    apt) apt-get update; DEBIAN_FRONTEND=noninteractive apt-get install -y wireguard-tools nftables ;;
    rpm) command -v dnf >/dev/null || err 'Thiếu dnf.'
         dnf install -y wireguard-tools nftables ;;
    pacman) pacman -S --needed --noconfirm wireguard-tools nftables ;;
    zypper) zypper --non-interactive install wireguard-tools nftables ;;
  esac
  command -v wg >/dev/null && command -v wg-quick >/dev/null && command -v nft >/dev/null || err 'Package WireGuard/nftables chưa cài thành công.'
}

write_firewall(){
  install -d -m 700 "$FW_DIR"
  cat > "$FW_DIR/up.sh" <<EOF
#!/usr/bin/env bash
set -e
nft list table inet wg_installer >/dev/null 2>&1 && nft delete table inet wg_installer || true
nft list table ip wg_installer_nat >/dev/null 2>&1 && nft delete table ip wg_installer_nat || true
nft -f - <<NFT
add table inet wg_installer
add chain inet wg_installer input { type filter hook input priority -10; policy accept; }
add rule inet wg_installer input udp dport $PORT accept
add chain inet wg_installer forward { type filter hook forward priority -10; policy accept; }
add rule inet wg_installer forward iifname "wg0" oifname "$OUT_IF" accept
add rule inet wg_installer forward iifname "$OUT_IF" oifname "wg0" ct state established,related accept
add table ip wg_installer_nat
add chain ip wg_installer_nat postrouting { type nat hook postrouting priority srcnat; policy accept; }
add rule ip wg_installer_nat postrouting ip saddr $VPN_NET oifname "$OUT_IF" masquerade
NFT
EOF
  cat > "$FW_DIR/down.sh" <<'EOF'
#!/usr/bin/env bash
nft list table inet wg_installer >/dev/null 2>&1 && nft delete table inet wg_installer || true
nft list table ip wg_installer_nat >/dev/null 2>&1 && nft delete table ip wg_installer_nat || true
EOF
  chmod 700 "$FW_DIR/"*.sh
}

create_client(){
  local name=$1 number=2 private public psk server_public profile pskfile
  validate_name "$name" || err 'Tên client chỉ gồm chữ, số, dấu - hoặc _, bắt đầu bằng chữ.'
  profile="/root/$name-wg.conf"
  [[ ! -e $profile ]] && ! grep -Fq "# BEGIN_PEER $name" "$WG_CONF" || err 'Tên client đã tồn tại.'
  while grep -Eq "^AllowedIPs = 10\\.7\\.0\\.$number/32$" "$WG_CONF"; do ((number++)); done
  (( number < 255 )) || err 'Dải IP client đã hết.'
  private=$(wg genkey)
  public=$(printf '%s' "$private" | wg pubkey)
  psk=$(wg genpsk)
  server_public=$(wg show wg0 public-key)
  pskfile=$(mktemp)
  chmod 600 "$pskfile"
  printf '%s\n' "$psk" > "$pskfile"
  cat > "$profile" <<EOF
[Interface]
PrivateKey = $private
Address = 10.7.0.$number/24
DNS = $DNS

[Peer]
PublicKey = $server_public
PresharedKey = $psk
Endpoint = $ENDPOINT:$PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
  chmod 600 "$profile"
  if ! wg set wg0 peer "$public" preshared-key "$pskfile" allowed-ips "10.7.0.$number/32"; then
    rm -f "$pskfile" "$profile"
    err 'Không thể thêm peer vào WireGuard.'
  fi
  rm -f "$pskfile"
  cat >> "$WG_CONF" <<EOF
# BEGIN_PEER $name
[Peer]
PublicKey = $public
PresharedKey = $psk
AllowedIPs = 10.7.0.$number/32
# END_PEER $name
EOF
  printf 'Đã tạo %s (quyền 600). Hãy tải riêng về thiết bị, không gửi khóa lên chat.\n' "$profile"
}

install_main(){
  local choice local_ip
  check_preflight
  printf 'Cài WireGuard trên %s, VPN IPv4 %s. OpenVPN và proxy hiện có sẽ không bị sửa.\n' "$(hostname)" "$VPN_NET"
  local_ip=$(ip -4 -o addr show dev "$OUT_IF" | awk 'NR==1{split($4,a,"/");print a[1]}')
  read -r -p "IP public hoặc tên miền [${local_ip:-nhập thủ công}]: " ENDPOINT
  ENDPOINT=${ENDPOINT:-$local_ip}
  [[ $ENDPOINT =~ ^[a-zA-Z0-9.-]+$ ]] || err 'Endpoint không hợp lệ.'
  if [[ $ENDPOINT =~ ^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.) ]]; then
    err 'Endpoint là IP nội bộ; cần IP public hoặc tên miền để client kết nối từ ngoài.'
  fi
  read -r -p 'Cổng UDP [51820]: ' PORT
  PORT=${PORT:-51820}
  [[ $PORT =~ ^[0-9]+$ ]] && (( 10#$PORT >= 1 && 10#$PORT <= 65535 )) || err 'Cổng không hợp lệ.'
  ss -H -lun | awk -v p=":$PORT" '$4 ~ (p "$") {used=1} END {exit !used}' && err 'Cổng UDP này đã được sử dụng.'
  read -r -p 'Tên client đầu tiên [client]: ' CLIENT
  CLIENT=${CLIENT:-client}
  validate_name "$CLIENT" || err 'Tên client không hợp lệ.'
  [[ ! -e "/root/$CLIENT-wg.conf" ]] || err 'File client đã tồn tại.'
  pick_dns
  printf 'Sẽ cài UDP/%s, endpoint %s, client %s, DNS %s.\n' "$PORT" "$ENDPOINT" "$CLIENT" "$DNS"
  read -r -p 'Xác nhận cài? [y/N]: ' choice
  [[ $choice == y || $choice == Y ]] || exit 0
  install_packages
  install -d -m 700 "$WG_DIR" "$STATE_DIR"
  write_firewall
  local server_private
  server_private=$(wg genkey)
  cat > "$WG_CONF" <<EOF
# Managed by wg-installer. Keep this file private.
[Interface]
Address = $VPN_SERVER
ListenPort = $PORT
PrivateKey = $server_private
PostUp = $FW_DIR/up.sh
PostDown = $FW_DIR/down.sh
EOF
  chmod 600 "$WG_CONF"
  cat > /etc/sysctl.d/99-wg-installer.conf <<'EOF'
net.ipv4.ip_forward=1
EOF
  sysctl -w net.ipv4.ip_forward=1 >/dev/null
  cat > "$STATE" <<EOF
PORT='$PORT'
ENDPOINT='$ENDPOINT'
DNS='$DNS'
OUT_IF='$OUT_IF'
EOF
  chmod 600 "$STATE"
  systemctl enable --now wg-quick@wg0.service || err 'WireGuard chưa khởi động; xem journalctl -u wg-quick@wg0.'
  wg show wg0 >/dev/null && ip link show wg0 >/dev/null || err 'wg0 chưa sẵn sàng.'
  create_client "$CLIENT"
  printf 'WireGuard đang chạy. Hãy mở UDP/%s trong Cloud Firewall và thử client từ thiết bị khác.\n' "$PORT"
}

manage_main(){
  local choice name
  [[ -r $WG_CONF && -r $STATE ]] || err 'Đã có wg0.conf ngoài phạm vi script này; không chỉnh sửa.'
  # shellcheck disable=SC1090
  . "$STATE"
  wg show wg0 >/dev/null || err 'wg0 không hoạt động.'
  printf '1) Thêm client\n2) Kiểm tra wg0\n3) Thoát\n'
  read -r -p 'Chọn [1-3]: ' choice
  case $choice in
    1) read -r -p 'Tên client mới: ' name; create_client "$name" ;;
    2) printf 'wg0 đang chạy trên UDP/%s; số peer: ' "$PORT"
       wg show wg0 peers | wc -l ;;
    *) exit 0 ;;
  esac
}

case ${1:-menu} in
  menu) if [[ -e $WG_CONF ]]; then manage_main; else install_main; fi ;;
  status) [[ -r $STATE ]] || err 'Chưa có state.'; . "$STATE"
          wg show wg0 >/dev/null && printf 'wg0 hoạt động, UDP/%s.\n' "$PORT" ;;
  *) err 'Dùng: sudo bash wireguard-install.sh [menu|status]' ;;
esac

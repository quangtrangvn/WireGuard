#!/bin/bash
# shellcheck disable=SC1091,SC2164,SC2034,SC1072,SC1073,SC1009

# Enhanced Secure OpenVPN server installer for Debian, Ubuntu, CentOS, Amazon Linux 2, Fedora, Oracle Linux 8, Arch Linux, Rocky Linux and AlmaLinux.
# Version: 2.0 Enhanced with AdGuard Family DNS and improved error handling
# Last Updated: 2024

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="/var/log/openvpn-install.log"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

# Initialize log file
touch "$LOG_FILE" 2>/dev/null || true

function isRoot() {
	if [ "$EUID" -ne 0 ]; then
		return 1
	fi
}

function tunAvailable() {
	if [ ! -e /dev/net/tun ]; then
		return 1
	fi
}

function checkDependencies() {
	log_info "Checking required dependencies..."
	local missing_deps=()
	
	for cmd in curl openssl sed awk grep; do
		if ! command -v "$cmd" &> /dev/null; then
			missing_deps+=("$cmd")
		fi
	done
	
	if [ ${#missing_deps[@]} -gt 0 ]; then
		log_error "Missing required commands: ${missing_deps[*]}"
		log_info "Installing missing dependencies..."
		if [[ $OS =~ (debian|ubuntu) ]]; then
			apt-get update
			apt-get install -y curl openssl sed gawk grep
		elif [[ $OS =~ (centos|amzn|oracle|fedora) ]]; then
			yum install -y curl openssl sed gawk grep
		fi
	else
		log_success "All dependencies available"
	fi
}

function checkOS() {
	if [[ -e /etc/debian_version ]]; then
		OS="debian"
		source /etc/os-release

		if [[ $ID == "debian" || $ID == "raspbian" ]]; then
			if [[ $VERSION_ID -lt 9 ]]; then
				log_warn "Your version of Debian is not supported."
				echo ""
				echo "However, if you're using Debian >= 9 or unstable/testing then you can continue, at your own risk."
				echo ""
				until [[ $CONTINUE =~ (y|n) ]]; do
					read -rp "Continue? [y/n]: " -e CONTINUE
				done
				if [[ $CONTINUE == "n" ]]; then
					exit 1
				fi
			fi
		elif [[ $ID == "ubuntu" ]]; then
			OS="ubuntu"
			MAJOR_UBUNTU_VERSION=$(echo "$VERSION_ID" | cut -d '.' -f1)
			if [[ $MAJOR_UBUNTU_VERSION -lt 16 ]]; then
				log_warn "Your version of Ubuntu is not supported."
				echo ""
				echo "However, if you're using Ubuntu >= 16.04 or beta, then you can continue, at your own risk."
				echo ""
				until [[ $CONTINUE =~ (y|n) ]]; do
					read -rp "Continue? [y/n]: " -e CONTINUE
				done
				if [[ $CONTINUE == "n" ]]; then
					exit 1
				fi
			fi
		fi
	elif [[ -e /etc/system-release ]]; then
		source /etc/os-release
		if [[ $ID == "fedora" || $ID_LIKE == "fedora" ]]; then
			OS="fedora"
		fi
		if [[ $ID == "centos" || $ID == "rocky" || $ID == "almalinux" ]]; then
			OS="centos"
			if [[ ${VERSION_ID%.*} -lt 7 ]]; then
				log_error "Your version of CentOS is not supported."
				echo ""
				echo "The script only support CentOS 7 and CentOS 8."
				echo ""
				exit 1
			fi
		fi
		if [[ $ID == "ol" ]]; then
			OS="oracle"
			if [[ ! $VERSION_ID =~ (8) ]]; then
				log_error "Your version of Oracle Linux is not supported."
				echo ""
				echo "The script only support Oracle Linux 8."
				exit 1
			fi
		fi
		if [[ $ID == "amzn" ]]; then
			OS="amzn"
			if [[ $VERSION_ID != "2" ]]; then
				log_warn "Your version of Amazon Linux is not supported."
				echo ""
				echo "The script only support Amazon Linux 2."
				echo ""
				exit 1
			fi
		fi
	elif [[ -e /etc/arch-release ]]; then
		OS=arch
	else
		log_error "Looks like you aren't running this installer on a Debian, Ubuntu, Fedora, CentOS, Amazon Linux 2, Oracle Linux 8 or Arch Linux system"
		exit 1
	fi
	log_success "Detected OS: $OS"
}

function initialCheck() {
	if ! isRoot; then
		log_error "Sorry, you need to run this as root"
		exit 1
	fi
	if ! tunAvailable; then
		log_error "TUN is not available"
		exit 1
	fi
	checkOS
	checkDependencies
}

function installUnbound() {
	log_info "Configuring Unbound DNS..."
	# If Unbound isn't installed, install it
	if [[ ! -e /etc/unbound/unbound.conf ]]; then

		if [[ $OS =~ (debian|ubuntu) ]]; then
			apt-get install -y unbound

			# Configuration
			echo 'interface: 10.8.0.1
access-control: 10.8.0.1/24 allow
hide-identity: yes
hide-version: yes
use-caps-for-id: yes
prefetch: yes' >>/etc/unbound/unbound.conf

		elif [[ $OS =~ (centos|amzn|oracle) ]]; then
			yum install -y unbound

			# Configuration
			sed -i 's|# interface: 0.0.0.0$|interface: 10.8.0.1|' /etc/unbound/unbound.conf
			sed -i 's|# access-control: 127.0.0.0/8 allow|access-control: 10.8.0.1/24 allow|' /etc/unbound/unbound.conf
			sed -i 's|# hide-identity: no|hide-identity: yes|' /etc/unbound/unbound.conf
			sed -i 's|# hide-version: no|hide-version: yes|' /etc/unbound/unbound.conf
			sed -i 's|use-caps-for-id: no|use-caps-for-id: yes|' /etc/unbound/unbound.conf

		elif [[ $OS == "fedora" ]]; then
			dnf install -y unbound

			# Configuration
			sed -i 's|# interface: 0.0.0.0$|interface: 10.8.0.1|' /etc/unbound/unbound.conf
			sed -i 's|# access-control: 127.0.0.0/8 allow|access-control: 10.8.0.1/24 allow|' /etc/unbound/unbound.conf
			sed -i 's|# hide-identity: no|hide-identity: yes|' /etc/unbound/unbound.conf
			sed -i 's|# hide-version: no|hide-version: yes|' /etc/unbound/unbound.conf
			sed -i 's|# use-caps-for-id: no|use-caps-for-id: yes|' /etc/unbound/unbound.conf

		elif [[ $OS == "arch" ]]; then
			pacman -Syu --noconfirm unbound

			# Get root servers list
			curl -o /etc/unbound/root.hints https://www.internic.net/domain/named.cache

			if [[ ! -f /etc/unbound/unbound.conf.old ]]; then
				mv /etc/unbound/unbound.conf /etc/unbound/unbound.conf.old
			fi

			echo 'server:
	use-syslog: yes
	do-daemonize: no
	username: "unbound"
	directory: "/etc/unbound"
	trust-anchor-file: trusted-key.key
	root-hints: root.hints
	interface: 10.8.0.1
	access-control: 10.8.0.1/24 allow
	port: 53
	num-threads: 2
	use-caps-for-id: yes
	harden-glue: yes
	hide-identity: yes
	hide-version: yes
	qname-minimisation: yes
	prefetch: yes' >/etc/unbound/unbound.conf
		fi

		# IPv6 DNS for all OS
		if [[ $IPV6_SUPPORT == 'y' ]]; then
			echo 'interface: fd42:42:42:42::1
access-control: fd42:42:42:42::/112 allow' >>/etc/unbound/unbound.conf
		fi

		if [[ ! $OS =~ (fedora|centos|amzn|oracle) ]]; then
			# DNS Rebinding fix
			echo "private-address: 10.0.0.0/8
private-address: fd42:42:42:42::/112
private-address: 172.16.0.0/12
private-address: 192.168.0.0/16
private-address: 169.254.0.0/16
private-address: fd00::/8
private-address: fe80::/10
private-address: 127.0.0.0/8
private-address: ::ffff:0:0/96" >>/etc/unbound/unbound.conf
		fi
	else # Unbound is already installed
		echo 'include: /etc/unbound/openvpn.conf' >>/etc/unbound/unbound.conf

		# Add Unbound 'server' for the OpenVPN subnet
		echo 'server:
interface: 10.8.0.1
access-control: 10.8.0.1/24 allow
hide-identity: yes
hide-version: yes
use-caps-for-id: yes
prefetch: yes
private-address: 10.0.0.0/8
private-address: fd42:42:42:42::/112
private-address: 172.16.0.0/12
private-address: 192.168.0.0/16
private-address: 169.254.0.0/16
private-address: fd00::/8
private-address: fe80::/10
private-address: 127.0.0.0/8
private-address: ::ffff:0:0/96' >/etc/unbound/openvpn.conf
		if [[ $IPV6_SUPPORT == 'y' ]]; then
			echo 'interface: fd42:42:42:42::1
access-control: fd42:42:42:42::/112 allow' >>/etc/unbound/openvpn.conf
		fi
	fi

	systemctl enable unbound
	systemctl restart unbound
	log_success "Unbound DNS configured"
}

function backupConfig() {
	if [ -f "$1" ]; then
		local backup_file="$1.backup.$(date +%Y%m%d_%H%M%S)"
		cp "$1" "$backup_file"
		log_info "Backup created: $backup_file"
	fi
}

function installQuestions() {
	echo ""
	echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
	echo -e "${BLUE}║  Welcome to Enhanced OpenVPN Installer v2.0        ║${NC}"
	echo -e "${BLUE}║  GitHub: https://github.com/quangtrangvn/openVPN  ║${NC}"
	echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
	echo ""

	log_info "I need to ask you a few questions before starting the setup."
	echo "You can leave the default options and just press enter if you are ok with them."
	echo ""
	echo "I need to know the IPv4 address of the network interface you want OpenVPN listening to."
	echo "Unless your server is behind NAT, it should be your public IPv4 address."

	# Detect public IPv4 address and pre-fill for the user
	IP=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | head -1)

	if [[ -z $IP ]]; then
		# Detect public IPv6 address
		IP=$(ip -6 addr | sed -ne 's|^.* inet6 \([^/]*\)/.* scope global.*$|\1|p' | head -1)
	fi
	APPROVE_IP=${APPROVE_IP:-n}
	if [[ $APPROVE_IP =~ n ]]; do
		read -rp "IP address: " -e -i "$IP" IP
	fi
	# If $IP is a private IP address, the server must be behind NAT
	if echo "$IP" | grep -qE '^(10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.|192\.168)'; then
		echo ""
		echo "It seems this server is behind NAT. What is its public IPv4 address or hostname?"
		echo "We need it for the clients to connect to the server."

		PUBLICIP=$(curl -s https://api.ipify.org)
		until [[ $ENDPOINT != "" ]]; do
			read -rp "Public IPv4 address or hostname: " -e -i "$PUBLICIP" ENDPOINT
		done
	fi

	echo ""
	log_info "Checking for IPv6 connectivity..."
	echo ""
	# "ping6" and "ping -6" availability varies depending on the distribution
	if type ping6 >/dev/null 2>&1; then
		PING6="ping6 -c3 ipv6.google.com > /dev/null 2>&1"
	else
		PING6="ping -6 -c3 ipv6.google.com > /dev/null 2>&1"
	fi
	if eval "$PING6"; then
		log_success "Your host appears to have IPv6 connectivity."
		SUGGESTION="y"
	else
		log_warn "Your host does not appear to have IPv6 connectivity."
		SUGGESTION="n"
	fi
	echo ""
	# Ask the user if they want to enable IPv6 regardless its availability.
	until [[ $IPV6_SUPPORT =~ (y|n) ]]; do
		read -rp "Do you want to enable IPv6 support (NAT)? [y/n]: " -e -i $SUGGESTION IPV6_SUPPORT
	done
	echo ""
	echo "What port do you want OpenVPN to listen to?"
	echo "   1) Default: 1194"
	echo "   2) Custom"
	echo "   3) Random [49152-65535]"
	until [[ $PORT_CHOICE =~ ^[1-3]$ ]]; do
		read -rp "Port choice [1-3]: " -e -i 1 PORT_CHOICE
	done
	case $PORT_CHOICE in
	1)
		PORT="1194"
		;;
	2)
		until [[ $PORT =~ ^[0-9]+$ ]] && [ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ]; do
			read -rp "Custom port [1-65535]: " -e -i 1194 PORT
		done
		;;
	3)
		# Generate random number within private ports range
		PORT=$(shuf -i49152-65535 -n1)
		log_success "Random Port: $PORT"
		;;
	esac
	echo ""
	echo "What protocol do you want OpenVPN to use?"
	echo "UDP is faster. Unless it is not available, you shouldn't use TCP."
	echo "   1) UDP"
	echo "   2) TCP"
	until [[ $PROTOCOL_CHOICE =~ ^[1-2]$ ]]; do
		read -rp "Protocol [1-2]: " -e -i 1 PROTOCOL_CHOICE
	done
	case $PROTOCOL_CHOICE in
	1)
		PROTOCOL="udp"
		;;
	2)
		PROTOCOL="tcp"
		;;
	esac
	echo ""
	echo "What DNS resolvers do you want to use with the VPN?"
	echo "   1) Current system resolvers (from /etc/resolv.conf)"
	echo "   2) Self-hosted DNS Resolver (Unbound)"
	echo "   3) Cloudflare (Anycast: worldwide)"
	echo "   4) Quad9 (Anycast: worldwide)"
	echo "   5) Quad9 uncensored (Anycast: worldwide)"
	echo "   6) FDN (France)"
	echo "   7) DNS.WATCH (Germany)"
	echo "   8) OpenDNS (Anycast: worldwide)"
	echo "   9) Google (Anycast: worldwide)"
	echo "   10) Yandex Basic (Russia)"
	echo "   11) AdGuard DNS (Anycast: worldwide)"
	echo "   12) AdGuard Family Protection (Blocks adult content)"
	echo "   13) NextDNS (Anycast: worldwide)"
	echo "   14) Custom"
	until [[ $DNS =~ ^[0-9]+$ ]] && [ "$DNS" -ge 1 ] && [ "$DNS" -le 14 ]; do
		read -rp "DNS [1-14]: " -e -i 3 DNS
		if [[ $DNS == 2 ]] && [[ -e /etc/unbound/unbound.conf ]]; then
			echo ""
			log_info "Unbound is already installed."
			echo "You can allow the script to configure it in order to use it from your OpenVPN clients"
			echo "We will simply add a second server to /etc/unbound/unbound.conf for the OpenVPN subnet."
			echo "No changes are made to the current configuration."
			echo ""

			until [[ $CONTINUE =~ (y|n) ]]; do
				read -rp "Apply configuration changes to Unbound? [y/n]: " -e CONTINUE
			done
			if [[ $CONTINUE == "n" ]]; then
				# Break the loop and cleanup
				unset DNS
				unset CONTINUE
			fi
		elif [[ $DNS == "14" ]]; then
			until [[ $DNS1 =~ ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; do
				read -rp "Primary DNS: " -e DNS1
			done
			until [[ $DNS2 =~ ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; do
				read -rp "Secondary DNS (optional): " -e DNS2
				if [[ $DNS2 == "" ]]; then
					break
				fi
			done
		fi
	done
	echo ""
	echo "Do you want to allow multiple simultaneous client connections?"
	echo "   1) Yes (Multiple devices/users can use same account) - RECOMMENDED"
	echo "   2) No (Only ONE device can use the account at a time)"
	until [[ $MULTI_CLIENT =~ ^[1-2]$ ]]; do
		read -rp "Allow multiple clients? [1-2]: " -e -i 1 MULTI_CLIENT
	done
	case $MULTI_CLIENT in
	1)
		ALLOW_DUPLICATE_CN="y"
		log_info "Multiple simultaneous connections ALLOWED"
		;;
	2)
		ALLOW_DUPLICATE_CN="n"
		log_warn "Only 1 simultaneous connection ALLOWED"
		;;
	esac
	echo ""
	echo "Do you want to use compression? It is not recommended since the VORACLE attack makes use of it."
	until [[ $COMPRESSION_ENABLED =~ (y|n) ]]; do
		read -rp "Enable compression? [y/n]: " -e -i n COMPRESSION_ENABLED
	done
	if [[ $COMPRESSION_ENABLED == "y" ]]; then
		echo "Choose which compression algorithm you want to use: (they are ordered by efficiency)"
		echo "   1) LZ4-v2"
		echo "   2) LZ4"
		echo "   3) LZO"
		until [[ $COMPRESSION_CHOICE =~ ^[1-3]$ ]]; do
			read -rp "Compression algorithm [1-3]: " -e -i 1 COMPRESSION_CHOICE
		done
		case $COMPRESSION_CHOICE in
		1)
			COMPRESSION_ALG="lz4-v2"
			;;
		2)
			COMPRESSION_ALG="lz4"
			;;
		3)
			COMPRESSION_ALG="lzo"
			;;
		esac
	fi
	echo ""
	echo "Do you want to customize encryption settings?"
	echo "Unless you know what you're doing, you should stick with the default parameters provided by the script."
	echo "Note that whatever you choose, all the choices presented in the script are safe. (Unlike OpenVPN's defaults)"
	echo "See https://github.com/quangtrangvn/openVPN#security-and-encryption to learn more."
	echo ""
	until [[ $CUSTOMIZE_ENC =~ (y|n) ]]; do
		read -rp "Customize encryption settings? [y/n]: " -e -i n CUSTOMIZE_ENC
	done
	if [[ $CUSTOMIZE_ENC == "n" ]]; then
		# Use default, sane and fast parameters
		CIPHER="AES-128-GCM"
		CERT_TYPE="1" # ECDSA
		CERT_CURVE="prime256v1"
		CC_CIPHER="TLS-ECDHE-ECDSA-WITH-AES-128-GCM-SHA256"
		DH_TYPE="1" # ECDH
		DH_CURVE="prime256v1"
		HMAC_ALG="SHA256"
		TLS_SIG="1" # tls-crypt
	else
		echo ""
		echo "Choose which cipher you want to use for the data channel:"
		echo "   1) AES-128-GCM (recommended)"
		echo "   2) AES-192-GCM"
		echo "   3) AES-256-GCM"
		echo "   4) AES-128-CBC"
		echo "   5) AES-192-CBC"
		echo "   6) AES-256-CBC"
		until [[ $CIPHER_CHOICE =~ ^[1-6]$ ]]; do
			read -rp "Cipher [1-6]: " -e -i 1 CIPHER_CHOICE
		done
		case $CIPHER_CHOICE in
		1)
			CIPHER="AES-128-GCM"
			;;
		2)
			CIPHER="AES-192-GCM"
			;;
		3)
			CIPHER="AES-256-GCM"
			;;
		4)
			CIPHER="AES-128-CBC"
			;;
		5)
			CIPHER="AES-192-CBC"
			;;
		6)
			CIPHER="AES-256-CBC"
			;;
		esac
		echo ""
		echo "Choose what kind of certificate you want to use:"
		echo "   1) ECDSA (recommended)"
		echo "   2) RSA"
		until [[ $CERT_TYPE =~ ^[1-2]$ ]]; do
			read -rp "Certificate key type [1-2]: " -e -i 1 CERT_TYPE
		done
		case $CERT_TYPE in
		1)
			echo ""
			echo "Choose which curve you want to use for the certificate's key:"
			echo "   1) prime256v1 (recommended)"
			echo "   2) secp384r1"
			echo "   3) secp521r1"
			until [[ $CERT_CURVE_CHOICE =~ ^[1-3]$ ]]; do
				read -rp "Curve [1-3]: " -e -i 1 CERT_CURVE_CHOICE
			done
			case $CERT_CURVE_CHOICE in
			1)
				CERT_CURVE="prime256v1"
				;;
			2)
				CERT_CURVE="secp384r1"
				;;
			3)
				CERT_CURVE="secp521r1"
				;;
			esac
			;;
		2)
			echo ""
			echo "Choose which size you want to use for the certificate's RSA key:"
			echo "   1) 2048 bits (recommended)"
			echo "   2) 3072 bits"
			echo "   3) 4096 bits"
			until [[ $RSA_KEY_SIZE_CHOICE =~ ^[1-3]$ ]]; do
				read -rp "RSA key size [1-3]: " -e -i 1 RSA_KEY_SIZE_CHOICE
			done
			case $RSA_KEY_SIZE_CHOICE in
			1)
				RSA_KEY_SIZE="2048"
				;;
			2)
				RSA_KEY_SIZE="3072"
				;;
			3)
				RSA_KEY_SIZE="4096"
				;;
			esac
			;;
		esac
		echo ""
		echo "Choose which cipher you want to use for the control channel:"
		case $CERT_TYPE in
		1)
			echo "   1) ECDHE-ECDSA-AES-128-GCM-SHA256 (recommended)"
			echo "   2) ECDHE-ECDSA-AES-256-GCM-SHA384"
			until [[ $CC_CIPHER_CHOICE =~ ^[1-2]$ ]]; do
				read -rp "Control channel cipher [1-2]: " -e -i 1 CC_CIPHER_CHOICE
			done
			case $CC_CIPHER_CHOICE in
			1)
				CC_CIPHER="TLS-ECDHE-ECDSA-WITH-AES-128-GCM-SHA256"
				;;
			2)
				CC_CIPHER="TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384"
				;;
			esac
			;;
		2)
			echo "   1) ECDHE-RSA-AES-128-GCM-SHA256 (recommended)"
			echo "   2) ECDHE-RSA-AES-256-GCM-SHA384"
			until [[ $CC_CIPHER_CHOICE =~ ^[1-2]$ ]]; do
				read -rp "Control channel cipher [1-2]: " -e -i 1 CC_CIPHER_CHOICE
			done
			case $CC_CIPHER_CHOICE in
			1)
				CC_CIPHER="TLS-ECDHE-RSA-WITH-AES-128-GCM-SHA256"
				;;
			2)
				CC_CIPHER="TLS-ECDHE-RSA-WITH-AES-256-GCM-SHA384"
				;;
			esac
			;;
		esac
		echo ""
		echo "Choose what kind of Diffie-Hellman key you want to use:"
		echo "   1) ECDH (recommended)"
		echo "   2) DH"
		until [[ $DH_TYPE =~ [1-2] ]]; do
			read -rp "DH key type [1-2]: " -e -i 1 DH_TYPE
		done
		case $DH_TYPE in
		1)
			echo ""
			echo "Choose which curve you want to use for the ECDH key:"
			echo "   1) prime256v1 (recommended)"
			echo "   2) secp384r1"
			echo "   3) secp521r1"
			while [[ $DH_CURVE_CHOICE != "1" && $DH_CURVE_CHOICE != "2" && $DH_CURVE_CHOICE != "3" ]]; do
				read -rp "Curve [1-3]: " -e -i 1 DH_CURVE_CHOICE
			done
			case $DH_CURVE_CHOICE in
			1)
				DH_CURVE="prime256v1"
				;;
			2)
				DH_CURVE="secp384r1"
				;;
			3)
				DH_CURVE="secp521r1"
				;;
			esac
			;;
		2)
			echo ""
			echo "Choose what size of Diffie-Hellman key you want to use:"
			echo "   1) 2048 bits (recommended)"
			echo "   2) 3072 bits"
			echo "   3) 4096 bits"
			until [[ $DH_KEY_SIZE_CHOICE =~ ^[1-3]$ ]]; do
				read -rp "DH key size [1-3]: " -e -i 1 DH_KEY_SIZE_CHOICE
			done
			case $DH_KEY_SIZE_CHOICE in
			1)
				DH_KEY_SIZE="2048"
				;;
			2)
				DH_KEY_SIZE="3072"
				;;
			3)
				DH_KEY_SIZE="4096"
				;;
			esac
			;;
		esac
		echo ""
		# The "auth" options behaves differently with AEAD ciphers
		if [[ $CIPHER =~ CBC$ ]]; then
			echo "The digest algorithm authenticates data channel packets and tls-auth packets from the control channel."
		elif [[ $CIPHER =~ GCM$ ]]; then
			echo "The digest algorithm authenticates tls-auth packets from the control channel."
		fi
		echo "Which digest algorithm do you want to use for HMAC?"
		echo "   1) SHA-256 (recommended)"
		echo "   2) SHA-384"
		echo "   3) SHA-512"
		until [[ $HMAC_ALG_CHOICE =~ ^[1-3]$ ]]; do
			read -rp "Digest algorithm [1-3]: " -e -i 1 HMAC_ALG_CHOICE
		done
		case $HMAC_ALG_CHOICE in
		1)
			HMAC_ALG="SHA256"
			;;
		2)
			HMAC_ALG="SHA384"
			;;
		3)
			HMAC_ALG="SHA512"
			;;
		esac
		echo ""
		echo "You can add an additional layer of security to the control channel with tls-auth and tls-crypt"
		echo "tls-auth authenticates the packets, while tls-crypt authenticate and encrypt them."
		echo "   1) tls-crypt (recommended)"
		echo "   2) tls-auth"
		until [[ $TLS_SIG =~ [1-2] ]]; do
			read -rp "Control channel additional security mechanism [1-2]: " -e -i 1 TLS_SIG
		done
	fi
	echo ""
	echo -e "${GREEN}Okay, that was all I needed. We are ready to setup your OpenVPN server now.${NC}"
	echo "You will be able to generate a client at the end of the installation."
	APPROVE_INSTALL=${APPROVE_INSTALL:-n}
	if [[ $APPROVE_INSTALL =~ n ]]; do
		read -n1 -r -p "Press any key to continue..."
	fi
}

function installOpenVPN() {
	if [[ $AUTO_INSTALL == "y" ]]; then
		# Set default choices so that no questions will be asked.
		APPROVE_INSTALL=${APPROVE_INSTALL:-y}
		APPROVE_IP=${APPROVE_IP:-y}
		IPV6_SUPPORT=${IPV6_SUPPORT:-n}
		PORT_CHOICE=${PORT_CHOICE:-1}
		PROTOCOL_CHOICE=${PROTOCOL_CHOICE:-1}
		DNS=${DNS:-3}
		COMPRESSION_ENABLED=${COMPRESSION_ENABLED:-n}
		CUSTOMIZE_ENC=${CUSTOMIZE_ENC:-n}
		CLIENT=${CLIENT:-client}
		PASS=${PASS:-1}
		CONTINUE=${CONTINUE:-y}

		# Behind NAT, we'll default to the publicly reachable IPv4/IPv6.
		if [[ $IPV6_SUPPORT == "y" ]]; then
			if ! PUBLIC_IP=$(curl -f --retry 5 --retry-connrefused https://ip.seeip.org); then
				PUBLIC_IP=$(dig -6 TXT +short o-o.myaddr.l.google.com @ns1.google.com | tr -d '"')
			fi
		else
			if ! PUBLIC_IP=$(curl -f --retry 5 --retry-connrefused -4 https://ip.seeip.org); then
				PUBLIC_IP=$(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com | tr -d '"')
			fi
		fi
		ENDPOINT=${ENDPOINT:-$PUBLIC_IP}
	fi

	# Run setup questions first, and set other variables if auto-install
	installQuestions

	# Get the "public" interface from the default route
	NIC=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
	if [[ -z $NIC ]] && [[ $IPV6_SUPPORT == 'y' ]]; do
		NIC=$(ip -6 route show default | sed -ne 's/^default .* dev \([^ ]*\) .*$/\1/p')
	fi

	# $NIC can not be empty for script rm-openvpn-rules.sh
	if [[ -z $NIC ]]; then
		echo
		log_error "Can not detect public interface."
		echo "This needs for setup MASQUERADE."
		until [[ $CONTINUE =~ (y|n) ]]; do
			read -rp "Continue? [y/n]: " -e CONTINUE
		done
		if [[ $CONTINUE == "n" ]]; do
			exit 1
		fi
	fi

	# If OpenVPN isn't installed yet, install it
	if [[ ! -e /etc/openvpn/server.conf ]]; do
		log_info "Installing OpenVPN..."
		if [[ $OS =~ (debian|ubuntu) ]]; do
			apt-get update
			apt-get -y install ca-certificates gnupg
			# We add the OpenVPN repo to get the latest version.
			if [[ $VERSION_ID == "16.04" ]]; do
				echo "deb http://build.openvpn.net/debian/openvpn/stable xenial main" >/etc/apt/sources.list.d/openvpn-aptly.list
			else
				echo "deb http://build.openvpn.net/debian/openvpn/stable $(lsb_release -sc) main" >/etc/apt/sources.list.d/openvpn-aptly.list
			fi
			wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add -
			apt-get update
			apt-get install -y openvpn
		elif [[ $OS == "ubuntu" ]]; do
			apt-get update
			apt-get -y install ca-certificates gnupg
			echo "deb http://build.openvpn.net/debian/openvpn/stable $(lsb_release -sc) main" >/etc/apt/sources.list.d/openvpn-aptly.list
			wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add -
			apt-get update
			apt-get install -y openvpn
		elif [[ $OS =~ (fedora|centos|amzn|oracle) ]]; do
			yum install -y openvpn
		elif [[ $OS == "arch" ]]; do
			pacman -Syu --noconfirm openvpn
		fi
		log_success "OpenVPN installed"
	fi

	# If easy-rsa isn't already installed, install it
	if [[ ! -d /etc/openvpn/easy-rsa/ ]]; do
		log_info "Installing easy-rsa..."
		local EASYRSA_URL="https://github.com/OpenVPN/easy-rsa/releases/download/v3.1.2/EasyRSA-3.1.2.tgz"
		mkdir -p /etc/openvpn/easy-rsa/
		curl -sL "$EASYRSA_URL" -o - | tar xz -C /etc/openvpn/easy-rsa/ --strip-components 1
		chown -R root:root /etc/openvpn/easy-rsa/
		log_success "easy-rsa installed"
	fi

	log_info "Generating certificates and keys..."
	
	cd /etc/openvpn/easy-rsa/
	case $CERT_TYPE in
	1)
		./easyrsa build-ca nopass <<< "$" 2>/dev/null
		./easyrsa build-server-full server nopass <<< "$" 2>/dev/null
		./easyrsa build-client-full "$CLIENT" nopass <<< "$" 2>/dev/null
		;;
	2)
		./easyrsa --rsa-key-size="$RSA_KEY_SIZE" build-ca nopass <<< "$" 2>/dev/null
		./easyrsa --rsa-key-size="$RSA_KEY_SIZE" build-server-full server nopass <<< "$" 2>/dev/null
		./easyrsa --rsa-key-size="$RSA_KEY_SIZE" build-client-full "$CLIENT" nopass <<< "$" 2>/dev/null
		;;
	esac

	# Move the stuff we need
	cp pki/ca.crt /etc/openvpn/server/
	cp pki/issued/server.crt /etc/openvpn/server/
	cp pki/private/server.key /etc/openvpn/server/
	cp pki/ca.crt /etc/openvpn/client/
	cp pki/issued/"$CLIENT".crt /etc/openvpn/client/
	cp pki/private/"$CLIENT".key /etc/openvpn/client/

	cd /etc/openvpn/
	
	# TLS authentication
	case $TLS_SIG in
	1)
		openvpn --genkey secret /etc/openvpn/server/ta.key
		cp /etc/openvpn/server/ta.key /etc/openvpn/client/
		;;
	2)
		openvpn --genkey secret /etc/openvpn/server/ta.key
		cp /etc/openvpn/server/ta.key /etc/openvpn/client/
		;;
	esac

	# Diffie-Hellman
	if [[ $DH_TYPE == "2" ]]; do
		log_info "Generating Diffie-Hellman key (this may take a while)..."
		openssl dhparam -out /etc/openvpn/server/dh.pem "$DH_KEY_SIZE"
	fi

	log_success "Certificates and keys generated"

	# Create server configuration
	log_info "Creating server configuration..."
	backupConfig /etc/openvpn/server.conf
	
	cat > /etc/openvpn/server.conf <<EOF
# OpenVPN Server Configuration
# Enhanced Configuration - v2.0

port $PORT
proto $PROTOCOL
dev tun
ca /etc/openvpn/server/ca.crt
cert /etc/openvpn/server/server.crt
key /etc/openvpn/server/server.key
EOF

	if [[ $DH_TYPE == "1" ]]; do
		echo "dh none" >> /etc/openvpn/server.conf
		echo "ecdh-curve $DH_CURVE" >> /etc/openvpn/server.conf
	elif [[ $DH_TYPE == "2" ]]; do
		echo "dh /etc/openvpn/server/dh.pem" >> /etc/openvpn/server.conf
	fi

	cat >> /etc/openvpn/server.conf <<EOF
topology subnet
server 10.8.0.0 255.255.255.0
EOF

	if [[ $IPV6_SUPPORT == 'y' ]]; do
		echo "server-ipv6 fd42:42:42:42::/112" >> /etc/openvpn/server.conf
	fi

	cat >> /etc/openvpn/server.conf <<EOF

ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
EOF

	if [[ $IPV6_SUPPORT == 'y' ]]; do
		echo 'push "redirect-gateway def1 ipv6 bypass-dhcp"' >> /etc/openvpn/server.conf
	fi

	# DNS configuration
	case $DNS in
	1)
		# System DNS - get from /etc/resolv.conf
		while IFS= read -r line; do
			if [[ $line =~ ^nameserver ]]; do
				echo "push \"dhcp-option DNS ${line#nameserver }\"" >> /etc/openvpn/server.conf
			fi
		done < /etc/resolv.conf
		;;
	2)
		echo 'push "dhcp-option DNS 10.8.0.1"' >> /etc/openvpn/server.conf
		installUnbound
		;;
	3)
		echo 'push "dhcp-option DNS 1.1.1.1"' >> /etc/openvpn/server.conf
		echo 'push "dhcp-option DNS 1.0.0.1"' >> /etc/openvpn/server.conf
		;;
	4)
		echo 'push "dhcp-option DNS 9.9.9.9"' >> /etc/openvpn/server.conf
		echo 'push "dhcp-option DNS 149.112.112.112"' >> /etc/openvpn/server.conf
		;;
	5)
		echo 'push "dhcp-option DNS 9.9.9.10"' >> /etc/openvpn/server.conf
		echo 'push "dhcp-option DNS 149.112.112.10"' >> /etc/openvpn/server.conf
		;;
	6)
		echo 'push "dhcp-option DNS 80.67.169.40"' >> /etc/openvpn/server.conf
		echo 'push "dhcp-option DNS 80.67.169.12"' >> /etc/openvpn/server.conf
		;;
	7)
		echo 'push "dhcp-option DNS 84.200.69.80"' >> /etc/openvpn/server.conf
		echo 'push "dhcp-option DNS 84.200.70.40"' >> /etc/openvpn/server.conf
		;;
	8)
		echo 'push "dhcp-option DNS 208.67.222.222"' >> /etc/openvpn/server.conf
		echo 'push "dhcp-option DNS 208.67.220.220"' >> /etc/openvpn/server.conf
		;;
	9)
		echo 'push "dhcp-option DNS 8.8.8.8"' >> /etc/openvpn/server.conf
		echo 'push "dhcp-option DNS 8.8.4.4"' >> /etc/openvpn/server.conf
		;;
	10)
		echo 'push "dhcp-option DNS 77.88.8.8"' >> /etc/openvpn/server.conf
		echo 'push "dhcp-option DNS 77.88.9.9"' >> /etc/openvpn/server.conf
		;;
	11)
		echo 'push "dhcp-option DNS 94.140.14.14"' >> /etc/openvpn/server.conf
		echo 'push "dhcp-option DNS 94.140.15.15"' >> /etc/openvpn/server.conf
		;;
	12)
		echo 'push "dhcp-option DNS 94.140.14.15"' >> /etc/openvpn/server.conf
		echo 'push "dhcp-option DNS 94.140.15.16"' >> /etc/openvpn/server.conf
		;;
	13)
		echo 'push "dhcp-option DNS 45.33.32.22"' >> /etc/openvpn/server.conf
		echo 'push "dhcp-option DNS 45.55.25.25"' >> /etc/openvpn/server.conf
		;;
	14)
		echo "push \"dhcp-option DNS $DNS1\"" >> /etc/openvpn/server.conf
		if [[ -n $DNS2 ]]; do
			echo "push \"dhcp-option DNS $DNS2\"" >> /etc/openvpn/server.conf
		fi
		;;
	esac

	cat >> /etc/openvpn/server.conf <<EOF
push "block-outside-dns"
keepalive 20 60
EOF

	# Encryption
	echo "cipher $CIPHER" >> /etc/openvpn/server.conf
	echo "auth $HMAC_ALG" >> /etc/openvpn/server.conf
	
	# TLS options
	case $TLS_SIG in
	1)
		echo "tls-crypt /etc/openvpn/server/ta.key" >> /etc/openvpn/server.conf
		;;
	2)
		echo "tls-auth /etc/openvpn/server/ta.key 0" >> /etc/openvpn/server.conf
		;;
	esac

	cat >> /etc/openvpn/server.conf <<EOF
tls-version-min 1.2
tls-cipher "$CC_CIPHER"
status openvpn-status.log
status-version 3
mute-replay-warnings
dh none
ecdh-curve $DH_CURVE
comp-lzo no
user nobody
group nogroup
persist-key
persist-tun
log-append /var/log/openvpn/server.log
verb 3
client-to-client
EOF

	# Add duplicate-cn option based on user choice
	if [[ $ALLOW_DUPLICATE_CN == "y" ]]; then
		echo "# Allow multiple simultaneous client connections" >> /etc/openvpn/server.conf
		echo "duplicate-cn" >> /etc/openvpn/server.conf
	else
		echo "# Only one simultaneous client connection per certificate" >> /etc/openvpn/server.conf
		echo "# duplicate-cn option is disabled" >> /etc/openvpn/server.conf
	fi

	if [[ $COMPRESSION_ENABLED == "y" ]]; do
		echo "compress $COMPRESSION_ALG" >> /etc/openvpn/server.conf
		echo "push \"compress $COMPRESSION_ALG\"" >> /etc/openvpn/server.conf
	fi

	log_success "Server configuration created"

	# Enable OpenVPN
	systemctl enable openvpn-server@server.service
	systemctl start openvpn-server@server.service

	# Check if it's running
	if systemctl is-active --quiet openvpn-server@server.service; do
		log_success "OpenVPN server is running"
	else
		log_error "OpenVPN server failed to start. Check logs with: journalctl -u openvpn-server@server -n 50"
		exit 1
	fi

	# Create client configuration
	log_info "Creating client configuration..."
	cat > /etc/openvpn/client.ovpn <<EOF
client
dev tun
proto $PROTOCOL
remote ${ENDPOINT} ${PORT}
resolv-retry infinite
nobind
user nobody
group nogroup
persist-key
persist-tun
ca ca.crt
cert ${CLIENT}.crt
key ${CLIENT}.key
EOF

	case $TLS_SIG in
	1)
		echo "tls-crypt ta.key" >> /etc/openvpn/client.ovpn
		;;
	2)
		echo "tls-auth ta.key 1" >> /etc/openvpn/client.ovpn
		;;
	esac

	cat >> /etc/openvpn/client.ovpn <<EOF
tls-version-min 1.2
tls-cipher "$CC_CIPHER"
cipher $CIPHER
auth $HMAC_ALG
remote-cert-tls server
block-outside-dns
EOF

	if [[ $COMPRESSION_ENABLED == "y" ]]; do
		echo "compress $COMPRESSION_ALG" >> /etc/openvpn/client.ovpn
	fi

	# Create inline config with embedded certificates
	log_info "Creating inline client configuration..."
	cat > /etc/openvpn/${CLIENT}.ovpn <<EOF
client
dev tun
proto $PROTOCOL
remote ${ENDPOINT} ${PORT}
resolv-retry infinite
nobind
user nobody
group nogroup
persist-key
persist-tun

tls-version-min 1.2
tls-cipher "$CC_CIPHER"
cipher $CIPHER
auth $HMAC_ALG
remote-cert-tls server
block-outside-dns
EOF

	if [[ $COMPRESSION_ENABLED == "y" ]]; do
		echo "compress $COMPRESSION_ALG" >> /etc/openvpn/${CLIENT}.ovpn
	fi

	cat >> /etc/openvpn/${CLIENT}.ovpn <<EOF

<ca>
EOF
	cat /etc/openvpn/client/ca.crt >> /etc/openvpn/${CLIENT}.ovpn
	cat >> /etc/openvpn/${CLIENT}.ovpn <<EOF
</ca>

<cert>
EOF
	cat /etc/openvpn/client/${CLIENT}.crt >> /etc/openvpn/${CLIENT}.ovpn
	cat >> /etc/openvpn/${CLIENT}.ovpn <<EOF
</cert>

<key>
EOF
	cat /etc/openvpn/client/${CLIENT}.key >> /etc/openvpn/${CLIENT}.ovpn
	cat >> /etc/openvpn/${CLIENT}.ovpn <<EOF
</key>

EOF

	case $TLS_SIG in
	1)
		echo "<tls-crypt>" >> /etc/openvpn/${CLIENT}.ovpn
		cat /etc/openvpn/client/ta.key >> /etc/openvpn/${CLIENT}.ovpn
		echo "</tls-crypt>" >> /etc/openvpn/${CLIENT}.ovpn
		;;
	2)
		echo "<tls-auth>" >> /etc/openvpn/${CLIENT}.ovpn
		cat /etc/openvpn/client/ta.key >> /etc/openvpn/${CLIENT}.ovpn
		echo "</tls-auth>" >> /etc/openvpn/${CLIENT}.ovpn
		;;
	esac

	chmod 600 /etc/openvpn/${CLIENT}.ovpn
	cp /etc/openvpn/${CLIENT}.ovpn /root/${CLIENT}.ovpn

	log_success "Client configuration created"

	# Firewall
	log_info "Configuring firewall..."
	if command -v ufw &> /dev/null; do
		ufw allow "OpenVPN"
		ufw allow $PORT/$PROTOCOL
	elif command -v firewall-cmd &> /dev/null; do
		firewall-cmd --permanent --add-service=openvpn
		firewall-cmd --permanent --add-port=$PORT/$PROTOCOL
		firewall-cmd --reload
	fi

	# IP forwarding
	sysctl -w net.ipv4.ip_forward=1 > /dev/null
	echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

	if [[ $IPV6_SUPPORT == 'y' ]]; do
		sysctl -w net.ipv6.conf.all.forwarding=1 > /dev/null
		echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
	fi

	log_success "Firewall and IP forwarding configured"

	log_success "OpenVPN installation completed successfully!"
	echo ""
	echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
	echo -e "${GREEN}✓ Your OpenVPN server is ready!${NC}"
	echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
	echo ""
	echo -e "Client config file: ${BLUE}/root/${CLIENT}.ovpn${NC}"
	echo -e "Server config file: ${BLUE}/etc/openvpn/server.conf${NC}"
	echo ""
	echo -e "${YELLOW}Important:${NC}"
	echo "1. Download the client config from /root/${CLIENT}.ovpn"
	echo "2. Import it into OpenVPN Connect, Tunnelblick, or your VPN app"
	echo "3. Check OpenVPN status: ${BLUE}systemctl status openvpn-server@server${NC}"
	echo "4. View logs: ${BLUE}journalctl -u openvpn-server@server -f${NC}"
	echo ""
	
	# Show multi-client info
	if [[ $ALLOW_DUPLICATE_CN == "y" ]]; then
		echo -e "${GREEN}✓ Multiple simultaneous connections: ALLOWED${NC}"
		echo "  → Multiple devices/users can use the same client certificate"
		echo "  → This certificate can be shared with multiple people"
	else
		echo -e "${YELLOW}⚠ Multiple simultaneous connections: DISABLED${NC}"
		echo "  → Only ONE device can use this certificate at a time"
		echo "  → If you need multiple devices, create separate client certificates"
	fi
	echo ""
	echo -e "${YELLOW}Useful commands:${NC}"
	echo "• Start server: systemctl start openvpn-server@server"
	echo "• Stop server: systemctl stop openvpn-server@server"
	echo "• Restart server: systemctl restart openvpn-server@server"
	echo "• View status: systemctl status openvpn-server@server"
	echo "• Live logs: tail -f /var/log/openvpn/server.log"
	echo ""
	echo -e "${YELLOW}To add more clients:${NC}"
	echo "cd /etc/openvpn/easy-rsa && ./easyrsa build-client-full CLIENT_NAME nopass"
	echo ""
}

# Main execution
initialCheck
installOpenVPN

log_success "Installation logged to: $LOG_FILE"

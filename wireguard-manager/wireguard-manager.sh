#!/usr/bin/env bash
# https://github.com/complexorganizations/wireguard-manager

# Require script to be run as root
function super-user-check() {
  if [ "${EUID}" -ne 0 ]; then
    echo "Error: You need to run this script as administrator."
    exit
  fi
}

# Check for root
super-user-check

# User on the CLI
CLIENT_USER="${2}"

# Custom expiration
CUSTOM_EXPIRE="${3}"

# Get the current system information
function system-information() {
  if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    CURRENT_DISTRO=${ID}
    CURRENT_DISTRO_VERSION=${VERSION_ID}
  fi
}

# Get the current system information
system-information

# Pre-Checks system requirements
function installing-system-requirements() {
  if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ] || [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ] || [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ] || [ "${CURRENT_DISTRO}" == "alpine" ] || [ "${CURRENT_DISTRO}" == "freebsd" ]; }; then
    if { [ ! -x "$(command -v curl)" ] || [ ! -x "$(command -v cut)" ] || [ ! -x "$(command -v jq)" ] || [ ! -x "$(command -v ip)" ] || [ ! -x "$(command -v lsof)" ] || [ ! -x "$(command -v cron)" ] || [ ! -x "$(command -v awk)" ] || [ ! -x "$(command -v pgrep)" ] || [ ! -x "$(command -v grep)" ] || [ ! -x "$(command -v qrencode)" ] || [ ! -x "$(command -v sed)" ] || [ ! -x "$(command -v zip)" ] || [ ! -x "$(command -v unzip)" ] || [ ! -x "$(command -v openssl)" ] || [ ! -x "$(command -v iptables)" ] || [ ! -x "$(command -v bc)" ] || [ ! -x "$(command -v ifup)" ] || [ ! -x "$(command -v chattr)" ] || [ ! -x "$(command -v gpg)" ] || [ ! -x "$(command -v systemd-detect-virt)" ]; }; then
      if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
        apt-get update
        apt-get install curl coreutils jq iproute2 lsof cron gawk procps grep qrencode sed zip unzip openssl iptables bc ifupdown e2fsprogs gnupg systemd -y
      elif { [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
        yum update -y
        yum install epel-release elrepo-release -y
        yum install curl coreutils jq iproute lsof cronie gawk procps-ng grep qrencode sed zip unzip openssl iptables bc NetworkManager e2fsprogs gnupg systemd -y
      elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
        pacman -Syu --noconfirm --needed curl coreutils jq iproute2 lsof cronie gawk procps-ng grep qrencode sed zip unzip openssl iptables bc ifupdown e2fsprogs gnupg systemd
      elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
        apk update
        apk add curl coreutils jq iproute2 lsof cronie gawk procps grep qrencode sed zip unzip openssl iptables bc ifupdown e2fsprogs gnupg systemd
      elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
        pkg update
        pkg install curl coreutils jq iproute2 lsof cronie gawk procps grep qrencode sed zip unzip openssl iptables bc ifupdown e2fsprogs gnupg systemd
      fi
    fi
  else
    echo "Error: ${CURRENT_DISTRO} ${CURRENT_DISTRO_VERSION} is not supported."
    exit
  fi
}

# check for requirements
installing-system-requirements

# Checking For Virtualization
function virt-check() {
  # Deny certain virtualization
  case $(systemd-detect-virt) in
  "kvm" | "none" | "qemu") ;;
  *)
    echo "$(systemd-detect-virt) virtualization is not supported (yet)."
    exit
    ;;
  esac
}

# Virtualization Check
virt-check

# Lets check the kernel version
function kernel-check() {
  CURRENT_KERNEL_VERSION=$(uname -r | cut -d'.' -f1-2)
  ALLOWED_KERNEL_VERSION="3.1"
  if (($(echo "${CURRENT_KERNEL_VERSION} <= ${ALLOWED_KERNEL_VERSION}" | bc -l))); then
    echo "Error: Kernel ${CURRENT_KERNEL_VERSION} not supported, please update to ${ALLOWED_KERNEL_VERSION}."
    exit
  fi
}

kernel-check

# Global variables
CURRENT_FILE_PATH=$(realpath "${0}")
WIREGUARD_WEBSITE_URL="https://www.wireguard.com"
WIREGUARD_PATH="/etc/wireguard"
WIREGUARD_CLIENT_PATH="${WIREGUARD_PATH}/clients"
WIREGUARD_PUB_NIC="wg0"
WIREGUARD_CONFIG="${WIREGUARD_PATH}/${WIREGUARD_PUB_NIC}.conf"
WIREGUARD_ADD_PEER_CONFIG="${WIREGUARD_PATH}/${WIREGUARD_PUB_NIC}-add-peer.conf"
SYSTEM_BACKUP_PATH="/var/backups"
WIREGUARD_CONFIG_BACKUP="${SYSTEM_BACKUP_PATH}/wireguard-manager.zip"
WIREGUARD_BACKUP_PASSWORD_PATH="${HOME}/.wireguard-manager"
WIREGUARD_IP_FORWARDING_CONFIG="/etc/sysctl.d/wireguard.conf"
RESOLV_CONFIG="/etc/resolv.conf"
RESOLV_CONFIG_OLD="${RESOLV_CONFIG}.old"
UNBOUND_ROOT="/etc/unbound"
UNBOUND_MANAGER="${UNBOUND_ROOT}/wireguard-manager"
UNBOUND_CONFIG="${UNBOUND_ROOT}/unbound.conf"
UNBOUND_ROOT_HINTS="${UNBOUND_ROOT}/root.hints"
UNBOUND_ANCHOR="/var/lib/unbound/root.key"
UNBOUND_CONFIG_HOST="${UNBOUND_ROOT}/unbound.conf.d/hosts.conf"
case $(shuf -i1-6 -n1) in
1)
  UNBOUND_ROOT_SERVER_CONFIG_URL="https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/assets/named.cache"
  ;;
2)
  UNBOUND_ROOT_SERVER_CONFIG_URL="https://cdn.statically.io/gh/complexorganizations/wireguard-manager/main/assets/named.cache"
  ;;
3)
  UNBOUND_ROOT_SERVER_CONFIG_URL="https://cdn.jsdelivr.net/gh/complexorganizations/wireguard-manager/assets/named.cache"
  ;;
4)
  UNBOUND_ROOT_SERVER_CONFIG_URL="https://combinatronics.io/complexorganizations/wireguard-manager/main/assets/named.cache"
  ;;
5)
  UNBOUND_ROOT_SERVER_CONFIG_URL="https://www.internic.net/domain/named.cache"
  ;;
6)
  UNBOUND_ROOT_SERVER_CONFIG_URL="https://gitlab.com/prajwal-koirala/wireguard-manager/-/raw/main/assets/named.cache"
  ;;
esac
case $(shuf -i1-5 -n1) in
1)
  UNBOUND_CONFIG_HOST_URL="https://raw.githubusercontent.com/complexorganizations/content-blocker/main/assets/hosts"
  ;;
2)
  UNBOUND_CONFIG_HOST_URL="https://cdn.statically.io/gh/complexorganizations/content-blocker/main/assets/hosts"
  ;;
3)
  UNBOUND_CONFIG_HOST_URL="https://cdn.jsdelivr.net/gh/complexorganizations/content-blocker/assets/hosts"
  ;;
4)
  UNBOUND_CONFIG_HOST_URL="https://combinatronics.io/complexorganizations/content-blocker/main/assets/hosts"
  ;;
5)
  UNBOUND_CONFIG_HOST_URL="https://gitlab.com/prajwal-koirala/content-blocker/-/raw/main/assets/hosts"
  ;;
esac
case $(shuf -i1-1 -n1) in
1)
  WIREGUARD_MANAGER_UPDATE="https://wireguard-manager.sh"
  ;;
esac

# Usage Guide of the application
function usage-guide() {
  echo "usage: ./$(basename "${0}") <command>"
  echo "  --install     Install WireGuard Interface"
  echo "  --start       Start WireGuard Interface"
  echo "  --stop        Stop WireGuard Interface"
  echo "  --restart     Restart WireGuard Interface"
  echo "  --list        Show WireGuard Peer(s)"
  echo "  --add         Add WireGuard Peer"
  echo "  --remove      Remove WireGuard Peer"
  echo "  --reinstall   Reinstall WireGuard Interface"
  echo "  --uninstall   Uninstall WireGuard Interface"
  echo "  --update      Update WireGuard Manager"
  echo "  --ddns        Update WireGuard IP Address"
  echo "  --backup      Backup WireGuard"
  echo "  --restore     Restore WireGuard"
  echo "  --purge       Purge WireGuard Peer(s)"
  echo "  --help        Show Usage Guide"
}

# The usage of the script
function usage() {
  while [ $# -ne 0 ]; do
    case ${1} in
    --install)
      shift
      HEADLESS_INSTALL=${HEADLESS_INSTALL:-true}
      ;;
    --start)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-2}
      ;;
    --stop)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-3}
      ;;
    --restart)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-4}
      ;;
    --list)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-1}
      ;;
    --add)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-5}
      ;;
    --remove)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-6}
      ;;
    --reinstall)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-7}
      ;;
    --uninstall)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-8}
      ;;
    --update)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-9}
      ;;
    --backup)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-10}
      ;;
    --restore)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-11}
      ;;
    --ddns)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-12}
      ;;
    --purge)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-14}
      ;;
    --help)
      shift
      usage-guide
      ;;
    *)
      echo "Invalid argument: ${1}"
      usage-guide
      exit
      ;;
    esac
  done
}


# If the user name is on the CLI and the option is to remove the user
if [[ "${CLIENT_USER}" != "" && "${1}" == "--remove" ]]; then

	WIREGUARD_OPTIONS=6

# If the user name is on the CLI and the option is to add the user
elif [[ "${CLIENT_USER}" != "" && "${1}" == "--add" ]]; then

	WIREGUARD_OPTIONS=5

else

	usage "$@"

fi

# All questions are skipped, and wireguard is installed and a configuration is generated.
function headless-install() {
  if [ "${HEADLESS_INSTALL}" == true ]; then
    INTERFACE_OR_PEER=${INTERFACE_OR_PEER:-1}
    IPV4_SUBNET_SETTINGS=${IPV4_SUBNET_SETTINGS:-1}
    IPV6_SUBNET_SETTINGS=${IPV6_SUBNET_SETTINGS:-1}
    SERVER_HOST_V4_SETTINGS=${SERVER_HOST_V4_SETTINGS:-1}
    SERVER_HOST_V6_SETTINGS=${SERVER_HOST_V6_SETTINGS:-1}
    SERVER_PUB_NIC_SETTINGS=${SERVER_PUB_NIC_SETTINGS:-1}
    SERVER_PORT_SETTINGS=${SERVER_PORT_SETTINGS:-1}
    NAT_CHOICE_SETTINGS=${NAT_CHOICE_SETTINGS:-1}
    MTU_CHOICE_SETTINGS=${MTU_CHOICE_SETTINGS:-1}
    SERVER_HOST_SETTINGS=${SERVER_HOST_SETTINGS:-1}
    DISABLE_HOST_SETTINGS=${DISABLE_HOST_SETTINGS:-1}
    CLIENT_ALLOWED_IP_SETTINGS=${CLIENT_ALLOWED_IP_SETTINGS:-1}
    AUTOMATIC_UPDATES_SETTINGS=${AUTOMATIC_UPDATES_SETTINGS:-1}
    AUTOMATIC_BACKUP_SETTINGS=${AUTOMATIC_BACKUP_SETTINGS:-1}
    DNS_PROVIDER_SETTINGS=${DNS_PROVIDER_SETTINGS:-1}
    CONTENT_BLOCKER_SETTINGS=${CONTENT_BLOCKER_SETTINGS:-1}
    CLIENT_NAME=${CLIENT_NAME:-$(openssl rand -hex 50)}
    AUTOMATIC_CONFIG_REMOVER=${AUTOMATIC_CONFIG_REMOVER:-1}
  fi
}

# No GUI
headless-install

# Set up the wireguard, if config it isn't already there.
if [ ! -f "${WIREGUARD_CONFIG}" ]; then

  # Custom IPv4 subnet
  function set-ipv4-subnet() {
    echo "What IPv4 subnet do you want to use?"
    echo "  1) 10.0.0.0/8 (Recommended)"
    echo "  2) Custom (Advanced)"
    until [[ "${IPV4_SUBNET_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Subnet Choice [1-2]:" -e -i 1 IPV4_SUBNET_SETTINGS
    done
    case ${IPV4_SUBNET_SETTINGS} in
    1)
      IPV4_SUBNET="10.0.0.0/8"
      ;;
    2)
      read -rp "Custom IPv4 Subnet:" IPV4_SUBNET
      if [ -z "${IPV4_SUBNET}" ]; then
        IPV4_SUBNET="10.0.0.0/8"
      fi
      ;;
    esac
  }

  # Custom IPv4 Subnet
  set-ipv4-subnet

  # Custom IPv6 subnet
  function set-ipv6-subnet() {
    echo "What IPv6 subnet do you want to use?"
    echo "  1) fd00:00:00::0/8 (Recommended)"
    echo "  2) Custom (Advanced)"
    until [[ "${IPV6_SUBNET_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Subnet Choice [1-2]:" -e -i 1 IPV6_SUBNET_SETTINGS
    done
    case ${IPV6_SUBNET_SETTINGS} in
    1)
      IPV6_SUBNET="fd00:00:00::0/8"
      ;;
    2)
      read -rp "Custom IPv6 Subnet:" IPV6_SUBNET
      if [ -z "${IPV6_SUBNET}" ]; then
        IPV6_SUBNET="fd00:00:00::0/8"
      fi
      ;;
    esac
  }

  # Custom IPv6 Subnet
  set-ipv6-subnet

  # Private Subnet Ipv4
  PRIVATE_SUBNET_V4=${PRIVATE_SUBNET_V4:-"${IPV4_SUBNET}"}
  # Private Subnet Mask IPv4
  PRIVATE_SUBNET_MASK_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut -d "/" -f 2)
  # IPv4 Getaway
  GATEWAY_ADDRESS_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut -d'.' -f1-3).1
  # Private Subnet Ipv6
  PRIVATE_SUBNET_V6=${PRIVATE_SUBNET_V6:-"${IPV6_SUBNET}"}
  # Private Subnet Mask IPv6
  PRIVATE_SUBNET_MASK_V6=$(echo "${PRIVATE_SUBNET_V6}" | cut -d "/" -f 2)
  # IPv6 Getaway
  GATEWAY_ADDRESS_V6="${PRIVATE_SUBNET_V6::-3}1"

  # Get the IPv4
  function test-connectivity-v4() {
    echo "How would you like to detect IPv4?"
    echo "  1) Curl (Recommended)"
    echo "  2) Custom (Advanced)"
    until [[ "${SERVER_HOST_V4_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "IPv4 Choice [1-2]:" -e -i 1 SERVER_HOST_V4_SETTINGS
    done
    case ${SERVER_HOST_V4_SETTINGS} in
    1)
      SERVER_HOST_V4="$(curl -4 --connect-timeout 5 --tlsv1.3 -s 'https://api.ipengine.dev' | jq -r '.network.ip')"
      if [ -z "${SERVER_HOST_V4}" ]; then
        SERVER_HOST_V4="$(curl -4 --connect-timeout 5 --tlsv1.3 -s 'https://checkip.amazonaws.com')"
      fi
      ;;
    2)
      read -rp "Custom IPv4:" SERVER_HOST_V4
      if [ -z "${SERVER_HOST_V4}" ]; then
        SERVER_HOST_V4="$(curl -4 --connect-timeout 5 --tlsv1.3 -s 'https://api.ipengine.dev' | jq -r '.network.ip')"
      fi
      if [ -z "${SERVER_HOST_V4}" ]; then
        SERVER_HOST_V4="$(curl -4 --connect-timeout 5 --tlsv1.3 -s 'https://checkip.amazonaws.com')"
      fi
      ;;
    esac
  }

  # Get the IPv4
  test-connectivity-v4

  # Determine IPv6
  function test-connectivity-v6() {
    echo "How would you like to detect IPv6?"
    echo "  1) Curl (Recommended)"
    echo "  2) Custom (Advanced)"
    until [[ "${SERVER_HOST_V6_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "IPv6 Choice [1-2]:" -e -i 1 SERVER_HOST_V6_SETTINGS
    done
    case ${SERVER_HOST_V6_SETTINGS} in
    1)
      SERVER_HOST_V6="$(curl -6 --connect-timeout 5 --tlsv1.3 -s 'https://api.ipengine.dev' | jq -r '.network.ip')"
      if [ -z "${SERVER_HOST_V6}" ]; then
        SERVER_HOST_V6="$(curl -6 --connect-timeout 5 --tlsv1.3 -s 'https://checkip.amazonaws.com')"
      fi
      ;;
    2)
      read -rp "Custom IPv6:" SERVER_HOST_V6
      if [ -z "${SERVER_HOST_V6}" ]; then
        SERVER_HOST_V6="$(curl -6 --connect-timeout 5 --tlsv1.3 -s 'https://api.ipengine.dev' | jq -r '.network.ip')"
      fi
      if [ -z "${SERVER_HOST_V6}" ]; then
        SERVER_HOST_V6="$(curl -6 --connect-timeout 5 --tlsv1.3 -s 'https://checkip.amazonaws.com')"
      fi
      ;;
    esac
  }

  # Get the IPv6
  test-connectivity-v6

  # Determine public NIC
  function server-pub-nic() {
    echo "How would you like to detect NIC?"
    echo "  1) IP (Recommended)"
    echo "  2) Custom (Advanced)"
    until [[ "${SERVER_PUB_NIC_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Nic Choice [1-2]:" -e -i 1 SERVER_PUB_NIC_SETTINGS
    done
    case ${SERVER_PUB_NIC_SETTINGS} in
    1)
      SERVER_PUB_NIC="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)"
      if [ -z "${SERVER_PUB_NIC}" ]; then
        echo "Error: Your server's public network interface could not be found."
      fi
      ;;
    2)
      read -rp "Custom NAT:" SERVER_PUB_NIC
      if [ -z "${SERVER_PUB_NIC}" ]; then
        SERVER_PUB_NIC="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)"
      fi
      ;;
    esac
  }

  # Determine public NIC
  server-pub-nic

  # Determine host port
  function set-port() {
    echo "What port do you want WireGuard server to listen to?"
    echo "  1) 51820 (Recommended)"
    echo "  2) Custom (Advanced)"
    until [[ "${SERVER_PORT_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Port Choice [1-2]:" -e -i 1 SERVER_PORT_SETTINGS
    done
    case ${SERVER_PORT_SETTINGS} in
    1)
      SERVER_PORT="51820"
      if [ "$(lsof -i UDP:"${SERVER_PORT}")" ]; then
        echo "Error: Please use a different port because ${SERVER_PORT} is already in use."
      fi
      ;;
    2)
      until [[ "${SERVER_PORT}" =~ ^[0-9]+$ ]] && [ "${SERVER_PORT}" -ge 1 ] && [ "${SERVER_PORT}" -le 65535 ]; do
        read -rp "Custom port [1-65535]:" SERVER_PORT
      done
      if [ "$(lsof -i UDP:"${SERVER_PORT}")" ]; then
        echo "Error: The port ${SERVER_PORT} is already used by a different application, please use a different port."
      fi
      ;;
    esac
  }

  # Set port
  set-port

  # Determine Keepalive interval.
  function nat-keepalive() {
    echo "What do you want your keepalive interval to be?"
    echo "  1) 25 (Default)"
    echo "  2) Custom (Advanced)"
    until [[ "${NAT_CHOICE_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Nat Choice [1-2]:" -e -i 1 NAT_CHOICE_SETTINGS
    done
    case ${NAT_CHOICE_SETTINGS} in
    1)
      NAT_CHOICE="25"
      ;;
    2)
      until [[ "${NAT_CHOICE}" =~ ^[0-9]+$ ]] && [ "${NAT_CHOICE}" -ge 1 ] && [ "${NAT_CHOICE}" -le 65535 ]; do
        read -rp "Custom NAT [1-65535]:" NAT_CHOICE
      done
      ;;
    esac
  }

  # Keepalive interval
  nat-keepalive

  # Custom MTU or default settings
  function mtu-set() {
    echo "What MTU do you want to use?"
    echo "  1) 1280 (Recommended)"
    echo "  2) Custom (Advanced)"
    until [[ "${MTU_CHOICE_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "MTU Choice [1-2]:" -e -i 1 MTU_CHOICE_SETTINGS
    done
    case ${MTU_CHOICE_SETTINGS} in
    1)
      MTU_CHOICE="1280"
      ;;
    2)
      until [[ "${MTU_CHOICE}" =~ ^[0-9]+$ ]] && [ "${MTU_CHOICE}" -ge 1 ] && [ "${MTU_CHOICE}" -le 65535 ]; do
        read -rp "Custom MTU [1-65535]:" MTU_CHOICE
      done
      ;;
    esac
  }

  # Set MTU
  mtu-set

  # What IP version would you like to be available on this WireGuard server?
  function ipvx-select() {
    echo "What IPv do you want to use to connect to the WireGuard server?"
    echo "  1) IPv4 (Recommended)"
    echo "  2) IPv6"
    until [[ "${SERVER_HOST_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "IP Choice [1-2]:" -e -i 1 SERVER_HOST_SETTINGS
    done
    case ${SERVER_HOST_SETTINGS} in
    1)
      if [ -n "${SERVER_HOST_V4}" ]; then
        SERVER_HOST="${SERVER_HOST_V4}"
      else
        SERVER_HOST="[${SERVER_HOST_V6}]"
      fi
      ;;
    2)
      if [ -n "${SERVER_HOST_V6}" ]; then
        SERVER_HOST="[${SERVER_HOST_V6}]"
      else
        SERVER_HOST="${SERVER_HOST_V4}"
      fi
      ;;
    esac
  }

  # IPv4 or IPv6 Selector
  ipvx-select

  # Do you want to disable IPv4 or IPv6 or leave them both enabled?
  function disable-ipvx() {
    echo "Do you want to disable IPv4 or IPv6 on the server?"
    echo "  1) No (Recommended)"
    echo "  2) Disable IPv4"
    echo "  3) Disable IPv6"
    until [[ "${DISABLE_HOST_SETTINGS}" =~ ^[1-3]$ ]]; do
      read -rp "Disable Host Choice [1-3]:" -e -i 1 DISABLE_HOST_SETTINGS
    done
    case ${DISABLE_HOST_SETTINGS} in
    1)
      echo "net.ipv4.ip_forward=1" >${WIREGUARD_IP_FORWARDING_CONFIG}
      echo "net.ipv6.conf.all.forwarding=1" >>${WIREGUARD_IP_FORWARDING_CONFIG}
      ;;
    2)
      echo "net.ipv6.conf.all.forwarding=1" >${WIREGUARD_IP_FORWARDING_CONFIG}
      ;;
    3)
      echo "net.ipv4.ip_forward=1" >${WIREGUARD_IP_FORWARDING_CONFIG}
      ;;
    esac
    sysctl -p ${WIREGUARD_IP_FORWARDING_CONFIG}
  }

  # Disable IPv4 or IPv6
  disable-ipvx

  # Would you like to allow connections to your LAN neighbors?
  function client-allowed-ip() {
    echo "What traffic do you want the client to forward through WireGuard?"
    echo "  1) Everything (Recommended)"
    echo "  2) Custom (Advanced)"
    until [[ "${CLIENT_ALLOWED_IP_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Client Allowed IP Choice [1-2]:" -e -i 1 CLIENT_ALLOWED_IP_SETTINGS
    done
    case ${CLIENT_ALLOWED_IP_SETTINGS} in
    1)
      CLIENT_ALLOWED_IP="0.0.0.0/0,::/0"
      ;;
    2)
      read -rp "Custom IPs:" CLIENT_ALLOWED_IP
      if [ -z "${CLIENT_ALLOWED_IP}" ]; then
        CLIENT_ALLOWED_IP="0.0.0.0/0,::/0"
      fi
      ;;
    esac
  }

  # Traffic Forwarding
  client-allowed-ip

  # real-time updates
  function enable-automatic-updates() {
    echo "Would you like to setup real-time updates?"
    echo "  1) Yes (Recommended)"
    echo "  2) No (Advanced)"
    until [[ "${AUTOMATIC_UPDATES_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Automatic Updates [1-2]:" -e -i 1 AUTOMATIC_UPDATES_SETTINGS
    done
    case ${AUTOMATIC_UPDATES_SETTINGS} in
    1)
      crontab -l | {
        cat
        echo "0 0 * * * ${CURRENT_FILE_PATH} --update"
      } | crontab -
      if pgrep systemd-journal; then
        systemctl enable cron
        systemctl start cron
      else
        service cron enable
        service cron start
      fi
      ;;
    2)
      echo "Real-time Updates Disabled"
      ;;
    esac
  }

  # real-time updates
  enable-automatic-updates

  # real-time backup
  function enable-automatic-backup() {
    echo "Would you like to setup real-time backup?"
    echo "  1) Yes (Recommended)"
    echo "  2) No (Advanced)"
    until [[ "${AUTOMATIC_BACKUP_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Automatic Backup [1-2]:" -e -i 1 AUTOMATIC_BACKUP_SETTINGS
    done
    case ${AUTOMATIC_BACKUP_SETTINGS} in
    1)
      crontab -l | {
        cat
        echo "0 0 * * * ${CURRENT_FILE_PATH} --backup"
      } | crontab -
      if pgrep systemd-journal; then
        systemctl enable cron
        systemctl start cron
      else
        service cron enable
        service cron start
      fi
      ;;
    2)
      echo "Real-time Backup Disabled"
      ;;
    esac
  }

  # real-time backup
  enable-automatic-backup

  # Would you like to install unbound.
  function ask-install-dns() {
    echo "Which DNS provider would you like to use?"
    echo "  1) Unbound (Recommended)"
    echo "  2) Custom (Advanced)"
    until [[ "${DNS_PROVIDER_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "DNS provider [1-2]:" -e -i 1 DNS_PROVIDER_SETTINGS
    done
    case ${DNS_PROVIDER_SETTINGS} in
    1)
      INSTALL_UNBOUND=true
      echo "Do you want to prevent advertisements, tracking, malware, and phishing using the content-blocker?"
      echo "  1) Yes (Recommended)"
      echo "  2) No"
      until [[ "${CONTENT_BLOCKER_SETTINGS}" =~ ^[1-2]$ ]]; do
        read -rp "Content Blocker Choice [1-2]:" -e -i 1 CONTENT_BLOCKER_SETTINGS
      done
      case ${CONTENT_BLOCKER_SETTINGS} in
      1)
        INSTALL_BLOCK_LIST=true
        ;;
      2)
        INSTALL_BLOCK_LIST=false
        ;;
      esac
      ;;
    2)
      CUSTOM_DNS=true
      ;;
    esac
  }

  # Ask To Install DNS
  ask-install-dns

  # Let the users choose their custom dns provider.
  function custom-dns() {
    if [ "${CUSTOM_DNS}" == true ]; then
      echo "Which DNS do you want to use with the WireGuard connection?"
      echo "  1) Cloudflare (Recommended)"
      echo "  2) AdGuard"
      echo "  3) NextDNS"
      echo "  4) OpenDNS"
      echo "  5) Google"
      echo "  6) Verisign"
      echo "  7) Quad9"
      echo "  8) FDN"
      echo "  9) Custom (Advanced)"
      until [[ "${CLIENT_DNS_SETTINGS}" =~ ^[0-9]+$ ]] && [ "${CLIENT_DNS_SETTINGS}" -ge 1 ] && [ "${CLIENT_DNS_SETTINGS}" -le 9 ]; do
        read -rp "DNS [1-9]:" -e -i 1 CLIENT_DNS_SETTINGS
      done
      case ${CLIENT_DNS_SETTINGS} in
      1)
        CLIENT_DNS="1.1.1.1,1.0.0.1,2606:4700:4700::1111,2606:4700:4700::1001"
        ;;
      2)
        CLIENT_DNS="94.140.14.14,94.140.15.15,2a10:50c0::ad1:ff,2a10:50c0::ad2:ff"
        ;;
      3)
        CLIENT_DNS="45.90.28.167,45.90.30.167,2a07:a8c0::12:cf53,2a07:a8c1::12:cf53"
        ;;
      4)
        CLIENT_DNS="208.67.222.222,208.67.220.220,2620:119:35::35,2620:119:53::53"
        ;;
      5)
        CLIENT_DNS="8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844"
        ;;
      6)
        CLIENT_DNS="64.6.64.6,64.6.65.6,2620:74:1b::1:1,2620:74:1c::2:2"
        ;;
      7)
        CLIENT_DNS="9.9.9.9,149.112.112.112,2620:fe::fe,2620:fe::9"
        ;;
      8)
        CLIENT_DNS="80.67.169.40,80.67.169.12,2001:910:800::40,2001:910:800::12"
        ;;
      9)
        read -rp "Custom DNS:" CLIENT_DNS
        if [ -z "${CLIENT_DNS}" ]; then
          CLIENT_DNS="8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844"
        fi
        ;;
      esac
    fi
  }

  # use custom dns
  custom-dns

  # What would you like to name your first WireGuard peer?
  function client-name() {
    if [ -z "${CLIENT_NAME}" ]; then
      echo "Let's name the WireGuard Peer. Use one word only, no special characters, no spaces."
      read -rp "Client name:" -e -i "$(openssl rand -hex 50)" CLIENT_NAME
    fi
    if [ -z "${CLIENT_NAME}" ]; then
      CLIENT_NAME="$(openssl rand -hex 50)"
    fi
  }

  # Client Name
  client-name

  # Automatically remove wireguard peers after a period of time.
  function auto-remove-confg() {
    echo "Would you like to expire the peer after a certain period of time?"
    echo "  1) Every Year (Recommended)"
    echo "  2) No"
    until [[ "${AUTOMATIC_CONFIG_REMOVER}" =~ ^[1-2]$ ]]; do
      read -rp "Automatic config expire [1-2]:" -e -i 1 AUTOMATIC_CONFIG_REMOVER
    done
    case ${AUTOMATIC_CONFIG_REMOVER} in
    1)
      AUTOMATIC_WIREGUARD_EXPIRATION=true
      ;;
    2)
      AUTOMATIC_WIREGUARD_EXPIRATION=false
      ;;
    esac
  }

  # Automatic Remove Config
  auto-remove-confg

  # Lets check the kernel version and check if headers are required
  function install-kernel-headers() {
    ALLOWED_KERNEL_VERSION="5.6"
    if (($(echo "${CURRENT_KERNEL_VERSION} <= ${ALLOWED_KERNEL_VERSION}" | bc -l))); then
      if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
        apt-get update
        apt-get install linux-headers-"$(uname -r)" -y
      elif [ "${CURRENT_DISTRO}" == "raspbian" ]; then
        apt-get update
        apt-get install raspberrypi-kernel-headers -y
      elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
        pacman -Syu --noconfirm --needed linux-headers
      elif [ "${CURRENT_DISTRO}" == "fedora" ]; then
        dnf update -y
        dnf install kernel-headers-"$(uname -r)" kernel-devel-"$(uname -r)" -y
      elif { [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
        yum update -y
        yum install kernel-headers-"$(uname -r)" kernel-devel-"$(uname -r)" -y
      fi
    else
      echo "Correct: You do not need kernel headers." >>/dev/null
    fi
  }

  # Kernel Version
  install-kernel-headers

  # Install WireGuard Server
  function install-wireguard-server() {
    if [ ! -x "$(command -v wg)" ]; then
      if [ "${CURRENT_DISTRO}" == "ubuntu" ] && [ "${CURRENT_DISTRO_VERSION%.*}" -ge 21 ]; then
        apt-get update
        apt-get install wireguard -y
      elif [ "${CURRENT_DISTRO}" == "ubuntu" ] && [ "${CURRENT_DISTRO_VERSION%.*}" -le 20 ]; then
        apt-get update
        apt-get install software-properties-common -y
        add-apt-repository ppa:wireguard/wireguard -y
        apt-get update
        apt-get install wireguard -y
      elif { [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
        apt-get update
        apt-get install wireguard -y
      elif { [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "kali" ]; }; then
        apt-get update
        if { [ "${CURRENT_DISTRO}" == "debian" ] && [ "${CURRENT_DISTRO_VERSION%.*}" -le 11 ]; }; then
          if [ ! -f "/etc/apt/sources.list.d/backports.list" ]; then
            echo "deb http://deb.debian.org/debian buster-backports main" >>/etc/apt/sources.list.d/backports.list
            apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138
            apt-get update
          fi
        fi
        apt-get install wireguard -y
      elif [ "${CURRENT_DISTRO}" == "raspbian" ]; then
        apt-get update
        if [ ! -f "/etc/apt/sources.list.d/backports.list" ]; then
          echo "deb http://deb.debian.org/debian buster-backports main" >>/etc/apt/sources.list.d/backports.list
          apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138
          apt-get update
        fi
        apt-get install wireguard -y
      elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
        pacman -Syu --noconfirm --needed wireguard-tools
      elif [ "${CURRENT_DISTRO}" = "fedora" ] && [ "${CURRENT_DISTRO_VERSION%.*}" -ge 32 ]; then
        dnf update -y
        dnf install wireguard-tools -y
      elif [ "${CURRENT_DISTRO}" = "fedora" ] && [ "${CURRENT_DISTRO_VERSION%.*}" -le 31 ]; then
        dnf update -y
        dnf copr enable jdoss/wireguard -y
        dnf install wireguard-dkms wireguard-tools -y
      elif [ "${CURRENT_DISTRO}" == "centos" ] && [ "${CURRENT_DISTRO_VERSION%.*}" -ge 8 ]; then
        yum update -y
        yum install kmod-wireguard wireguard-tools -y
      elif [ "${CURRENT_DISTRO}" == "centos" ] && [ "${CURRENT_DISTRO_VERSION%.*}" -le 7 ]; then
        yum update -y
        yum install yum-plugin-elrepo -y
        yum install kmod-wireguard wireguard-tools -y
      elif [ "${CURRENT_DISTRO}" == "rhel" ] && [ "${CURRENT_DISTRO_VERSION%.*}" == 8 ]; then
        yum update -y
        yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
        yum update -y
        yum install kmod-wireguard wireguard-tools -y
      elif [ "${CURRENT_DISTRO}" == "rhel" ] && [ "${CURRENT_DISTRO_VERSION%.*}" == 7 ]; then
        yum update -y
        yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
        yum install kmod-wireguard wireguard-tools -y
      elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
        apk update
        apk add wireguard-tools
      elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
        pkg update
        pkg install wireguard
      elif { [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
        yum update -y
        yum install kmod-wireguard wireguard-tools -y
      fi
    fi
  }

  # Install WireGuard Server
  install-wireguard-server

  # Function to install Unbound
  function install-unbound() {
    if [ "${INSTALL_UNBOUND}" == true ]; then
      if { [ ! -x "$(command -v unbound)" ] || [ ! -x "$(command -v resolvconf)" ]; }; then
        if { [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
          apt-get install unbound resolvconf -y
          if [ "${CURRENT_DISTRO}" == "ubuntu" ]; then
            if pgrep systemd-journal; then
              systemctl stop systemd-resolved
              systemctl disable systemd-resolved
            else
              service systemd-resolved stop
              service systemd-resolved disable
            fi
          fi
        elif { [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
          yum install unbound -y
        elif [ "${CURRENT_DISTRO}" == "fedora" ]; then
          dnf install unbound resolvconf -y
        elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
          pacman -Syu --noconfirm unbound resolvconf
        elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
          apk add unbound resolvconf
        elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
          pkg install unbound resolvconf
        fi
      fi
      unbound-anchor -a ${UNBOUND_ANCHOR}
      curl "${UNBOUND_ROOT_SERVER_CONFIG_URL}" --create-dirs -o ${UNBOUND_ROOT_HINTS}
      NPROC=$(nproc)
      echo "server:
    num-threads: ${NPROC}
    verbosity: 1
    root-hints: ${UNBOUND_ROOT_HINTS}
    auto-trust-anchor-file: ${UNBOUND_ANCHOR}
    interface: 0.0.0.0
    interface: ::0
    max-udp-size: 3072
    access-control: 0.0.0.0/0                 refuse
    access-control: ::0                       refuse
    access-control: ${PRIVATE_SUBNET_V4}                allow
    access-control: ${PRIVATE_SUBNET_V6}           allow
    access-control: 127.0.0.1                 allow
    access-control: ::1                       allow
    private-address: ${PRIVATE_SUBNET_V4}
    private-address: ${PRIVATE_SUBNET_V6}
    do-tcp: no
    hide-identity: yes
    hide-version: yes
    harden-glue: yes
    harden-dnssec-stripped: yes
    harden-referral-path: yes
    unwanted-reply-threshold: 10000000
    cache-min-ttl: 1800
    cache-max-ttl: 14400
    prefetch: yes
    qname-minimisation: yes
    prefetch-key: yes" >${UNBOUND_CONFIG}
      if [ -f "${RESOLV_CONFIG_OLD}" ]; then
        rm -f ${RESOLV_CONFIG_OLD}
      fi
      if [ -f "${RESOLV_CONFIG}" ]; then
        chattr -i ${RESOLV_CONFIG}
        mv ${RESOLV_CONFIG} ${RESOLV_CONFIG_OLD}
      fi
      echo "nameserver 127.0.0.1" >>${RESOLV_CONFIG}
      echo "nameserver ::1" >>${RESOLV_CONFIG}
      chattr +i ${RESOLV_CONFIG}
      echo "Unbound: true" >>${UNBOUND_MANAGER}
      if [ "${INSTALL_BLOCK_LIST}" == true ]; then
        echo "include: ${UNBOUND_CONFIG_HOST}" >>${UNBOUND_CONFIG}
        curl "${UNBOUND_CONFIG_HOST_URL}" | awk '$1' | awk '{print "local-zone: \""$1"\" always_refuse"}' >${UNBOUND_CONFIG_HOST}
      fi
      # restart unbound
      if pgrep systemd-journal; then
        systemctl reenable unbound
        systemctl restart unbound
      else
        service unbound enable
        service unbound restart
      fi
      CLIENT_DNS="${GATEWAY_ADDRESS_V4},${GATEWAY_ADDRESS_V6}"
    fi
  }

  # Running Install Unbound
  install-unbound

  # WireGuard Set Config
  function wireguard-setconf() {
    SERVER_PRIVKEY=$(wg genkey)
    SERVER_PUBKEY=$(echo "${SERVER_PRIVKEY}" | wg pubkey)
    CLIENT_PRIVKEY=$(wg genkey)
    CLIENT_PUBKEY=$(echo "${CLIENT_PRIVKEY}" | wg pubkey)
    CLIENT_ADDRESS_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut -d'.' -f1-3).2
    CLIENT_ADDRESS_V6="${PRIVATE_SUBNET_V6::-3}2"
    PRESHARED_KEY=$(wg genpsk)
    PEER_PORT=$(shuf -i1024-65535 -n1)
    mkdir -p ${WIREGUARD_CLIENT_PATH}
    if [ "${INSTALL_UNBOUND}" == true ]; then
      IPTABLES_POSTUP="iptables -A FORWARD -i ${WIREGUARD_PUB_NIC} -j ACCEPT; iptables -t nat -A POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE; ip6tables -A FORWARD -i ${WIREGUARD_PUB_NIC} -j ACCEPT; ip6tables -t nat -A POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE; iptables -A INPUT -s ${PRIVATE_SUBNET_V4} -p udp -m udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT; ip6tables -A INPUT -s ${PRIVATE_SUBNET_V6} -p udp -m udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT"
      IPTABLES_POSTDOWN="iptables -D FORWARD -i ${WIREGUARD_PUB_NIC} -j ACCEPT; iptables -t nat -D POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE; ip6tables -D FORWARD -i ${WIREGUARD_PUB_NIC} -j ACCEPT; ip6tables -t nat -D POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE; iptables -D INPUT -s ${PRIVATE_SUBNET_V4} -p udp -m udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT; ip6tables -D INPUT -s ${PRIVATE_SUBNET_V6} -p udp -m udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT"
    else
      IPTABLES_POSTUP="iptables -A FORWARD -i ${WIREGUARD_PUB_NIC} -j ACCEPT; iptables -t nat -A POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE; ip6tables -A FORWARD -i ${WIREGUARD_PUB_NIC} -j ACCEPT; ip6tables -t nat -A POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE"
      IPTABLES_POSTDOWN="iptables -D FORWARD -i ${WIREGUARD_PUB_NIC} -j ACCEPT; iptables -t nat -D POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE; ip6tables -D FORWARD -i ${WIREGUARD_PUB_NIC} -j ACCEPT; ip6tables -t nat -D POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE"
    fi
    # Set WireGuard settings for this host and first peer.
    echo "# ${PRIVATE_SUBNET_V4} ${PRIVATE_SUBNET_V6} ${SERVER_HOST}:${SERVER_PORT} ${SERVER_PUBKEY} ${CLIENT_DNS} ${MTU_CHOICE} ${NAT_CHOICE} ${CLIENT_ALLOWED_IP}
[Interface]
Address = ${GATEWAY_ADDRESS_V4}/${PRIVATE_SUBNET_MASK_V4},${GATEWAY_ADDRESS_V6}/${PRIVATE_SUBNET_MASK_V6}
DNS = ${CLIENT_DNS}
ListenPort = ${SERVER_PORT}
MTU = ${MTU_CHOICE}
PrivateKey = ${SERVER_PRIVKEY}
PostUp = ${IPTABLES_POSTUP}
PostDown = ${IPTABLES_POSTDOWN}
SaveConfig = false
# ${CLIENT_NAME} start
[Peer]
PublicKey = ${CLIENT_PUBKEY}
PresharedKey = ${PRESHARED_KEY}
AllowedIPs = ${CLIENT_ADDRESS_V4}/32,${CLIENT_ADDRESS_V6}/128
# ${CLIENT_NAME} end" >>${WIREGUARD_CONFIG}

    echo "# ${WIREGUARD_WEBSITE_URL}
[Interface]
Address = ${CLIENT_ADDRESS_V4}/${PRIVATE_SUBNET_MASK_V4},${CLIENT_ADDRESS_V6}/${PRIVATE_SUBNET_MASK_V6}
DNS = ${CLIENT_DNS}
ListenPort = ${PEER_PORT}
MTU = ${MTU_CHOICE}
PrivateKey = ${CLIENT_PRIVKEY}
[Peer]
AllowedIPs = ${CLIENT_ALLOWED_IP}
Endpoint = ${SERVER_HOST}:${SERVER_PORT}
PersistentKeepalive = ${NAT_CHOICE}
PresharedKey = ${PRESHARED_KEY}
PublicKey = ${SERVER_PUBKEY}" >>${WIREGUARD_CLIENT_PATH}/"${CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
    # If automaic wireguard expiration is enabled than set the expiration date.
    if [ ${AUTOMATIC_WIREGUARD_EXPIRATION} == true ]; then
      crontab -l | {
        cat
        echo "$(date +%M) $(date +%H) $(date +%d) $(date +%m) * echo -e \"${CLIENT_NAME}\" | ${CURRENT_FILE_PATH} --remove"
      } | crontab -
      if pgrep systemd-journal; then
        systemctl enable cron
        systemctl start cron
      else
        service cron enable
        service cron start
      fi
    fi
    # Service Restart
    if pgrep systemd-journal; then
      systemctl reenable wg-quick@${WIREGUARD_PUB_NIC}
      systemctl restart wg-quick@${WIREGUARD_PUB_NIC}
    else
      service wg-quick@${WIREGUARD_PUB_NIC} enable
      service wg-quick@${WIREGUARD_PUB_NIC} restart
    fi
    # Generate QR Code
    qrencode -t ansiutf8 -r ${WIREGUARD_CLIENT_PATH}/"${CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
    echo "Client Config --> ${WIREGUARD_CLIENT_PATH}/${CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf"
  }

  # Setting Up WireGuard Config
  wireguard-setconf

# After WireGuard Install
else

  # Already installed what next?
  function wireguard-next-questions-interface() {
    echo "What do you want to do?"
    echo "   1) Show WireGuard"
    echo "   2) Start WireGuard"
    echo "   3) Stop WireGuard"
    echo "   4) Restart WireGuard"
    echo "   5) Add WireGuard Peer (client)"
    echo "   6) Remove WireGuard Peer (client)"
    echo "   7) Reinstall WireGuard"
    echo "   8) Uninstall WireGuard"
    echo "   9) Update this script"
    echo "   10) Backup WireGuard"
    echo "   11) Restore WireGuard"
    echo "   12) Update Interface IP"
    echo "   13) Update Interface Port"
    echo "   14) Purge WireGuard Peers"
    echo "   15) Generate QR Code"
    until [[ "${WIREGUARD_OPTIONS}" =~ ^[0-9]+$ ]] && [ "${WIREGUARD_OPTIONS}" -ge 1 ] && [ "${WIREGUARD_OPTIONS}" -le 15 ]; do
      read -rp "Select an Option [1-15]:" -e -i 0 WIREGUARD_OPTIONS
    done
    case ${WIREGUARD_OPTIONS} in
    1) # WG Show
      wg show ${WIREGUARD_PUB_NIC}
      ;;
    2) # Enable & Start WireGuard
      if pgrep systemd-journal; then
        systemctl enable wg-quick@${WIREGUARD_PUB_NIC}
        systemctl start wg-quick@${WIREGUARD_PUB_NIC}
      else
        service wg-quick@${WIREGUARD_PUB_NIC} enable
        service wg-quick@${WIREGUARD_PUB_NIC} start
      fi
      ;;
    3) # Disable & Stop WireGuard
      if pgrep systemd-journal; then
        systemctl disable wg-quick@${WIREGUARD_PUB_NIC}
        systemctl stop wg-quick@${WIREGUARD_PUB_NIC}
      else
        service wg-quick@${WIREGUARD_PUB_NIC} disable
        service wg-quick@${WIREGUARD_PUB_NIC} stop
      fi
      ;;
    4) # Restart WireGuard
      if pgrep systemd-journal; then
        systemctl restart wg-quick@${WIREGUARD_PUB_NIC}
      else
        service wg-quick@${WIREGUARD_PUB_NIC} restart
      fi
      ;;
    5) # WireGuard add Peer
      # If the client name is set then assign it to the NEW_CLIENT_NAME
      if [[ "${CLIENT_USER}" != "" ]]; then
	      NEW_CLIENT_NAME=${CLIENT_USER}
      fi
      if [ -z "${NEW_CLIENT_NAME}" ]; then
        echo "Let's name the WireGuard Peer. Use one word only, no special characters, no spaces."
        read -rp "New client peer:" -e -i "$(openssl rand -hex 50)" NEW_CLIENT_NAME
      fi
      if [ -z "${NEW_CLIENT_NAME}" ]; then
        NEW_CLIENT_NAME="$(openssl rand -hex 50)"
      fi
      # Check if user exists
      if [[ "$(egrep ${NEW_CLIENT_NAME} ${WIREGUARD_CONFIG})" != "" ]]; then

	      echo "User already exists."
	      exit 1
      fi

      if [[ "${CUSTOM_EXPIRE}" != "" ]]; then

	# Custom Expiration date for the user
        read -p "Do you want to set a custom expiration date for the user? [y|N]" set_expire
        if [[ "${set_expire}" =~ ^[Yy]$ ]]; then

        function custom_exp() {

                read -p "Enter the month (MM) (e.g. 01 for January ): " the_month
                read -p "Enter the day (DD) (e.g. 05 or 25): " the_day
                read -p "Enter the year (YYYY) (e.g. 2022): " the_year

                # Format the date YYYYMMDD
                REMOVE_DATE="${the_year}${the_month}${the_day}"

                # Current date
                CURR_DATE=$(date +"%Y%m%d")
        
                # Check if date is current or in the future
                if [[ ${REMOVE_DATE} -le ${CURR_DATE} ]]; then
        
                        echo "Date must be greater than or equal to today's date...please wait"
                        read -p "Hit ENTER to continue"
                        custom_exp
        
                fi
        
                # Check if the entered date is valid
                # Catches leap year invalid dates too
                date -d "${REMOVE_DATE}" > /dev/null 2>&1
        
                # If the date is valid, it will return 0
		if [[ $? != 0 ]]; then
        
                        echo "Invalid Date provided."
                        read -p "Press ENTER to continue"
                        custom_exp
        
                fi
        
                # Current Hour and minute
                THE_HOUR_MIN=$(date '+%H%M' -d '1 hour ago')
        
                # Removal Date
                THE_REMOVE_DATE="${REMOVE_DATE}${THE_HOUR_MIN}"

        }

        custom_exp

        fi
      fi 
      # See if there are any gaps in IPs.  Removing a user leaves an available IP.
      # https://stackoverflow.com/questions/38491676/how-can-i-find-the-missing-integers-in-a-unique-and-sequential-list-one-per-lin
      UNUSED_IPS=$(egrep -o "^AllowedIPs = $(head -n1 ${WIREGUARD_CONFIG} | awk ' { print $2 } ' | cut -d\. -f1,2,3)\.[0-9]{1,3}" ${WIREGUARD_CONFIG} | awk ' { print $3 } ' | cut -d\. -f4 | sort -n | awk '{for(i=p+1; i<$1; i++) print i} {p=$1}' | egrep -v '^1$')
      # If there is an unused IP. Get the first one (especially, if there are more than one).
      if [[ "${UNUSED_IPS}" != "" ]]; then
        LASTIPV4=$(echo "${UNUSED_IPS}" | head -n 1)
        LASTIPV6=$(echo "${UNUSED_IPS}" | head -n 1)
      else
        # Else use the standard method
        LASTIPV4=$(grep "/32" ${WIREGUARD_CONFIG} | awk '{print $3}' | cut -d "/" -f 1 | cut -d "." -f 4 | sort | tail -n1)
        LASTIPV6=$(grep "/128" ${WIREGUARD_CONFIG} | awk '{print $3}' | cut -d ":" -f 5 | cut -d "/" -f 1 | sort | tail -n1)

      fi
      #LASTIPV4=$(grep "/32" ${WIREGUARD_CONFIG} | tail -n1 | awk '{print $3}' | cut -d "/" -f 1 | cut -d "." -f 4)
      #LASTIPV6=$(grep "/128" ${WIREGUARD_CONFIG} | tail -n1 | awk '{print $3}' | cut -d ":" -f 5 | cut -d "/" -f 1)
      if { [ -z "${LASTIPV4}" ] && [ -z "${LASTIPV6}" ]; }; then
        LASTIPV4="1"
        LASTIPV6="1"
      fi
      if { [ "${LASTIPV4}" -ge 255 ] && [ "${LASTIPV6}" -ge 255 ]; }; then
        CURRENT_IPV4_RANGE=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $2}')
        CURRENT_IPV6_RANGE=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $3}')
        IPV4_BEFORE_BACKSLASH=$(echo "${CURRENT_IPV4_RANGE}" | cut -d "/" -f 1 | cut -d "." -f 4)
        IPV6_BEFORE_BACKSLASH=$(echo "${CURRENT_IPV6_RANGE}" | cut -d "/" -f 1 | cut -d ":" -f 5)
        IPV4_AFTER_FIRST=$(echo "${CURRENT_IPV4_RANGE}" | cut -d "/" -f 1 | cut -d "." -f 2)
        IPV6_AFTER_FIRST=$(echo "${CURRENT_IPV6_RANGE}" | cut -d "/" -f 1 | cut -d ":" -f 2)
        SECOND_IPV4_IN_RANGE=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $2}' | cut -d "/" -f 1 | cut -d "." -f 2)
        SECOND_IPV6_IN_RANGE=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $3}' | cut -d "/" -f 1 | cut -d ":" -f 2)
        THIRD_IPV4_IN_RANGE=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $2}' | cut -d "/" -f 1 | cut -d "." -f 3)
        THIRD_IPV6_IN_RANGE=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $3}' | cut -d "/" -f 1 | cut -d ":" -f 3)
        NEXT_IPV4_RANGE=$((THIRD_IPV4_IN_RANGE + 1))
        NEXT_IPV6_RANGE=$((THIRD_IPV6_IN_RANGE + 1))
        CURRENT_IPV4_RANGE_CIDR=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $2}' | cut -d "/" -f 2)
        CURRENT_IPV6_RANGE_CIDR=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $3}' | cut -d "/" -f 2)
        FINAL_IPV4_RANGE=$(echo "${CURRENT_IPV4_RANGE}" | cut -d "/" -f 1 | cut -d "." -f 1,2)".${NEXT_IPV4_RANGE}.${IPV4_BEFORE_BACKSLASH}/${CURRENT_IPV4_RANGE_CIDR}"
        FINAL_IPV6_RANGE=$(echo "${CURRENT_IPV6_RANGE}" | cut -d "/" -f 1 | cut -d ":" -f 1,2)":${NEXT_IPV6_RANGE}::${IPV6_BEFORE_BACKSLASH}/${CURRENT_IPV6_RANGE_CIDR}"
        if { [ "${THIRD_IPV4_IN_RANGE}" -ge 255 ] && [ "${THIRD_IPV6_IN_RANGE}" -ge 255 ]; }; then
          if { [ "${SECOND_IPV4_IN_RANGE}" -ge 255 ] && [ "${SECOND_IPV6_IN_RANGE}" -ge 255 ] && [ "${THIRD_IPV4_IN_RANGE}" -ge 255 ] && [ "${THIRD_IPV6_IN_RANGE}" -ge 255 ] && [ "${LASTIPV4}" -ge 255 ] && [ "${LASTIPV6}" -ge 255 ]; }; then
            echo "Error: You are unable to add any more peers."
            exit
          fi
          NEXT_IPV4_RANGE=$((SECOND_IPV4_IN_RANGE + 1))
          NEXT_IPV6_RANGE=$((SECOND_IPV6_IN_RANGE + 1))
          FINAL_IPV4_RANGE=$(echo "${CURRENT_IPV4_RANGE}" | cut -d "/" -f 1 | cut -d "." -f 1)".${NEXT_IPV4_RANGE}.${IPV4_AFTER_FIRST}.${IPV4_BEFORE_BACKSLASH}/${CURRENT_IPV4_RANGE_CIDR}"
          FINAL_IPV6_RANGE=$(echo "${CURRENT_IPV6_RANGE}" | cut -d "/" -f 1 | cut -d ":" -f 1)":${NEXT_IPV6_RANGE}:${IPV6_AFTER_FIRST}::${IPV6_BEFORE_BACKSLASH}/${CURRENT_IPV6_RANGE_CIDR}"
        fi
        sed -i "1s|${CURRENT_IPV4_RANGE}|${FINAL_IPV4_RANGE}|" ${WIREGUARD_CONFIG}
        sed -i "1s|${CURRENT_IPV6_RANGE}|${FINAL_IPV6_RANGE}|" ${WIREGUARD_CONFIG}
        LASTIPV4="2"
        LASTIPV6="2"
      fi
      CLIENT_PRIVKEY=$(wg genkey)
      CLIENT_PUBKEY=$(echo "${CLIENT_PRIVKEY}" | wg pubkey)
      PRESHARED_KEY=$(wg genpsk)
      PEER_PORT=$(shuf -i1024-65535 -n1)
      PRIVATE_SUBNET_V4=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $2}')
      PRIVATE_SUBNET_MASK_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut -d "/" -f 2)
      PRIVATE_SUBNET_V6=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $3}')
      PRIVATE_SUBNET_MASK_V6=$(echo "${PRIVATE_SUBNET_V6}" | cut -d "/" -f 2)
      SERVER_HOST=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $4}')
      SERVER_PUBKEY=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $5}')
      CLIENT_DNS=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $6}')
      MTU_CHOICE=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $7}')
      NAT_CHOICE=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $8}')
      CLIENT_ALLOWED_IP=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $9}')
      # Check if unused IPs.  Prevents assigning duplicate IPs
      if [[ "${UNUSED_IPS}" == "" ]]; then
        CLIENT_ADDRESS_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut -d'.' -f1-3).$((LASTIPV4 + 1))
        CLIENT_ADDRESS_V6="${PRIVATE_SUBNET_V6::-3}$((LASTIPV6 + 1))"
	# Remove the leading zero in octets such as 01, 03, etc. http://drewgraybeal.blogspot.com/2015/07/remove-leading-zeros-from-ip-address.html
	CLIENT_ADDRESS_V4=$(echo ${CLIENT_ADDRESS_V4} | sed -r 's/^0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)$/\1.\2.\3.\4/')
	CLIENT_ADDRESS_V6=$(echo ${CLIENT_ADDRESS_V6} | sed -r 's/^0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)$/\1.\2.\3.\4/')
	LASTIPV6=$(echo ${LASTIPV4} | sed -r 's/^0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)$/\1.\2.\3.\4/')
      else
        CLIENT_ADDRESS_V4="${PRIVATE_SUBNET_V4::-3}${LASTIPV4}"
        CLIENT_ADDRESS_V6="${PRIVATE_SUBNET_V6::-3}${LASTIPV6}"
	# Remove the leading zero in octets such as 01, 03, etc.
	CLIENT_ADDRESS_V4=$(echo ${CLIENT_ADDRESS_V4} | sed -r 's/^0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)$/\1.\2.\3.\4/')
	CLIENT_ADDRESS_V6=$(echo ${CLIENT_ADDRESS_V6} | sed -r 's/^0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)$/\1.\2.\3.\4/')
      fi
      # Check if THE_REMOVE_DATE 
      if [[ "${THE_REMOVE_DATE}" == "" ]]; then

           TODO="${NEW_CLIENT_NAME} start"

      else

           TODO="${NEW_CLIENT_NAME} start ${THE_REMOVE_DATE}"

      fi
      echo "# ${TODO}
[Peer]
PublicKey = ${CLIENT_PUBKEY}
PresharedKey = ${PRESHARED_KEY}
AllowedIPs = ${CLIENT_ADDRESS_V4}/32,${CLIENT_ADDRESS_V6}/128
# ${NEW_CLIENT_NAME} end" >${WIREGUARD_ADD_PEER_CONFIG}
      wg addconf ${WIREGUARD_PUB_NIC} ${WIREGUARD_ADD_PEER_CONFIG}
      cat ${WIREGUARD_ADD_PEER_CONFIG} >>${WIREGUARD_CONFIG}
      rm -f ${WIREGUARD_ADD_PEER_CONFIG}
      echo "# ${WIREGUARD_WEBSITE_URL}
[Interface]
Address = ${CLIENT_ADDRESS_V4}/${PRIVATE_SUBNET_MASK_V4},${CLIENT_ADDRESS_V6}/${PRIVATE_SUBNET_MASK_V6}
DNS = ${CLIENT_DNS}
ListenPort = ${PEER_PORT}
MTU = ${MTU_CHOICE}
PrivateKey = ${CLIENT_PRIVKEY}
[Peer]
AllowedIPs = ${CLIENT_ALLOWED_IP}
Endpoint = ${SERVER_HOST}${SERVER_PORT}
PersistentKeepalive = ${NAT_CHOICE}
PresharedKey = ${PRESHARED_KEY}
PublicKey = ${SERVER_PUBKEY}" >>${WIREGUARD_CLIENT_PATH}/"${NEW_CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
      # If the ssh configurationf diectory doesn't exist, then create it.
      if [[ ! -d "/home/${NEW_CLIENT_NAME}/sshwireguardConf/" ]]; then
        mkdir "/home/${NEW_CLIENT_NAME}/sshwireguardConf/"
      fi
      # Copy the VPN configuration to user's home directory sshwireguardConf/ folder
      cp ${WIREGUARD_CLIENT_PATH}/"${NEW_CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf /home/${NEW_CLIENT_NAME}/sshwireguardConf/sshwireguard.conf
echo "
############################################
# These settings are generated server-side #
# and should not be manually changed.      #
# ##########################################
# Username to authenticate.
username: duane
# Remote SSH server.
hostname: ${SERVER_HOST}
# SSH port number
hostport: 22" > /home/${NEW_CLIENT_NAME}/sshwireguardConf/config.yaml
      wg addconf ${WIREGUARD_PUB_NIC} <(wg-quick strip ${WIREGUARD_PUB_NIC})
      #qrencode -t ansiutf8 -r ${WIREGUARD_CLIENT_PATH}/"${NEW_CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
      echo "Client config --> ${WIREGUARD_CLIENT_PATH}/${NEW_CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf"
      ;;
    6) # Remove WireGuard Peer
      echo "Which WireGuard peer would you like to remove?"
      grep start ${WIREGUARD_CONFIG} | awk '{print $2}'
      if [[ "${CLIENT_USER}" == "" ]]; then
        read -rp "Peer's name:" REMOVECLIENT
      else
	REMOVECLIENT=${CLIENT_USER}
      fi
      if [[ "$(egrep "start [0-9]{12}" ${WIREGUARD_CONFIG})" != "" ]]; then

	CLIENTKEY=$(sed -n "/\# ${REMOVECLIENT} start [0-9]\{12\}/,/\# ${REMOVECLIENT} end/p" ${WIREGUARD_CONFIG} | grep PublicKey | awk '{print $3}')
      else
        CLIENTKEY=$(sed -n "/\# ${REMOVECLIENT} start/,/\# ${REMOVECLIENT} end/p" ${WIREGUARD_CONFIG} | grep PublicKey | awk '{print $3}')
      fi
      wg set ${WIREGUARD_PUB_NIC} peer "${CLIENTKEY}" remove
      sed -i "/\# ${REMOVECLIENT} start/,/\# ${REMOVECLIENT} end/d" ${WIREGUARD_CONFIG}
      if [ -f "${WIREGUARD_CLIENT_PATH}/${REMOVECLIENT}-${WIREGUARD_PUB_NIC}.conf" ]; then
        rm -f ${WIREGUARD_CLIENT_PATH}/"${REMOVECLIENT}"-${WIREGUARD_PUB_NIC}.conf
      fi
      wg addconf ${WIREGUARD_PUB_NIC} <(wg-quick strip ${WIREGUARD_PUB_NIC})
      crontab -l | grep -v "${REMOVECLIENT}" | crontab -
      ;;
    7) # Reinstall WireGuard
      if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
        dpkg-reconfigure wireguard-dkms
        modprobe wireguard
        systemctl reenable wg-quick@${WIREGUARD_PUB_NIC}
        systemctl restart wg-quick@${WIREGUARD_PUB_NIC}
      elif { [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
        yum reinstall wireguard-tools -y
        service wg-quick@${WIREGUARD_PUB_NIC} restart
      elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
        pacman -S --noconfirm wireguard-tools
        systemctl reenable wg-quick@${WIREGUARD_PUB_NIC}
        systemctl restart wg-quick@${WIREGUARD_PUB_NIC}
      elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
        apk fix wireguard-tools
      elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
        pkg check wireguard
      fi
      ;;
    8) # Uninstall WireGuard and purging files
      if pgrep systemd-journal; then
        systemctl disable wg-quick@${WIREGUARD_PUB_NIC}
        systemctl stop wg-quick@${WIREGUARD_PUB_NIC}
        wg-quick down ${WIREGUARD_PUB_NIC}
      else
        service wg-quick@${WIREGUARD_PUB_NIC} disable
        service wg-quick@${WIREGUARD_PUB_NIC} stop
        wg-quick down ${WIREGUARD_PUB_NIC}
      fi
      # Removing Wireguard Files
      if [ -d "${WIREGUARD_PATH}" ]; then
        rm -rf ${WIREGUARD_PATH}
      fi
      if [ -d "${WIREGUARD_CLIENT_PATH}" ]; then
        rm -rf ${WIREGUARD_CLIENT_PATH}
      fi
      if [ -f "${WIREGUARD_CONFIG}" ]; then
        rm -f ${WIREGUARD_CONFIG}
      fi
      if [ -f "${WIREGUARD_IP_FORWARDING_CONFIG}" ]; then
        rm -f ${WIREGUARD_IP_FORWARDING_CONFIG}
      fi
      if { [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
        yum remove wireguard qrencode haveged -y
      elif { [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "kali" ]; }; then
        apt-get remove --purge wireguard qrencode -y
        if [ -f "/etc/apt/sources.list.d/backports.list" ]; then
          rm -f /etc/apt/sources.list.d/backports.list
        fi
      elif { [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
        apt-get remove --purge wireguard qrencode haveged -y
      elif [ "${CURRENT_DISTRO}" == "ubuntu" ]; then
        apt-get remove --purge wireguard qrencode haveged -y
        if pgrep systemd-journal; then
          systemctl reenable systemd-resolved
          systemctl restart systemd-resolved
        else
          service systemd-resolved enable
          service systemd-resolved restart
        fi
      elif [ "${CURRENT_DISTRO}" == "raspbian" ]; then
        apt-key del 04EE7237B7D453EC
        apt-get remove --purge wireguard qrencode haveged -y
        if [ -f "/etc/apt/sources.list.d/backports.list" ]; then
          rm -f /etc/apt/sources.list.d/backports.list
        fi
      elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
        pacman -Rs --noconfirm wireguard-tools qrencode haveged
      elif [ "${CURRENT_DISTRO}" == "fedora" ]; then
        dnf remove wireguard qrencode haveged -y
        if [ -f "/etc/yum.repos.d/wireguard.repo" ]; then
          rm -f /etc/yum.repos.d/wireguard.repo
        fi
      elif [ "${CURRENT_DISTRO}" == "rhel" ]; then
        yum remove wireguard qrencode haveged -y
        if [ -f "/etc/yum.repos.d/wireguard.repo" ]; then
          rm -f /etc/yum.repos.d/wireguard.repo
        fi
      elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
        apk del wireguard-tools libqrencode haveged
      elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
        pkg delete wireguard libqrencode
      fi
      # Delete WireGuard backup
      if [ -f "${WIREGUARD_CONFIG_BACKUP}" ]; then
        rm -f ${WIREGUARD_CONFIG_BACKUP}
        if [ -f "${WIREGUARD_BACKUP_PASSWORD_PATH}" ]; then
          rm -f "${WIREGUARD_BACKUP_PASSWORD_PATH}"
        fi
      fi
      # Uninstall unbound
      if [ -x "$(command -v unbound)" ]; then
        if pgrep systemd-journal; then
          systemctl disable unbound
          systemctl stop unbound
        else
          service unbound disable
          service unbound stop
        fi
        if [ -f "${RESOLV_CONFIG_OLD}" ]; then
          chattr -i ${RESOLV_CONFIG}
          rm -f ${RESOLV_CONFIG}
          mv ${RESOLV_CONFIG_OLD} ${RESOLV_CONFIG}
          chattr +i ${RESOLV_CONFIG}
        fi
        if { [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
          yum remove unbound -y
        elif { [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
          apt-get remove --purge unbound -y
        elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
          pacman -Rs --noconfirm unbound
        elif [ "${CURRENT_DISTRO}" == "fedora" ]; then
          dnf remove unbound -y
        elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
          apk del unbound
        elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
          pkg delete unbound
        fi
        if [ -d "${UNBOUND_ROOT}" ]; then
          rm -rf ${UNBOUND_ROOT}
        fi
        if [ -f "${UNBOUND_ANCHOR}" ]; then
          rm -f ${UNBOUND_ANCHOR}
        fi
        if [ -f "${UNBOUND_ROOT_HINTS}" ]; then
          rm -f ${UNBOUND_ROOT_HINTS}
        fi
        if [ -f "${UNBOUND_CONFIG}" ]; then
          rm -f ${UNBOUND_CONFIG}
        fi
      fi
      # If any cronjobs are identified, they should be removed.
      crontab -l | grep -v "${CURRENT_FILE_PATH}" | crontab -
      ;;
    9) # Update the script
      curl ${WIREGUARD_MANAGER_UPDATE} -o "${CURRENT_FILE_PATH}"
      chmod +x "${CURRENT_FILE_PATH}"
      # Update the unbound configs
      if [ -x "$(command -v unbound)" ]; then
        # Refresh the root hints
        if [ -f "${UNBOUND_ROOT_HINTS}" ]; then
          curl ${UNBOUND_ROOT_SERVER_CONFIG_URL} -o ${UNBOUND_ROOT_HINTS}
        fi
        # The block list should be updated.
        if [ -f "${UNBOUND_CONFIG_HOST}" ]; then
          curl "${UNBOUND_CONFIG_HOST_URL}" | awk '$1' | awk '{print "local-zone: \""$1"\" always_refuse"}' >${UNBOUND_CONFIG_HOST}
        fi
        # Once everything is completed, restart the service.
        if pgrep systemd-journal; then
          systemctl restart unbound
        else
          service unbound restart
        fi
      fi
      ;;
    10) # Backup WireGuard Config
      if [ -f "${WIREGUARD_CONFIG_BACKUP}" ]; then
        rm -f ${WIREGUARD_CONFIG_BACKUP}
      fi
      if [ -d "${WIREGUARD_PATH}" ]; then
        BACKUP_PASSWORD="$(openssl rand -hex 50)"
        echo "${BACKUP_PASSWORD}" >"${WIREGUARD_BACKUP_PASSWORD_PATH}"
        zip -P "${BACKUP_PASSWORD}" -rj ${WIREGUARD_CONFIG_BACKUP} ${WIREGUARD_CONFIG}
      fi
      ;;
    11) # Restore WireGuard Config
      if [ -d "${WIREGUARD_PATH}" ]; then
        rm -rf ${WIREGUARD_PATH}
      fi
      unzip ${WIREGUARD_CONFIG_BACKUP} -d ${WIREGUARD_PATH}
      # Restart WireGuard
      if pgrep systemd-journal; then
        systemctl enable wg-quick@${WIREGUARD_PUB_NIC}
        systemctl restart wg-quick@${WIREGUARD_PUB_NIC}
      else
        service wg-quick@${WIREGUARD_PUB_NIC} enable
        service wg-quick@${WIREGUARD_PUB_NIC} restart
      fi
      ;;
    12) # Change the IP address of your wireguard interface.
      OLD_SERVER_HOST=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $4}' | awk -F: '{print $1}')
      NEW_SERVER_HOST="$(curl -4 --connect-timeout 5 --tlsv1.3 -s 'https://api.ipengine.dev' | jq -r '.network.ip')"
      if [ -z "${NEW_SERVER_HOST}" ]; then
        NEW_SERVER_HOST="$(curl -4 --connect-timeout 5 --tlsv1.3 -s 'https://checkip.amazonaws.com')"
      fi
      sed -i "1s/${OLD_SERVER_HOST}/${NEW_SERVER_HOST}/" ${WIREGUARD_CONFIG}
      ;;
    13) # Change the wireguard interface's port number.
      OLD_SERVER_PORT=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $4}' | awk -F: '{print $2}')
      until [[ "${NEW_SERVER_PORT}" =~ ^[0-9]+$ ]] && [ "${NEW_SERVER_PORT}" -ge 1 ] && [ "${NEW_SERVER_PORT}" -le 65535 ]; do
        read -rp "Custom port [1-65535]: " -e -i 51820 NEW_SERVER_PORT
      done
      if [ "$(lsof -i UDP:"${NEW_SERVER_PORT}")" ]; then
        echo "Error: The port ${NEW_SERVER_PORT} is already used by a different application, please use a different port."
      fi
      sed -i "s/${OLD_SERVER_PORT}/${NEW_SERVER_PORT}/g" ${WIREGUARD_CONFIG}
      ;;
    14) # All wireguard peers should be removed from your interface
      COMPLETE_CLIENT_LIST=$(grep start ${WIREGUARD_CONFIG} | awk '{print $2}')
      for CLIENT_LIST_ARRAY in ${COMPLETE_CLIENT_LIST}; do
        USER_LIST[${ADD_CONTENT}]=${CLIENT_LIST_ARRAY}
        ADD_CONTENT=$(("${ADD_CONTENT}" + 1))
      done
      for CLIENT_NAME in "${USER_LIST[@]}"; do
        CLIENTKEY=$(sed -n "/\# ${CLIENT_NAME} start/,/\# ${CLIENT_NAME} end/p" ${WIREGUARD_CONFIG} | grep PublicKey | awk '{print $3}')
        wg set ${WIREGUARD_PUB_NIC} peer "${CLIENTKEY}" remove
        sed -i "/\# ${CLIENT_NAME} start/,/\# ${CLIENT_NAME} end/d" ${WIREGUARD_CONFIG}
        if [ -f "${WIREGUARD_CLIENT_PATH}/${CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf" ]; then
          rm -f ${WIREGUARD_CLIENT_PATH}/"${CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
        fi
        wg addconf ${WIREGUARD_PUB_NIC} <(wg-quick strip ${WIREGUARD_PUB_NIC})
      done
      ;;
    15) # Generate QR code.
      echo "Which WireGuard peer would you like to generate a QR code for?"
      grep start ${WIREGUARD_CONFIG} | awk '{print $2}'
      read -rp "Peer's name:" VIEW_CLIENT_INFO
      if [ -f "${WIREGUARD_CLIENT_PATH}/${VIEW_CLIENT_INFO}-${WIREGUARD_PUB_NIC}.conf" ]; then
        #qrencode -t ansiutf8 -r ${WIREGUARD_CLIENT_PATH}/"${VIEW_CLIENT_INFO}"-${WIREGUARD_PUB_NIC}.conf
        echo "Peer's config --> ${WIREGUARD_CLIENT_PATH}/${VIEW_CLIENT_INFO}-${WIREGUARD_PUB_NIC}.conf"
      fi
      ;;
    esac
  }

  # Running Questions Command
  wireguard-next-questions-interface

fi

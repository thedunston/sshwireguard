#!/bin/bash

# VPN SERVER
# ex. vpn_server="my.server.com"
vpn_server="myserver.com"

# ex. ping_ip="10.8.0.1"
ping_ip=""

# See if Mac OS
if_mac="$(uname -a |egrep '^Darwin' | awk ' { print $1 }')"

# Check if MacOS.  Brew is installed as non-root user.
# So that check is first and then the script is run
# with sudo
if [[ "${if_mac}" == "Darwin" ]]
then

	# Get UID
	the_uid=$(id -u)
	chk_brew=$(which brew)
	if [[ "${chk_brew}" != "" && ${the_uid} -ne 0 ]]
	then
		
		brew update

	elif [[ "${chk_brew}" != "" && ${the_uid} -eq 0 ]]
	then

			echo "########################################################################"
			echo "In order to update the available brew packages, please run "
			echo "client-nowire.sh as a non-root user."
			echo "########################################################################"

	else

		if [[ $the_uid -eq 0 ]]
		then

			echo "########################################################################"
			echo "Brew is not installed so it has to be installed first as a non-root user."
			echo "Rerun this script but not with sudo or as root."
			echo "Please NOTE the brew install may hang a bit, but it is installing."
			echo "########################################################################"
			echo ""
			exit 1

		fi
		echo "Installing Brew"
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

		echo ""
		echo "Installing Wireguard-tools"
		brew install wireguard-tools

		echo ""
		echo "########################################################################"
		echo ""
		echo "Now run the client-nowire.sh script with sudo"
		echo ""
		echo "########################################################################"
		echo ""
		exit 0
	fi

fi

# Check user is root
if [[ $(id -u) -ne 0 ]]
then

	echo "Script must be run as root."
	exit 1
fi

function bring_up_vpn(){

	# empty pass variable before enabling stty echo
	pass=""
	grep Interface ${tmpFile}
	
	if [[ $? -eq 0 ]]
	then
	
		if [[ "${if_mac}" == "Darwin" ]]
		then

			mv ${tmpFile} /usr/local/etc/wireguard/wgvpn.conf
		
		else
			mv ${tmpFile} /etc/wireguard/wgvpn.conf

		fi
		wg-quick up wgvpn
	
		ping -c2 ${ping_ip}
		if [[ $? -eq 0 ]]
		then
	
			echo "##########"
			echo ""
			echo "VPN IS UP"
			echo ""
			echo "##########" 
	
		else
	
			echo "#####################################################################"
			echo "VPN is not up...please check to see if you have a firewall in place."
			echo "#####################################################################"
	
		fi
	
	
	else
	
		echo "Error from remote server."
		cat "${tmpFile}"
		rm -f "${tmpFile}"
	fi	

}


tmpFile="/tmp/wg"

# User's with some special characters like spaces at the end of their password
# were being stripped so this embedded python prompt preserves those characters
# and base64 encodes it only to help preserve the integrity of the special
# characters in the user's password.  It is not a replacement for using
# a secure connection.
function get_p() {
python3 - <<TRY

import getpass
import base64

p = getpass.getpass()
enc = p.encode('UTF-8')
q = base64.b64encode(enc)
print(q.decode('UTF-8'))

TRY
}

# Checks to see if connected to the VPN
function test_ping_vpn() {

	ping -c1 ${ping_ip} -W 2
	if [[ $? -eq 0 ]]
	then
    
		echo "###########"
		echo "VPN is on."
		echo "###########"

	else

		echo "###########"
		echo "VPN is off."
		echo "###########"

	fi

}

function on_err() {


	if [[ $? -ne 0 ]]
	then
		echo "Error running command."
		exit 1
	fi

}

function cmd_usage() {

	 echo "Usage: $(basename $0) and an option below
               -d Start the VPN
	       -f delete the current VPN IP (Requires an argument) -f X.X.X.X
               -i install the VPN client
	       -m Remove VPN configurations
               -r restart the VPN
               -s stop the VPN
               -t Test the VPN by pinging the VPN Default gateway
	       -y Set a Static IP for this VPN host (Requires an argument) -y X.X.X.X
	       -z Enable Roaming (All Internet Traffic goes through your VPN)
               -h How to use this script
                        "

}

# Get Current OS

if [[ -f /etc/os-release ]]; then

	the_os=$(awk -F= '/^NAME/{print $2}' /etc/os-release | sed 's/"//g')

else

	# Check if a mac.
	if [[ "$(uname -a | egrep '^Darwin')" != "" ]]; then
	
		the_os=$(uname -a | awk ' { print $1 } ')

	else

		echo "Unsupported OS"
		exit 1

	fi

fi

# Check if requisite packages are installed
# curl, resolvconf, and wireguard-tools
check_package() {

	for p in $1; do

		pkg="$(which ${p})"	
		if [[ "${pkg}" ==  "" ]]
		then
	
			if [[ ${toApt} -eq 0 ]]
			then
	
				echo "Refreshing available packages..."
				#$2 apt update
				$2
				toApt=1
			fi

			# wg is from the wireguard-tools package
			if [[ "${p}" == "wg" ]]
			then
	
				# Prevent installing the wireguard module
				# Only the client tool is needed.
				# $3 apt install --no-install-recommends wireguard-tools -y
				if [[ "$3" == "CentOS" ]]
				then

					dnf install epel-release elrepo-release -y
					yum install wireguard-tools -y

				elif [[ "$3" == "Debian" ]]
				then

					sh -c "echo 'deb http://deb.debian.org/debian buster-backports main contrib non-free' > /etc/apt/sources.list.d/buster-backports.list"
					apt update
					apt install wireguard-tools --no-install-recommends -y	
					apt install curl resolvconf -y 


				else

					$3

				fi
				
				on_err
	
			else
	
				# Install curl or resolvconf if necessary.
				# $4 apt install $1 -y
				$4
				on_err
	
			fi
	
		fi

	done

} #end check_package function

function which_os() {

	toApt=0	
	
	case "${the_os}" in
	
		Ubuntu)
	
		check_package "curl wg resolvconf" "apt update" "apt install --no-install-recommends wireguard-tools -y" "apt install curl resolvconf -y"
	
		;;
	
		Fedora)
	
		check_package "wg" "yum update --assumeno" "yum install wireguard-tools -y" ""
		
		;;
		"CentOS Linux")
	
		check_package "wg" "yum update --assumeno" "CentOS" ""
		
		;;
	
		"Arch Linux")
	
			check_package "wg" "" "pacman -S wireguard-tools" ""
		;;

		"Manjaro Linux")
	
			check_package "wg" "" "pacman -S wireguard-tools" ""
		;;

		"Debian GNU/Linux")

			check_package "wg" "apt update"  "Debian" ""

		;;
	
		*)
	
			echo "Unsupported OS"
			exit 1
	
	esac

}

if [ -z "${1}" ]; then

	cmd_usage
	exit 1

fi
while getopts 'itsrdhxzy:f:' OPTION; do

	case "${OPTION}" in

	i)	

		mac_config="/usr/local/etc/wireguard/wgvpn.conf"
		nix_config="/etc/wireguard/wgvpn.con"

		# Check if VPN configuration already exists
		if [[ -f "${mac_config}" || -f "${nix_config}" ]]
		then

			echo "########################################"
			echo "The VPN configuration already exists."
			echo "Please contact the System Administrator"
			echo "To create a new client configuration or"
			echo "to reset it for this computer."
			echo "########################################"
			exit 1
		fi

		# Check for package dependencies
		
		if [[ "${if_mac}" == "Darwin" ]]
		then

			echo ""

		else

			which_os

		fi

		# Enter code
		echo -n "Please enter your SSH username: "
		read user

pass=$(get_p)

		curl https://${vpn_server}/nowire/wgcheck.php -F 'submit=Login' -F "username=${user}" -F "password=${pass}" -F "action=a" -o "${tmpFile}"
		
		bring_up_vpn

		;;

#itsrdh

		t)

			echo "#########################################################"
			echo "Pinging VPN Gateway IP"
			echo "If the ping hangs then use Control+c to terminate."
			echo "#########################################################"
			ping -c2 ${ping_ip}
			exit 0

			;;

		s) echo "Stopping VPN"
			wg-quick down wgvpn
			wg-quick down roam_wgvpn
			test_ping_vpn
		;;

		r) echo "Restarting VPN"
			wg-quick down wgvpn ; wg-quick up wgvpn
			echo "#########################################################"
			echo "No Roaming. Use bash linux-nowire.sh -z to enable roaming."
			echo "#########################################################"
			test_ping_vpn


		;;

		d) echo "Starting VPN"
			wg-quick up wgvpn
			echo "No Roaming"
		
		;;

		h)

			cmd_usage
		;;

		f)

		static_ip=${OPTARG}

		if [[ "$static_ip" == "" ]]; then
		
			echo "Please enter an IP address.\n";
			exit 1

		fi

		tmpFile="/tmp/wg"
		
		echo -n "Please enter your SSH username: "
		read user

#		echo -n "Please enter your password: "
#		read -s pass	

pass=$(get_p)
		curl https://${vpn_server}/nowire/wgcheck.php -F 'submit=Login' -F "username=${user}" -F "password=${pass}" -F "action=d" -F "static_ip=${static_ip}" -o "${tmpFile}"
		
		# empty pass variable before enabling stty echo
		pass=""

		cat "${tmpFile}"
		rm "${tmpFile}"
		;;

		x)

			wg-quick down wgvpn
			rm -f /etc/wireguard/wgvpn.conf
		;;

		y)

			static_ip=${OPTARG}
	
			if [[ "$static_ip" == "" ]]; then
			
				echo "Please enter an IP address.\n";
				exit 1
	
			fi
	
			tmpFile="/tmp/wg"
			
			echo -n "Please enter your SSH username: "
			read user
	
	pass=$(get_p)
			curl https://${vpn_server}/nowire/wgcheck.php -F 'submit=Login' -F "username=${user}" -F "password=${pass}" -F "action=a" -F "static_ip=${static_ip}" -o "${tmpFile}"
			
			bring_up_vpn

		;;

		z)

				# Get the current IP
				current_ip=$(curl ipinfo.io/ip)

				# Wireguard configuration info
				WG_CONFIG_ROAM="/etc/wireguard/roam_wgvpn.conf"
				WG_CONFIG="/etc/wireguard/wgvpn.conf"

				# Check if the roam config is non-zero byte
				if [[ -s  ${WG_CONFIG_ROAM} ]]
				then
	
					wg-quick down wgvpn
					wg-quick up roam_wgvpn
	
				else
	
					# Copy current config to roaming config
					cp ${WG_CONFIG} ${WG_CONFIG_ROAM}
					
					# Replace current AllowedIPs with 0.0.0.0 to route all traffic
					sed -i 's/^AllowedIPs =.*/&, 0.0.0.0\/0/g' ${WG_CONFIG_ROAM}

					# Bring down the interface
					wg-quick down wgvpn

					# Bring up the roaming interface
					wg-quick up roam_wgvpn
	
				fi

				# Get IP after the VPN is up
				new_ip=$(curl ipinfo.io/ip)

				# Check to see if the old IP and the VPN IP are different
				# Could be hardcoded.
				if [[ "${current_ip}" != "${new_ip}" ]]
				then

					echo "#############################################"
					echo "You are now roaming."
					echo "All Traffic is going through your private VPN"
					echo "#############################################"
					exit 0

				else

					echo "#############################################"
					echo "Error.  Roaming was not successful."
					echo "Try running:  bash linux-nowire.sh -s"
					echo "Then:  bash linux-nowire.sh -z"
					echo "#############################################"
					exit 1

				fi

		;;

		*)

			cmd_usage
		;;

	esac

# Get opts while loop
done

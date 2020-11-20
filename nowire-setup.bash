#!/bin/bash

# Setup the nowire configurations

if [ $EUID -ne 0 ]; then

	echo "You need to run this script as a super user."
	echo "ex. sudo nowire-setup.bash"
	exit

fi

read -p "Enter the location of the Wireguard configuration file: [Default: /etc/wireguard]" config

# Check user input
if [[ "${config}" == "" ]]; then

	config='/etc/wireguard'

fi

if [[ ! -d "${config}" ]]; then

	echo ""
	echo "The directory doesn't exist."
	echo "Please run wireguard-server.bash first or enter the location of the existing wireguard configuration file."
	echo ""
	exit 1

fi

# Nowire configuration directory
read -p "Enter the location to store the wireguard configuration files: [Default: /var/peers/wireguard-nowire]" config_nowire

# Check user input
if [[ "${config_nowire}" == "" ]]; then

	config_nowire='/var/peers/wireguard-nowire'

fi

# Create the directory if doesn't exist.
if [[ ! -d "${config_nowire}" ]]; then

	read -p "The directory ${config_nowire} does not exist, create it? " create_dir
	if [[ ${create_dir} =~ 'y' ]]; then

		# Push in case top-level and subdirectories don't exist.
		mkdir -p ${config_nowire}

	else

		exit 1

	fi

fi


function peerips() {

	# Peer IPs
	read -p "How many VPN peer IPs can a user have? 0 is unlimited. [Default: 0]: " peer_ips

}

peerips

if [[ -z ${peer_ips} ]]; then

	peer_ips=0

else

	# Check that only an 
	while (true); do
	
		# if not a digit then call the peerips function
		if ! [[ ${peer_ips} =~ ^[0-9]+$ ]]; then
	
			peerips
	
		else
	
			# If a digit then break out of the loop
			break
	
		fi
	
	done

fi

function thehost() {

	read -p "Enter the hostname or IP of the SSH server where users are authenticated: [Default: localhost]: " the_host

	# Loop to check that the hostname or IP are valid
	while (true); do

		# Check user input
		if [[ "${the_host}" == "" || "${the_host}" == "localhost" ]]; then
	
			the_host='localhost'
			break
	
		else
	
			# Check if hostname provide.
			if [[ "${the_host}" =~ [a-zA-Z] ]]; then

				# regex: https://learning.oreilly.com/library/view/regular-expressions-cookbook/9781449327453/ch08s15.html
				if [[ "$(echo ${the_host} | grep -P '^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$')" == "" ]]; then
					
					thehost

				fi

				# if valid break out the loop
				break

			# Check it is an ip
			else

				if [[ "$(echo ${the_host} | egrep -o '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$')" == "" ]]; then

					thehost
					break

				fi

				# if valid break out the loop
				break

			fi

		fi

	done

}

thehost

function vpnadmin() {

	# VPN Admin user
	read -p "Enter the VPN admin user: " vpn_admin

}

vpnadmin
# vpn admin is required
while (true); do

	# Check user input
	if [[ "${vpn_admin}" == "" || "${vpn_admin}" == "root" ]]; then
		# Call on entering the vpn admin
		vpnadmin

	else

		break
	
	fi

done

function webroot() {

	read -p "Please enter the web root. [Default: /var/www/html]" web_root



# ...and that it exists.
while (true); do

	# Check the web root is set
	if [[ "${web_root}" == "" ]]; then

		web_root="/var/www/html"
		break

	elif [[ ! -d "${web_root}" ]]; then

		read -p "The web root provided \'${web_root}\' doesn't exist. Create it? " create_webroot

		if [[ "${create_webroot}" =~ 'y' ]]; then

			mkdir -p ${web_root}
			break

		else

			webroot

		fi


	else

		break

	fi

done
}
webroot

# Escape the backslashes in the directory path for the sed statement
wgcdir=$(echo ${config} | sed 's/\//\\\//g')
nwcdir=$(echo ${config_nowire} | sed 's/\//\\\//g')

# Edit the nowire configuration files
sed -i "s/^WG_CONFIG=.*/WG_CONFIG='${wgcdir}\/wg0.conf'/" get_vpn_info.bash
sed -i "s/^WG_CONFIG=.*/WG_CONFIG='${wgcdir}\/wg0.conf'/" get_max_ips.bash
sed -i "s/^WG_CONFIG=.*/WG_CONFIG='${wgcdir}\/wg0.conf'/" get_expire_account.bash
sed -i "s/^WG_CLIENTS=.*/WG_CLIENTS='${nwcdir}\/clients'/" wireguard-server.sh
sed -i "s/^WG_SCRIPTS_NOWIRE=.*/WG_SCRIPTS_NOWIRE='${nwcdir}'/" wireguard-server.sh
sed -i "s/^\$WG_SERVER_SCRIPT_PATH=.*/\$WG_SERVER_SCRIPT_PATH='${nwcdir}'/" wireguard-server.sh
sed -i "s/^\$WG_VPN_INFO =.*/\$WG_VPN_INFO = \"\$WG_SERVER_SCRIPT_PATH\/vpn_info.txt\";/" nowire/config.php
sed -i "s/^\$WHO_CAN_DELETE_PEERS =.*/\$WHO_CAN_DELETE_PEERS = \'${vpn_admin}\';/" nowire/config.php
sed -i "s/^\$PEER_IPS =.*/\$PEER_IPS = ${peer_ips};/" nowire/config.php
sed -i "s/^\$SSH_HOST =.*/\$SSH_HOST = '${the_host}';/" nowire/config.php

# Create the directory structure for nowire and copy the files.
chmod 700 ${config_nowire}
mkdir -p ${config_nowire}/{tmp,clients}
chown -R www-data: ${config_nowire}

# Create initial vpn_info.txt file.
bash get_vpn_info.bash
if [[ $? != 0 ]]; then

	exit 1
fi

# copy files to their respective directories
cp get_vpn_info.bash get_max_ips.bash wireguard-server.sh vpn_info.txt ${config_nowire}
cp -rp otp/  ${config_nowire}/
chmod 700 ${config_nowire}/{get_vpn_info.bash,wireguard-server.sh}
chown nobody: ${config_nowire}/{get_vpn_info.bash,wireguard-server.sh}

# Copy scripts to the webroot
cp -rp nowire ${web_root}
chown nobody: ${web_root}/nowire/{wgcheck.php,config.php}

echo ""
echo "All Done."
echo ""

function setotp() {

	read -p "Do you want to setup otp? [Default: no] " set_otp

	while (true); do
	
		if [[ "${set_otp}" =~ 'y' ]]; then

	
			# call on OTP setup
			cd ${config_nowire}/otp/
			bash setup_otp.bash
			chown www-data: nowire.db

		else

			echo ""
			echo "###############################################################"
			echo ""
			echo "Exiting. OTP not setup.  If you want to enable it later, then\n
			run:  bash otp/setup_otp.bash"
			echo ""
			echo "###############################################################"
			echo ""

			break
	
		fi

		break
	done

}

setotp

#!/bin/bash

: '

This script will configure otp

'

function get_nowire() {

	while (true); do

		read -p "What is the path to the nowire directory in the web root? [Default: /var/www/html/nowire] " nowire_webroot
		
		if [[ "${nowire_webroot}" == "" ]]; then

			nowire_webroot=/var/www/html/nowire

			if [[ ! -d "${nowire_webroot}" ]]; then
		
			get_nowire

			fi

		elif [[ ! -d "${nowire_webroot}" ]]; then
		
			get_nowire

		else

			break

		fi

		break

	done

}

# Check if the web root is passed by the setup.bash script.
if [[ "${1}" == "" ]]; then

	get_nowire

else

	nowire_webroot="${1}"

fi


function get_nowire_config() {

	while (true); do

		read -p "What is the path to the nowire configuration directory? [Default: /var/peers/wireguard-nowire] " nowire_config
		
		if [[ "${nowire_config}" == "" ]]; then

			nowire_config=/var/peers/wireguard-nowire

			if [[ ! -d "${nowire_config}" ]]; then
		
				get_nowire_config

			fi

		elif [[ ! -d "${nowire_config}" ]]; then
		
			get_nowire_config

		else

			break

		fi

		break
	done
}

# Check if the nowire configuration root is passed by the setup.bash script.
if [[ "${1}" == "" ]]; then

	get_nowire_config

else

	nowire_config="${2}"

fi


function get_hours() {

	while (true); do
		
		read -p "How many hours until the VPN expires? [Default: 24] " expire_hours

		if [[ "${expire_hours}" == "" ]]; then

			expire_hours=24
			break

		elif [[ "${expire_hours}" =~ ^[0-9]+$ ]]; then

			break

		else

			get_hours

		fi

	done

}

get_hours

function on_err() {

	if [[ $? != 0 ]]; then

		echo "########################################"
		echo ""
		echo "Error creating ${1}"
		echo ""
		echo "########################################"
		exit 1

	fi
}

	# Set USE_OTP in web config.php
	sed -i "s/^\$USE_OTP = [0-1]\{1\};/\$USE_OTP = 1;/" ${nowire_webroot}/config.php
	on_err "Editing config.php"

	# Set the OTP_HOURS in wireguard-server.sh
	sed -i "s/^OTP_HOURS=[0-9]\{1,14\}/OTP_HOURS=${expire_hours}/" ${nowire_config}/wireguard-server.sh
	on_err "Editing wireguard-server.sh"

	# Check the USE_OTP setting matches what was passed to it
	grep -o "\$USE_OTP = 1;" ${nowire_webroot}/config.php
	on_err "The \$USE_OTP setting is not enabled in the web configuration file => ${nowire_webroot}/config.php."

	# Check the OTP_HOURS setting matches what was passed to it
	grep -o "OTP_HOURS=${expire_hours}" ${nowire_config}/wireguard-server.sh
	on_err "The OTP_HOURS setting was not properly set in the file => ${nowire_config}/wireguard-server.sh"

	if [[ ! -f "otp/nowire.db" ]]; then

		# Create Database
		bash sqlite-db.bash
		on_err "Error creating the database"
		
		# Set permissions for web user
		chown www-data: ${nowire_config}/otp
		chown www-data: ${nowire_config}/otp/nowire.db

	else

		echo "Nowire database already exists."
		echo "You will have to delete it first."

	fi

	echo "################################################"
	echo ""
	echo "OTP has been setup"
	echo ""
	echo "################################################"

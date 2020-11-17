#!/bin/bash

####    EDIT IF DIFFERENT FROM THE DEFAULT LOCATION     ####

WG_CONFIG='/etc/wireguard/wg0.conf'

####    END EDITING     ####

: '

On a multiuser server, the VPN admin may only want to allow users to have a limited number of IPs so that is checked here.


'

the_user="${1}"

if [[ "${1}" == "" ]]; then

	echo "No User Specified"
	exit 1

fi

# Count the number of VPN Peer IPs for the user
max_ips=$(egrep "^# $the_user-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} start$" ${WG_CONFIG} | awk ' { print $2 } ' | cut -d- -f1 |wc -l)

# Value sent to the PHP program
echo "${max_ips}";

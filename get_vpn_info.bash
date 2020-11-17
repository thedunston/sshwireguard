#!/bin/bash

####    EDIT IF DIFFERENT FROM THE DEFAULT LOCATION     ####

WG_CONFIG='/etc/wireguard/wg0.conf'

####    END EDITING     ####

: '

This script reads in the VPN configuration file and gets the VPN Network and the IPs.

It is called after the client is created or removed so it is updated with the latest
IPs.

It prevents the web user from needing read access to the VPN configuration file.

The IPs may be out of order due to the removal of user VPN configurations.  The default is to use the last available IP and then add 1. However, if the last IP assigned is: X.X.X.10 and an old account X.X.X.5 was removed, then there will be an unused IP: X.X.X.5.  Similarly, if there is a static IP of X.X.X.100 and the last dynamically assigned is: X.X.X.10 then there will be a gap between IP address assignments.

In the above example, the next dynamic IP will be: X.X.X.5 the one that was removed.  If no other IPs are removed, then the next time a dynamic IP is assigned, based on the example above, then it will be X.X.X.11.


'


# Check if config file exists.
if [[ ! -f "${WG_CONFIG}" ]]; then

	echo "Wireguard Configuration File doesn't exist. Did you run wireguard-server.bash first or edit the WG_CONFIG vairable in this file?"
	exit 1

fi

# Get the network for the VPn
get_net=$(head -n1 ${WG_CONFIG} | awk ' { print $2 } ' | cut -d, -f1)

# Get the current IPs and sort
net_id="$(echo ${get_net} |awk -F\. ' { print $1"."$2"."$3 } ')"

function chk_config() {

	# When there are no more gaps in IPs, only the VPN network ID is left
	# This code will add the next usable IP along with the VPN Network ID
	# Check to see if there is only one or two lines in the vpn_info.txt file.  If so, then get the last IP and add +1
	get_num=$(cat ${vpn_info}/vpn_info.txt | wc -l | awk ' { print $1 } ')
	if [[ ${get_num} -eq 1 || ${get_num} -eq 2 ]]; then

		# Get the last IP
		TMP_OCTET=$(egrep -o "^AllowedIPs = ${net_id}.[0-9]{1,3}" /etc/wireguard/wg0.conf | awk ' { print $3 } ' | cut -d\. -f4 | sort  -n | tail -1)

		# Add 1
		LAST_OCTET=$( expr ${TMP_OCTET} + 1 )

		# Append to the vpn_info.txt file
		echo ${LAST_OCTET} >>  ${vpn_info}/vpn_info.txt

	fi

} # End chk_config function

function vpn_net() {

	head -n1 ${WG_CONFIG} | awk ' { print $2 } ' | cut -d, -f1 > "${vpn_info}/vpn_info.txt"

}

if [[ ! -f "${vpn_info}/vpn_info.txt" || -z "${vpn_info}/vpn_info.txt" ]]; then

	vpn_net
	chk_config

fi


# Check that only a valid network was returned
clean_val=$(echo "${get_net}" | egrep '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{2}$')

# VPN info text file
vpn_info=$(dirname $0)

if [[ "${get_net}" != "" ]]; then

	# Return the network
	echo "${get_net}" > ${vpn_info}/vpn_info.txt

	# Gets the IPs and gets prints any that are missing since a user can specify a static IP
	# https://stackoverflow.com/questions/38491676/how-can-i-find-the-missing-integers-in-a-unique-and-sequential-list-one-per-lin
	egrep -o "^AllowedIPs = ${net_id}\.[0-9]{1,3}" ${WG_CONFIG} | awk ' { print $3 } ' | cut -d\. -f4 |  sort -n | awk '{for(i=p+1; i<$1; i++) print i} {p=$1}' | egrep -v '^1$' >> ${vpn_info}/vpn_info.txt

	chk_config

	exit 0

else

	exit 1

fi

#!/bin/bash

: '


This script should be added to cron to run hourly.  It will check to see if the account is expired and then remove it from the VPN configuration file and reload the VPN


'

# Configuration file
WG_CONFIG='/etc/wireguard/wg0.conf'

# Current date to compare with expirations
current_date=$(date -d '+24 hours' '+%Y%m%d%H%M')

# Loop through and get all accounts that have expired
for each_peer in `egrep -o "[a-z]{2,30}-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-expire-[0-9]{12}" ${WG_CONFIG} | uniq`; do

	# Get the user
	user="$(echo ${each_peer} | awk -F- ' { print $1 } ')"

	# Get the expire date from the config file
	expiry="$(echo ${each_peer} | sed 's/ start//g'|  awk -F- ' { print $4 } ')"

	# Check if the date is less than the current date
	if [[ ${expiry} -lt ${current_date} ]]; then

		# Get the peers Publickey
		pub=$(sed -n "/${each_peer} start/,/${each_peer} end/p" ${WG_CONFIG} |grep PublicKey | awk ' { print $3 } ')

		# Remove the peer
		sed -i "/\# ${each_peer} start/,/\# ${each_peer} end/d" ${WG_CONFIG}

		# Delete their public key from the WG server and drop their access immediately
		wg set wg0 peer ${pub} remove


	fi

	# refresh the VPN configuration
	wg addconf wg0 <(wg-quick strip wg0)

done

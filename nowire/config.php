<?php

// The location of the wireguard-server.sh config file
// Put this script outside of the web root
// No trailing slash
$WG_SERVER_SCRIPT_PATH = '/var/peers/wireguard-nowire';

// The location of the wireguard configuration
// Setting below is the default.  Change if needed.
$WG_VPN_INFO = "$WG_SERVER_SCRIPT_PATH/vpn_info.txt";

// USER allowed to delete peers
$WHO_CAN_DELETE_PEERS = 'duane';

// How many Peer IPs can one user have?
$PEER_IPS = 0;

// SSH Host. The SSH host containing the user accounts to authenticate
// before they can get an IP.
$SSH_HOST = 'myserver.com';

/**************************************
*
* Please be sure you understand how the code works before editing below.
*
* ***************************************/

function the_msg($error) {

	echo "---------------------------------------------------------\n";
	echo "\n\nMESSAGE => $error\n\n";
	echo "---------------------------------------------------------\n";
	exit();

} // end the_msg() function

// SSH Connection
function ssh_conn($user, $pass, $hostname) {

	// SSH Authentication
	$upass = base64_decode($pass);
	$connection = ssh2_connect($hostname, 22);

	if (!ssh2_auth_password($connection, $user, $upass)) {

		the_msg('Authentication Failed...');

	}

	return $result;

} // End ssh_conn function

// Run the script
function write_file($f,$c) {

	// Array to store the return value and output from commands
	$returned_results = array();
	$file = new \SplFileObject($f, "w");
	$file->fwrite($c);
	
	exec("sudo bash $f", $output, $retval);
	
	$file = null;
	unlink($f);
	
	$returned_results[] = $retval;
	$returned_results[] = $output[0];
	
	return $returned_results;

} // end function write_file

// Check if the static IP belongs to the network
/**
* Check if a given ip is in a network
* @param  string $ip    IP to check in IPV4 format eg. 127.0.0.1
* @param  string $range IP/CIDR netmask eg. 127.0.0.0/24, also 127.0.0.1 is accepted and /32 assumed
* @return boolean true if the ip is in this range / false if not.

https://gist.github.com/tott/7684443
*/
function ip_in_range( $ip, $range ) {

	if ( strpos( $range, '/' ) == false ) {
		
		$range .= '/32';
	
	}

	// $range is in IP/CIDR format eg 127.0.0.1/24
	list( $range, $netmask ) = explode( '/', $range, 2 );
	$range_decimal = ip2long( $range );
	$ip_decimal = ip2long( $ip );
	$wildcard_decimal = pow( 2, ( 32 - $netmask ) ) - 1;
	$netmask_decimal = ~ $wildcard_decimal;
	
	return ( ( $ip_decimal & $netmask_decimal ) == ( $range_decimal & $netmask_decimal ) );

} // end ip_in_range function

// Verify IP
function check_ip($ip) {

	if (!filter_var($ip, FILTER_VALIDATE_IP)) {
      
		the_msg("The static IP provided is not a valid IP address. => $ip\n");

	}

} // end check_ip function

?>

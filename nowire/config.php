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
$PEER_IPS = 20;

// SSH Host
$SSH_HOST = 'localhost';

// Use OTP.  0 is off 1 is on.
$USE_OTP = 0;

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

function check_user($username) {

	// User variables
	$username = $_POST['username'];

	// Check username before authentication
	if (!preg_match('/^[a-zA-Z\d_\.-]{2,30}$/', $username)) {

		the_msg("Invalid username and/or password.");

	}
	
}

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

}

// Verify IP
function check_ip($ip) {

	if (!filter_var($ip, FILTER_VALIDATE_IP)) {
      
		the_msg("The static IP provided is not a valid IP address. => $ip\n");

	}

}

/********************************************************************
*
* Encryption and decryption for the OTP secret
*
********************************************************************/
function otp_encrypt($plaintext,$the_key) {

	$cipher = "aes-256-cbc";
	$ivlen = openssl_cipher_iv_length($cipher);
	$iv = openssl_random_pseudo_bytes($ivlen);

	//store $cipher, $iv, and $tag for decryption later
	$ciphertext = openssl_encrypt($plaintext, $cipher, $the_key, $options=0, $iv);

	// The iv needs to be stored so it can be used to decrypt the ciphertext
	$cipher_iv = base64_encode("$ciphertext:$iv");
	return $cipher_iv;

}

function otp_decrypt($ciphertext,$the_key) {

	$cipher = "aes-256-cbc";

	// Get the IV and ciphertext
	$cipher_iv = base64_decode($ciphertext);
	$x = explode(":",$cipher_iv);
	$ciphertext = $x[0];
	$iv = $x[1];
	$original_plaintext = openssl_decrypt($ciphertext, $cipher, $the_key, $options=0, $iv);

	return $original_plaintext;

}

function select_user($the_user) {

	global $WG_SERVER_SCRIPT_PATH;

	// Sqlite DB
	$db = new SQLite3($WG_SERVER_SCRIPT_PATH.'/otp/nowire.db');

	// Escape unsafe DB characters
                $the_user_escaped = SQLite3::escapeString($the_user);

                // Select user and secret the DB
                $stm = $db->prepare('SELECT user,secret FROM nowire_otp WHERE user = ?;');
                $stm->bindValue(1,$the_user_escaped, SQLITE3_TEXT);
                $result = $stm->execute();

		$r = array();

                while ($row = $result->fetchArray(SQLITE3_ASSOC)) {

                        if ($row['user'] == "") {

                                $results = "NO";
				$r[] = $results;

                        } else {

                                $results = "YES";
				$r[] = $results;

                        }
			
			$r[] = $row['secret'];

                } // end while loop

                return $r;

} // end select_user function

function insert_user($the_user, $enc_secret) {

	global $WG_SERVER_SCRIPT_PATH;
// Sqlite DB
        $db = new SQLite3($WG_SERVER_SCRIPT_PATH.'/otp/nowire.db');

	// Escape unsafe DB characters
         $username_escaped = SQLite3::escapeString($the_user);
	
 // Add user to the DB
        $stm = $db->prepare('INSERT INTO nowire_otp VALUES (:user, :secret)');
        $stm->bindValue(':user', $username_escaped);
        $stm->bindValue(':secret', $enc_secret);
        $result = $stm->execute();

	return $result;

} // end insert user

function update_user($the_user, $enc_secret) {

	global $WG_SERVER_SCRIPT_PATH;
// Sqlite DB
        $db = new SQLite3($WG_SERVER_SCRIPT_PATH.'/otp/nowire.db');

	// Escape unsafe DB characters
	$username_escaped = SQLite3::escapeString($the_user);
	
 // Add user to the DB
        $stm = $db->prepare('UPDATE nowire_otp SET secret = :secret WHERE user = :user');
        $stm->bindValue(':user', $username_escaped);
        $stm->bindValue(':secret', $enc_secret);
        $result = $stm->execute();

	return $result;

} // end insert user

?>

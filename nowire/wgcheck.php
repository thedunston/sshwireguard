<?php

// Load otp libraries
require __DIR__ . '/.htvendor/autoload.php';

// // use the OTP library
use OTPHP\TOTP;

include('config.php');

/**************************************

Please be sure you understand how the code works before editing below.

***************************************/

// Check there is a valid username before being passed for authentication
$username = $_POST['username'];

// Check username before authentication
if (!preg_match('/^[a-zA-Z\d_\.-]{2,30}$/', $username)) {

	the_msg("Invalid username and/or password.");

}

if ($_POST['submit'] == "Login") {

	$password = $_POST['password'];

	// Test authentication
	$c = ssh_conn($username, $password, $SSH_HOST);

	// The OTP code provided by the user.
	$input = $_POST['code'];

	// Check if code has been provided.
	if ($USE_OTP == 1) {
		
		if ($input == "") {
		
			echo "Send OTP";
			exit();

		}


		// Remove non-numeric characters
		$input = preg_replace("/[^0-9]/", "", $input);

		// Check that the input is valid
		if (!is_numeric($input)) {

			the_msg("Invalid code.");

		}

		if (strlen($input) != 6) {

			the_msg("Invalid code.");
	
		}

		// Clean up username before querying the DB
		$username_escaped = SQLite3::escapeString($username);
		
		// Initialize Database
		$db = new SQLite3($WG_SERVER_SCRIPT_PATH.'/otp/nowire.db');

		// Retrieve user secret from DB
		$stm = $db->prepare('SELECT user,secret FROM nowire_otp WHERE user = ?;');
		$stm->bindValue(1,$username_escaped, SQLITE3_TEXT);
		$result = $stm->execute();

		$secret = "";

		// Get the secret
	        while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
	
			if ($row['user'] == "") {

				the_msg("Please register for an account.");

			}

			$secret = $row['secret'];

		}

		// Decrypt the secret	
		$dec = otp_decrypt($secret,base64_decode($password));

		// Initialize the current code
		$otp = TOTP::create($dec); // create TOTP object from the secret.

		if (!$otp->verify($input)) {
	
			the_msg("Invalid code provided.");
		
		} else {
		
			$otp_success = 1;	

		}

	} // end use OTP check


/**************************************************************************
*
* Start VPN client configuration
*
**************************************************************************/

	// Script to run
	$script = "$WG_SERVER_SCRIPT_PATH/tmp/wg-add.bash";

	// Check if user has reached max number of peer ips
	$retval = write_file($script,"bash $WG_SERVER_SCRIPT_PATH/get_max_ips.bash $username");

	// Check to see if maximum number of Peer IPs has been met
	if ($retval[1] >= $PEER_IPS) {
	
		the_msg("The maximum number of VPN IPs you can have has been met.");
	
	}

	// Client configuration location
	$client_config = "$WG_SERVER_SCRIPT_PATH/clients/$username-wg0.conf";

	// Get network
	$fh = fopen($WG_VPN_INFO,'r');

	// The network ID is within the first 12 bytes of the $WG_VPN_INFO file var.
	$net = fgets($fh,12);
	fclose($fh);

	// Check that it is a network ID.
	if (!preg_match("/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{2}$/", $net)) {

		//echo "$net";
		the_msg("The network ID of the VPN is not valid => $net");

	}

	// Check there is a network ID
	if ($net == "") {

		  the_msg("The network of the VPN could not be retrieved.");

	}

	// Split the network ID
	$n = explode(".", $net);
	$the_net = "$n[0].$n[1].$n[2]";

	/**********************************************

	PASSED IN VARIABLES

	**********************************************/
	$stat_ip = htmlentities($_POST['static_ip'], ENT_QUOTES);
	$todo = htmlentities($_POST['action'], ENT_QUOTES);

	// Validate action
	if (!preg_match('/^(a|d){1}$/', $todo)) {

		the_msg("Invalid action.");

	}

/** TEST VARS **/
//$stat_ip = "*";
//$todo = "dele";


	/*********************************************

	REMOVE IP

	*********************************************/
	if ($stat_ip != "" && $todo == "d") {

		if ("$WHO_CAN_DELETE_PEERS" != "$username") {

			the_msg("Please contact an admin to delete a peer.");

		}

		if ("$stat_ip" == "$the_net.1") {

			the_msg("The IP cannot be deleted.");

		}

		// Verify the IP is valid
		check_ip($stat_ip);

		// Check to see if the IP is in the range of our VPN
		if (!ip_in_range($stat_ip, $net)) {

			the_msg("The IP provided is not within the VPN network range.");

		}

		// REMOVE the VPN peer and static IP
		$remove_user_stat = "bash $WG_SERVER_SCRIPT_PATH/wireguard-server.sh --remove $username:$stat_ip\n";

		// Script that will be executed by the web server user
		$script = "$WG_SERVER_SCRIPT_PATH/tmp/wg-add.bash";

		// Execute the command
		$retval = write_file($script, $remove_user_stat);

		if ($retval[0] != 0 ) {

			the_msg("Error removing the user.");

		}

		// Get the last octet
		$last_octet = explode(".", $stat_ip);

		// Check if the user was removed by search for the octet.  If it exists, it was removed.
		if (strpos(file_get_contents($WG_VPN_INFO),$last_octet[3])) {
 			
			the_msg("User was not removed. User VPN IP doesn't exist.");
			exit();

		} else {		

			the_msg("The IP $stat_ip was removed.");
			exit();

		}

	} // end check for stat_ip AND action
	
	/*********************************************

		END REMOVE IP

	*********************************************/

	/*********************************************

	STATIC IP assignment

	*********************************************/
	// Check if static IP is requested.
	if ($stat_ip != "") {

		// Verify the IP is valid
		check_ip($stat_ip);

		// Check to see if the IP is in the range of our VPN
		if (!ip_in_range($stat_ip, $net)) {

			the_msg("The IP provided is not within the VPN network range.");

		}

		// Get the last octet
		$last_octet = explode(".", $stat_ip);

		// Check if the octet is available
		if (strpos(file_get_contents($WG_VPN_INFO),$last_octet[3])) {
 			
			the_msg("The IP $stat_ip already exists.");

		}

		// Add the VPN peer and static IP
		$add_user_stat = "bash $WG_SERVER_SCRIPT_PATH/wireguard-server.sh --add $username:static_ip:$last_octet[3]\n";

		// Script that will be executed by the web server user
		$script = "$WG_SERVER_SCRIPT_PATH/tmp/wg-add.bash";

		// Execute the command
		$retval = write_file($script, $add_user_stat);

		// Check if the user was added by search for the octet
		if (strpos(file_get_contents($WG_VPN_INFO),$last_octet[3])) {
 			
			the_msg("User was not added.");

		} else {		

			// Display the IP configuration on the client
			readfile($client_config);
			unlink($client_config);
			exit();

		}
		
	}
	/*********************************************

	END STATIC IP assignment

	*********************************************/

	/**  GET THE IP    */
	$the_octet = "";
	$output = "";

	/*********************************************
	
	Dynamic IP assignment
	
	*********************************************/
	
	// Read in the VPN file INFO
	$o = file($WG_VPN_INFO);
	
	// Get the second line of the file which is an unused IP.
	$the_octet = $o[1];

	// command to add to file.
	if ($the_octet == "") {
	
		$add_user = "bash $WG_SERVER_SCRIPT_PATH/wireguard-server.sh --add $username\n";

	} else {

		$add_user = "bash $WG_SERVER_SCRIPT_PATH/wireguard-server.sh --add $username:last_octet:$the_octet\n";


	}

	// Write the $add_user command to the file wg-add.bash
	// This writes to the /tmp directory
	$retval = write_file("$WG_SERVER_SCRIPT_PATH/tmp/wg-add.bash",$add_user);

	// Check if the script ran successfully.
	if ($retval[0] != 0) {

		$file = new \SplFileObject($WG_SERVER_SCRIPT_PATH."/tmp/wg-add.bash", "w");
		$file = null;
		#unlink("$WG_SERVER_SCRIPT_PATH/tmp/wg-add.bash");
		the_msg("Error adding user.");

	}

	// Display the IP configuration on the client
	readfile($client_config);
	unlink($client_config);

} // end main $_POST['submit'] if statement

?>

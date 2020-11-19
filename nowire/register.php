<?php

/****************************************************************
 * This script registers the account for the vpn user.
 * They are presented with a QR Code which they use for
 * the 2FA.
 *
 * *************************************************************/

use BaconQrCode\Renderer\ImageRenderer;
use BaconQrCode\Renderer\Image\ImagickImageBackEnd;
use BaconQrCode\Renderer\RendererStyle\RendererStyle;
use BaconQrCode\Writer;

// Load otp libraries
require __DIR__ . '/.htvendor/autoload.php';

// use the OTP library
use OTPHP\TOTP;

include('config.php');

header( 'Content-type: text/html; charset=utf-8' );

// User variables
$username = $_POST['username'];

if ($_POST['submit'] == "Register") {

	check_user($username);
	$password = base64_encode($_POST['password']);
	

	/**************************************
	
	Please be sure you understand how the code works before editing below.
	
	***************************************/

	// Authenticate
	$c = ssh_conn($username, $password, $SSH_HOST);

	// See if the user exists.
	$chk = select_user($username);

	if ($chk[0] == "YES") {

		the_msg("User account already exists.  Please contact the VPN administrator!");
	
	}

	// create TOTP object from the secret.
	$otp = TOTP::create(); 

	// Get text version of secret to add to DB
	$secret = $otp->getSecret();

	// Set label for QR Code
	$otp->setLabel('Nowire');

	$renderer = new ImageRenderer(
		new RendererStyle(400),
		new ImagickImageBackEnd()
	);

	$writer = new Writer($renderer);
	$grCodeUri = $writer->writeString($otp->getProvisioningUri());
	
	$webroot = dirname(__FILE__);
	// Array to store the return value and output from commands
        $file = new \SplFileObject("$webroot/$username-qrcode.png", "w");
        $file->fwrite($grCodeUri);
	
	if ($grCodeUri == "") {

		the_msg("Error generating QR Code.");
	
	}
	 
	// Display QR Code
	// Method is used to print the image to the screen
	// and then delete the qrcode
	for ($i=0; $i<2; $i++) {

		ob_flush();
		flush();
	
		if ($i == 0) {

			echo "<p>";
			echo "<p>Please download freeotp and scan the QR Code below.";
			echo "<p>";
			echo "<img src='$username-qrcode.png'";
			echo "'>";
			echo "<p>";

		}

		sleep(1);

	}
	
        $file = null;
        unlink("$webroot/$username-qrcode.png");

	// Escape unsafe DB characters
	$username_escaped = SQLite3::escapeString($username);

	// Encrypt secret
	$enc = otp_encrypt($secret,base64_decode($password));

	// Insert user
	insert_user($username,$enc);
	
	// Check if the account was created.
	$chk = select_user($username);
	if ($chk[0] == "YES") {

		the_msg("User account created.");
	
	} else {
	
		the_msg("Error adding account, please try again!");
	
	}

// Unencrypt secret with the new password

} elseif ($_POST['submit'] == "Update") {

	check_user($username);

	// Be sure the new password is the same
	$new_password = base64_encode($_POST['newpass']);
	$new_password2 = base64_encode($_POST['newpass2']);

	if ($new_password != $new_password2) {
	
		echo "New Passwords do not match.";
		exit();
	
	}


	$old_password = base64_encode($_POST['password']);

	// Authenticate
	// The $new_password is used because the user would have already changed
	// their password on the server running SSH.
	ssh_conn($username, $new_password, $SSH_HOST);

	// Check that the user password exists.
	$user = select_user($username);

	if ($user[0] == "No") {

		the_msg("Account was not found.  Please contact the VPN administrator.");
	
	}

	// Secret encrypted with old password
	$secret = $user[1];

	// Decrypt the secret   
	$dec = otp_decrypt($secret,base64_decode($old_password));
	
	// Initialize the current code
	$otp = TOTP::create($dec); // create TOTP object from the secret.

	// Encrypt the secret with the password
	$new_secret = otp_encrypt($otp->getSecret(),base64_decode($new_password));

	// Update the DB with the secret encrypted with the new password
	$update = update_user($username,$new_secret);

	if ($update) {

		echo "OTP code has been updated.";
		exit();
	
	} else {

		echo "OTP code has not been updated.";
		exit();

	}

?>

	<form method="post" action="<?php print($_SERVER['PHP_SELF']); ?>">

		Username: 
       		<input type="text" name="username" value="">
		<br />
		Password: 
       		<input type="password" name="password" value="">
	        <input type="submit" name="submit" value="Register">

	</form>

<?php
	
// Display login form
} else { 

?>

	<form method="post" action="<?php print($_SERVER['PHP_SELF']); ?>">

Register 2FA access<p>
		Username: 
       		<input type="text" name="username" value="">
		<br />
		Password: 
       		<input type="password" name="password" value="">
<br />

	        <input type="submit" name="submit" value="Register">
	</form>

	
	<p>	- OR - <p>
	<form method="post" action="<?php print($_SERVER['PHP_SELF']); ?>">
		Update 2FA access:<p>

		Username: <input type="text" name="username" value=""><br />
		Old Password: <input type="password" name="password" value=""><br />
       		New Password: <input type="password" name="newpass" value="">
<br />

       		Confirm New Password: <input type="password" name="newpass2" value="">
	        <input type="submit" name="submit" value="Update">

	</form>

<?php

}


?>

# Nowire
Nowire was created because I wanted to make it easier for students to gain access to our VPN.  I really like how simple the configuration and management of Wireguard is and how it only manages the crypto for the VPN tunnels.  Since there is no manager for it, I decided to create a program that allows configuring a VPN peer without a lot of configuration by those using the VPN.  Those with Linux and Macs sometimes have a lot more configuration to do for many VPN solutions, though the Wireguard GUI makes it easier on Windows and Mac.

I started playing around with containers and wanted to connect those across multiple servers so that and wanting students to quickly connect to a VPN led to the creation of Nowire.  The name nowire comes from the fact that I'm not good at naming things and since the VPN peers were connecting from remote locations without a wire...nowire.

Nowire is written in PHP, bash, and there is a Powershell script for Windows that allows quickly setting up VPN peers.  The Nowire VPN configuration is based on Prajwal Koirala's Wireguard Manager - https://github.com/complexorganizations/wireguard-manager/blob/main/wireguard-server.sh, which is a shell script to setup a Wireguard VPN, manage the VPN service, and configure peers. I found it to be the easiest program to setup a Wireguard VPN.  

The VPN peers run the script client-nowire.sh or WindowsNowire.ps1, authenticate via the PHP script using the PHP-SSH2 module, and automatically downloads the auto-generated VPN file, and automatically configures the Wireguard interface.

The authentication is managed using the PHP SSH2 module.  The SSH server can be on a different host than the VPN.

*NOTE: The SSH password prompt is an embedded python script in the client-nowire.sh.  Users with some special characters get stripped in bash so Python was used to preserve special characters and base64 encode the password.  It is then base64 decoded on the remote server with the PHP script.  Accordingly, the base64 encoding is only for preserving the integrity of the user's password special characters.*

A user can select a static IP or assigned a dynamic IP. 

There is a script: get_vpn_info.bash which checks for any gaps in assigned IPs and assigns based on that first.  Otherwise, IPs are assigned sequentially using the Wireguard Manager script.  If the last dynamic IP assigned is X.X.X.5 and a static IP is set with X.X.X.100 there will be a large gap in the number of unused IPs.  The Wireguard-Manager script assigns IPs sequentially so the next dynamic IP would X.X.X.101.  The script get_vpn_info.bash resolves that issue by retrieving all IPs in the VPN configuration file, sorts them sequentially, and returns a list of the unused octets.  Those are stored in vpn_info.txt, which was created to mitigate the web server user from having to read the Wireguard VPN configuration file.

The VPN client scripts have been tested on arch Linux, Ubuntu 18+, Debian 9, Fedora, CentOS, MacOS, and Windows 10.

Prerequisites:

- Linux server
- Apache
- php7+
- php-ssh2
- HTTPS connection to the VPN server.
- Wireguard-Manager has its own dependencies (jq, qrencode)
- PHP Sqlite Module and Sqlite if you use OTP

## Setup

###Wireguard Setup

Wireguard needs to be installed first.  **If you already have Wireguard installed, then skip this step.**  Run the script *wireguard-server.sh* and follow the prompts or the easiest method is to run it Headless from the commandline:

<pre>HEADLESS_INSTALL=y ./wireguard-server.sh --install</pre>

and it will setup Wireguard automatically and download all necessary packages.

However, if you want to manually configure settings then run:

<pre>./wireguard-server.sh --install</pre>

### Nowire configuration setup

Sample install session (You will have to configure SSL with Apache):

<pre>
apt install apache2 php7.2 php7.2-ssh2 php7.2-sqlite3 sqlite3
git clone https://github.com/thedunston/nowire.git
cd nowire/
HEADLESS_INSTALL=y sudo ./wireguard-server.sh --install
sudo apt install jq
sudo bash nowire-setup.bash
sudo wg-quick up wg0

</pre>

Automatic setup

<pre>
bash nowire-setup.bash
</pre>

to setup the nowire configuration directory and add the nowire directory and scripts to your web directory.

#### Manual Setup

If you want to edit the scripts manually then add the full path of the wireguard configuration file to the top of get_vpn_info.bash and get_max_ips.bash to the WG_CONFIG line.  Edit the files nowire/config.php and change the settings as needed there, as well.

Copy all files in this directory to the location of $WG_SERVER_SCRIPT_PATH

Change permissions so it is read, write, and execute by the web server user and make the scripts editable by a non-privileged user because a sudo command will be used to execute the scripts as root.

Recommended commands (Tested on Ubuntu 18.04 and 20.04, but the paths are based on your setup):

<pre>
mkdir -p /var/peers/wireguard-nowire/{tmp,clients}
chmod 700 /var/peers/wireguard-nowire/
chown www-data: /var/peers/wireguard-nowire/{tmp,clients}
cp get_vpn_info.bash wireguard-server.sh /var/peers/wireguard-nowire/
chown nobody: /var/peers/wireguard-nowire/{get_vpn_info.bash,wireguard-server.sh}
chown www-data: /var/peers/wireguard-nowire/tmp/

#Copy the wgcheck.php script to the web root.  Currently, a directory named "nowire" is required in the webroot

cp -rp nowire /var/www/html/nowire
chown nobody: /var/www/html/nowire/{config.php,wgcheck.php}
</pre>

Finally, copy the "nowire" directory into your web root.

#### End nowire manual setup

## Sudo setup
In order for the web server user to run the scripts as root, which are needed to prevent the web user from having access to the wireguard configuration files, add the following to the /etc/sudoers file. Change "hostname" to the hostname of your VPN server based on what is in /etc/hostname.  Also, change www-data to the user running the web server and the change the location of /var/peers/wireguard-nowire/tmp/ to the directory you selected to store the nowire configuration files

<pre>
www-data hostname = NOPASSWD: /bin/bash /var/peers/wireguard-nowire/tmp/wg-add.bash
</pre>

The file wg-add.bash is created dynamically and deleted after it adds or removes a VPN user.

#### OTP Setup

During the install, you can select the option to enable OTP.  Otherwise, you can edit nowire/config.php and change:

<pre>$USE_OTP = 0;</pre>

to

<pre>$USE_OTP = 1;</pre>

and change 

Next, add the file get_expire_account.bash to cron and run it hourly.

<pre>
chmod +x get_expire_account.bash
cp get_expire_account.bash /etc/cron.hourly
</pre>

Or add it to your crontab:

<pre>
0 * * * * bash /var/peers/wireguard-nowire/get_expire_account.bash
</pre>

Also, with OTP, the VPN Peers connection to the VPN will default to expire every 24 hours unless otherwise specified.  You will be prompted during the install or you can edit wireguard-server.sh and near top change:

<pre>
OTP_HOURS=24
</pre>


to whatever value.  With bash, don't put spaces between the variable and value.

Won't work:

<pre>
OTP_HOURS = 48
</pre>

Will work:

<pre>
OTP_HOURS=48
</pre>

FreeOTP and Google Authenticator were tested.

When a user changes their password on the SSH server, it will break their ability to use OTP because their unique secret is being protected with their password.  The script nowire/register.php can be used to enter the old SSH password and the new one in order to continue using their existing OTP authenticator.

## CLIENT SCRIPT

Since the VPN IP may be behind NAT, the client scripts will need to be edited manually before distributing to users to setup their VPN peer.

Edit the client script client-nowire.sh and add the FQDN of your Public VPN server IP or hostname.

*vpn_server=""*

and

*ping_ip=""*

The ping_ip should be a host that the user can ping when they connect to the VPN to test their connectivity is working.

#### On the VPN peers

Run the script:  

<pre>sudo bash client-nowire.sh -h</pre>

 to see options.  

The command will check to ensure all the appropriate packages are installed, download missing packages (if necessary), and then prompt the user for the SSH username and SSH Password.

<pre>sudo bash client-nowire.sh -i</pre>

The Powershell script will elevate the user if they are not running as an administrator.


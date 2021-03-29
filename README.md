# Nowire

## Background
Nowire was created because I wanted to make it easier for students to gain access to our VPN.  I really like how simple the configuration and management of Wireguard is and how it only manages the crypto for the VPN tunnels.  Since there is no manager for it, I decided to create a program that allows configuring a VPN peer without a lot of configuration by those using the VPN.  Those with Linux and Macs sometimes have a lot more configuration to do for many VPN solutions, though the Wireguard GUI makes it easier on Windows and Mac.

I started playing around with containers and wanted to connect those across multiple servers so that and wanting students to quickly connect to a VPN led to the creation of Nowire.  The name nowire comes from the fact that I'm not good at naming things and since the VPN peers were connecting from remote locations without a wire...nowire.

Nowire is written in PHP, bash, and there is a Powershell script for Windows that allows quickly setting up VPN peers.  The Nowire VPN configuration is based on Prajwal Koirala's Wireguard Manager - https://github.com/complexorganizations/wireguard-manager/blob/main/wireguard-server.sh, which is a shell script to setup a Wireguard VPN, manage the VPN service, and configure peers. I found it to be the easiest program to setup a Wireguard VPN.  

## Nowire Authentication and Client configurations

The VPN peers run the script client-nowire.sh or WindowsNowire.ps1, authenticate via the PHP script using the PHP-SSH2 module, and automatically downloads the auto-generated VPN peer configuration file, and automatically configures the Wireguard interface.

The authentication is managed using the PHP SSH2 module.  The SSH server can be on a different host than the VPN.

*NOTE: The SSH password prompt is an embedded python script in the client-nowire.sh.  Users with some special characters get stripped in bash so Python was used to preserve special characters and base64 encode the password.  It is then base64 decoded on the remote server with the PHP script.  Accordingly, the base64 encoding is **only** for preserving the integrity of the user's password special characters.*

##  Nowire IP Assignment Management
There is a script: *get_vpn_info.bash* which checks for any gaps in assigned IPs and assigns based on that first.  Otherwise, IPs are assigned sequentially.  If the last dynamic IP assigned is X.X.X.5 and a static IP is set with X.X.X.100 there will be a large gap in the number of unused IPs.  The *wireguard-server.sh* script assigns IPs sequentially so the next dynamic IP would X.X.X.101.  The script *get_vpn_info.bash* resolves that issue by retrieving all IPs in the VPN configuration file, sorts them sequentially, and returns a list of the unused octets.  Those are stored in *vpn_info.txt*, which was created to mitigate the web server user from having to read the Wireguard VPN configuration file.

The VPN client scripts have been tested on arch Linux, Ubuntu 18+, Debian 9, Fedora, CentOS, MacOS, and Windows 10.

### Prerequisites:

- Linux server
- Apache
- php7+
- php-ssh2
- HTTPS connection to the VPN server.
- Wireguard-Manager has its own dependencies (jq, qrencode)
- PHP Sqlite Module and Sqlite if you use OTP

Documentation has moved to the [Wiki](https://github.com/thedunston/nowire/wiki)


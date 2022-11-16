# sshwireguard

**Status:** Actively used by author and actively supported.

License: sshwirdguard © 2022 by Duane Dunston is licensed under Attribution-ShareAlike 4.0 International. To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/4.0/

sshwireguard is a program that distributes Wireguard VPN configuration files over SSH to clients and automatically starts their Wireguard VPN client.  It has replaced the nowire application.

**Ready for use.**

### Why was nowire replaced?

The nowire application required PHP and Apache to distribute files to users and 3rd party One-time password modules. That was a lot of overhead for a very simple purpose.

The Wireguard VPN configuration files are now distributed over SSH. Since SSH is used extensively across Linux distributions and is usually a publicly availble service, I decided to use a well-established secure communication and file transfer protocol instead having to manage web SSL certificates, updating PHP, Apache, and third-party modules.

### What does sshwireguard do?

sshwireguard manages the Wireguard application for starting and stopping the service and downloading the configuration files. The SSH application scp is used to download the VPN and YAML configuration files.  The YAML file contains configurations that are read by the sshwireguard client.

In summary, a user runs the command:

    sshwireguard start

and the WireGuard service is started. If they run:

    sshwireguard stop

the WireGuard service is stopped.  The status of whether or not the service is up and running can be managed with:

    sshwireguard status

Whether it is used for remote access by roadwarriors or to setup quick peer-to-peer networks, all activity is performed over encrypted communication channels.

### Using sshwireguard

The sshwireguard clients are written in Go.  sshwireguard uses the native scp client on Windows 10+ Server 2016+ and Linux.  Support will be provided for [pscp](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html).

The Wireguard server runs on Linux (WSL has not been tested).  It uses a modified version of [ComplexOrganizations](https://github.com/complexorganizations/wireguard-manager) wireguard manager script.  The customizations are based on the needs for the automation of creating new VPN configurations.

Features added include

- Custom expiration date option per user
- Automated cron job that checks for users and removes them after a given period of time and generates a new VPN configuration
- Expirations can be set for a standard period for all users such as every 48 hours
- Email notification that the VPN configuration is going to expire.  One 2 hour notifcation prior to deactivation and the user has to re-authenticate.
- Fill in IP gaps. When a user is removed there is a gap in available IPs since their IP is free. When a new VPN configuration is created, it will use the first available free IP if there are gaps.

**NOTE**
Multifactor authentication is supported since the native SSH or pscp client is used interactively so no changes are required for existing multifactor authentication methods. Similarly, SSH keys will work normally, as well.

Accordingly, sshwireguard doesn't manage any multifactor authentication or SSH keys.  The sshwireguard client creates an interactive session that allows authentication via SSH to occur just as it did prior to using sshwireguard.

## Installation

## *Server*

On the Linux server hosting the Wireguard service, copy the wireguard-manager.sh file to a directory.  *Please note that the SSH server does not have to be on the same host as the WireGuard VPN*.  The server running SSH is only needed to distribute the WireGuard configuration and config.yaml file for each client. The config.yaml file will have the public IP address of the WireGuard server.

Make the script executable, run it and follow the prompts.

    chmod +x wireguard-manager.sh
    ./wireguard-manager.sh

Please pay attention to each prompt and input the appropriate values.

If you want to install without prompts then run:

    ./wireguard-manager.sh --install

Be aware that it will install the unbound DNS server on the WireGuard VPN server.

### Add new users

    ./wireguard-manager.sh --add username

replace "username" with the user's name.  Adding a user will not disrupt existing VPN clients.

### Remove a user

    ./wireguard-manager.sh --remove username

replace "username" with the user's name.  Removing a user will not disrupt existing VPN clients.

### Add a custom expiration for a user

    ./wireguard-manager.sh --add

Follow the prompts to create an expiration date.

Expiring an account can be used in a couple of ways.  One is to expire the account for temporary users, at the end of a project, end of a semester, etc.  The other is to require users to change their VPN client configuration on a periodic basis such as every 24 or 48 hours, etc.

TODO: Allow adding a custom expiration for existing users.

## *Client setup*

1. Download the [Wireguard client](https://www.wireguard.com/install/) for the respective OS.
2. Most Unix distributions have the scp client already installed.  Windows hosts can install the OpenSSH tools via the Microsoft Programs and Features control panel.

3. Download the sshwireguard binary for the respective OS.

4. On Linux/Unix based systems make the file executable:

        chmod +x sshwireguard-xxx-xxxx.bin

5. On Windows, download the sshwireguard executable ending with .exe.

6. The first time you run the client, you can execute it and it will check if the *sshwireguardConf* directory exists in the user's home directory.  If not, then it will start the process to download the *sshwireguardConf* directory from the WireGuard VPN server.  Follow the prompts for the username, IP or domain name for the SSH server, and enter the port for the SSH server.

7. Once the files have been downloaded, sshwireguard will attempt to start the WireGuard tunnel.  On Unix based systems the client runs "sudo" and on Windows, it will prompt to run with admin privileges.  Elevating to admin only occurs when starting or stopping the sshwireguard Tunnel. The interface name is called "sshwireguard."

TODO: Allow multiple profiles in case a user uses multiple WireGuard servers.
TODO: Create a GUI for the client.

8.  Managing the Wireguard Tunnel:

sshwireguard init - Initializes a new VPN configuration  
sshwireguard stop - Stops the VPN tunnel  
sshwireguard start - Returns whether the sshwireguard Tunnel is running or not running  
sshwireguard renew - Downloads a new VPN configuration (reads config.yaml file located in the sshwireguardConf directory)  

### Compiling clients

The clients can be compiled from source.  First install go 1.16+.

run:

    make help

for options.

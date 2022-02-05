# sshwireguard

sshwireguard is a program that distributes Wireguard VPN configuration files over SSH to clients and automatically starts their Wireguard VPN client.  It has replaced the nowire applications

**It is still beta**.  More features need to be added such as starting and stopping the VPN tunnels.  That will be completed by 2/14.

### Why was nowire replaced?

The nowire application required PHP and Apache to distribute files to users and 3rd party One-time password modules.   That was a lot of overhead for a very simple purpose.

The Wireguard VPN configuration files are now distributed over SSH.  Since SSH is used extensively across Linux distributions and is usually a publicly availble service, I decided to use a well-established secure communication and file transfer protocol instead having to manage web SSL certifications, updating PHP, Apache, and third-party modules.

### What does sshwireguard do?

sshwireguard performs the same functions where the user authenticates to the remote SSH server, a VPN configuration file is downloaded, and then automatically connects to the Wireguard VPN server.  Whether it is used for remote access by roadwarriors or to setup quick peer-to-peer networks, all activity is performed over encrypted communication channels.

### Using sshwireguard

The sshwireguard clients are written in Go.  sshwireguard uses the native scp client on Windows 10+ Server 2016+ and Linux.  Support will be provided for [pscp](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) soon too.

The Wireguard server runs on Linux (WSL has not been tested).  It uses a modified version of [ComplexOrganizations](https://github.com/complexorganizations/wireguard-manager) wireguard manager script.  The customizations are based on the needs for the automation of creating new VPN configurations.

Features added include

- Custom expiration date option per user
- Automated cron job that checks for users and removes them and generates a new VPN configuration
- Expirations can be set for a standard period for all users such as every 48 hours
- Email notification that the VPN configuration is going to expire.  One 2 hour notifcation prior to deactivation and the user has to re-authenticate.
- Fill in IP gaps. When a user is removed there is a gap in available IPs since their IP is free. When a new VPN configuration is created, it will use the first available free IP if there are gaps.
- Multifactor authentication is supported since the native SSH or pscp client is used interactively.

### Installation

Installation instructions will be added once sshwireguard is out of beta.  Testing is being performed on Linux and Windows hosts.  However, since the clients are written in Go, it can compile to multiple platforms including FreeBSD, MacOS, and different architectures, as well.

Source and binaries will be available when it is ready for release. It is planned to be released for testing around 2/14/2022.


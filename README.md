# Nowire

## Background
Nowire was created because I wanted to make it easier for students to gain access to our VPN.  I really like how simple the configuration and management of Wireguard is and how it only manages the crypto for the VPN tunnels.  Since there is no manager for it, I decided to create a program that allows configuring a VPN peer without a lot of configuration by those using the VPN.  Those with Linux and Macs sometimes have a lot more configuration to do for many VPN solutions, though the Wireguard GUI makes it easier on Windows and Mac.

I started playing around with containers and wanted to connect those across multiple servers so that and wanting students to quickly connect to a VPN led to the creation of Nowire.  The name nowire comes from the fact that I'm not good at naming things and since the VPN peers were connecting from remote locations without a wire...nowire.

Nowire is written in PHP, bash, and there is a Powershell script for Windows that allows quickly setting up VPN peers.  The Nowire VPN configuration is based on Prajwal Koirala's Wireguard Manager - https://github.com/complexorganizations/wireguard-manager, which is a shell script to setup a Wireguard VPN, manage the VPN service, and configure peers. I found it to be the easiest program to setup a Wireguard VPN.  

Documentation has moved to the [Wiki](https://github.com/thedunston/nowire/wiki)


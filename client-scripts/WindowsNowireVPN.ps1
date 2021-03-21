# Edit this for your VPN server
$Uri = 'https://my.server.com/nowire/wgcheck.php'
$Uri_Check_Auth = 'https://my.server.com/nowire/auth_check.php'

# This should be an IP that can only be pinged when on the VPN
$ping_ip = ""

Write-Host "Checking for elevated permissions..."
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator")) {
Write-Warning "Insufficient permissions to run this script."
Start-Process Powershell -ArgumentList $PSCommandPath -Verb RunAs

}

# Check if file exists
$wg_file = "wireguard-installer.exe"
$wg_Path = "$env:USERPROFILE\$wg_file"
$Uri_wg = "https://download.wireguard.com/windows-client/$wg_file"
if (Test-Path -Path "c:\windows\system32\wg.exe") {

    echo "Wireguard installed."
    sleep 1
    
} else {

    write-host "Downloading wireguard..."
    #$result = Invoke-WebRequest -Uri $Uri_wg -OutFile $wg_Path
    
    write-host "Installing wireguard..."
    start-process msiexec.exe /i, $wg_Path, /qb -Wait -Passthru

}

$userPath = "$env:USERPROFILE\wgvpn.conf"
$userVPN = "WireGuardTunnel`$wgvpn"
$userVPNName = "wgvpn"

function allDone (){

    write-host ""
    Read-Host -Prompt "Enter to return to main menu."
    menu

}

function check_connection() {

    echo "Testing connectivity..."
    # Test to see if the VPN is up.
    if (Test-Connection -ComputerName $ping_ip -Count 5) {
                        
        # If so, print the message
        write-host -BackgroundColor green -ForegroundColor white "VPN is up"

        allDone
            
    } else {
            
        # Else print an error
        write-host -BackgroundColor red -ForegroundColor white "VPN is not working properly."
        wg show $userVPNName
        allDone

    }

}

function menu() {

clear
write-host "[1] Install VPN Service"
write-host "[2] Remove VPN Service"
write-host "[3] Start VPN Service"
write-host "[4] Stop VPN Service"
write-host "[5] Restart VPN Service"
write-host "[6] Test Connection"
write-host "[7] Test Authentication"
write-host "[E]xit"

$choice = Read-Host -Prompt "Please type the value in the square brackets"

    switch ($choice) {

        1 {get_vpn_config}
        2 {remove_config}
        3 {start_vpn}
        4 {stop_vpn}
        5 {stop_vpn
                start_vpn}
        6 {check_connection}
        7 {check_auth}
        8 {user_register}
        "E" {return}
        default {write-host -BackgroundColor red -ForegroundColor white "Invalid value"
                 menu}

    }

}

function start_vpn () {

    write-host "Please wait starting the VPN..."

    Start-Service $userVPN

    sleep 5

    check_connection

    menu
}

function stop_vpn () {

    write-host "Please wait stopping the VPN..."
    Stop-Service $userVPN

        sleep 5

    try            
    
    { Test-Connection -ComputerName $ping_ip -Count 5 -ErrorAction stop }            
            
    catch [System.Net.NetworkInformation.PingException] {

        write-host -BackgroundColor Green  "VPN stopped"
       
    }

    alldone
    
}

function restart_vpn() {

    stop_vpn
    start_vpn

    menu

}

function check_vpn() {

    # Check if VPN config exists
    if (Test-Path $userPath) {

        # Delete the config?
        $remove_conf = Read-Host -Prompt "VPN configuration file exists, do you want to remove the configuration? [y|N]"

        # If no, then ask to start
        if ($remove_conf -eq "n" -or $remove_conf -eq "") {
    
            # Ask to start
            $start_vpn = Read-Host -Prompt "Do you want to start the VPN? [Y|n]"
        
            # If yes, then start the VPN
            if ($start_vpn -eq "Y" -or $start_vpn -eq "") {
        
                # Start the VPN
                start_vpn

                check_connection
        
            } else {
        
                # Close the program
                write-host "Closing the program."
                return
        
            }

        # Remove vpn configuration and create a config.
        } else {
        
        
            # Delete the config file
            rm $userPath

            # Get a new VPN Config
            get_vpn_config
        
        }

    }

} # end check_vpn function

function remove_config() {
    
        # Delete the config?
        $remove_conf = Read-Host -Prompt "Remove the current VPN configuration? [Y|n]"

        # If no, then ask to start
        if ($remove_conf -eq "Y" -or $remove_conf -eq "") {
     
            # Stop VPN
            Stop-Service $userVPN   
     
            # Uninstall VPN service
            & 'C:\Program Files\WireGuard\wireguard.exe' /uninstalltunnelservice $userVPNName

            # Remove the vpn Configuration
            Remove-Item $userPath
    
            $new_config = Read-Host -Prompt "Do you want to download a new configuration file? [Y|n]"
        
            if ( $new_config -eq "Y" -or $new_config -eq "") {
        

                # Download new config.
                get_vpn_config
        
            } else {
        
                # Close the program
                return
        
            }
            
        } else {
        
            # Close the program
            return
        
        } 

} # end remove_config function

$Form = ""
function user_login() {

   # Prompt for credentials
    $user = Read-Host -Prompt "What is your username "
    $upass = Read-Host -Prompt "What is your password " -AsSecureString
    write-host -BackgroundColor black -ForegroundColor white "Logging in"
    # Convert password to plaintext to pass to the remote server.
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($upass)
    $value = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    $b64_pass = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($value))
        $global:Form = @{
            username  = "$user"
            password      = "$b64_pass"
            action = "a"
            submit = "Login"
        }

} # end user_login function

function check_auth() {

user_login

    # Use TLS
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $Result = Invoke-WebRequest -Uri $Uri_Check_Auth  -Method Post -Body $global:Form -OutFile "$userPath" 
    
    # Check if the configuration file was downloaded.
    type "$userPath"
    sleep 2
    $global:Form = ""
    menu

}

function get_vpn_config() {

    user_login

    # Use TLS
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $Result = Invoke-WebRequest -Uri $Uri -Method Post -Body $global:Form -OutFile "$userPath" 
    
    $global:Form = @{
            username  = "$user"
            password      = "$b64_pass"
            action = "a"
            submit = "Login"
        }

    $global:Form = ""
    
    # Check if the configuration file was downloaded.
    $cfgCheck = Select-String "Interface" "$userPath"

    if ($cfgCheck) {

        # Replace the extraneous peer information.
        (Get-Content "$userPath" -Raw) -Replace "(?sm)^# $user start.*?(?=^# $user end)"
            
        # Install the configuration as a VPN service
        & 'C:\Program Files\WireGuard\wireguard.exe' /installtunnelservice $userPath

        write-host -BackgroundColor green -ForegroundColor white "Bringing up the connection.  Please wait..."
        sleep 3

        check_connection 

    } else {
        
        write-host -BackgroundColor red -ForegroundColor white "Error Downloading the VPN configuration"
        type "$userPath"
    
        read-host -Prompt "Press enter when done."
    }

} # end get_vpn_config

menu

# net-clerk
This set of scripts helps me deal with my Apple MacOS laptop to seamlessly move between my Home Wi-Fi, corporate Wi-Fi with NTLMv2 authenticated proxies and the corporate VPN. It automatically toggles the proxy settings on the Wi-Fi and LAN interfaces to use cntlm or switch it off. The script will detect the context and toggles it.

## Configuration
The file netclerk-ssid-home.list takes a list (one per line) of SSIDs that you use at home.
The file netclerk-ssid-work.list takes a list (one per line) of SSIDs that you use at work.
The VPN is toggle by discovering the utun device as the most prefered network device. This is tested to work with the MacOS Cisco Any Connect VPN client.
The run.config file contains the default settings. You can speed up the detection cycle (not recommended) and set a default username. Setting a username explicitly is particularly important if you want to launch the subscripts in a screen session (running in the background) and want to make the cntlm run as your user. Without it, the tool could crash on the cntlm enabling (continuously) and makes it impossible to connect the background running screen in the current terminal/TTY for debugging.

## Before usage.
Change the following files by name:
* netclerk-ssid-home.list.default to netclerk-ssid-home.list
* netclerk-ssid-work.list.default to netclerk-ssid-work.list
* run.config.default to run.config

## Run
Start net-clerk with ./net-clerk.sh. It will prompt you for not running in privileged mode. The script uses sudo, so you are seeing sudo right there.
It is recommend to run net-clerk in a screen session, like: "screen ./net-clerk" and hitting "ctrl-a d" to detach the screen session.
With "screen -r" you can see the "cntlm" and "net-clerk" main tool run in the background. You can take a peak to each with "screen -r <some identier you copied and pasted here>".

## Elevated privileges requirement.
MacOS requires you to confirm proxy setting changes from netsetup on the commandline with a visual prompt. It will ask for your credentials or TouchID. When netsetup is called from root, no visual prompt is given and the experience is thus seamless.

# Todo
* Make it easier to configure and install.
* Install it with brew
* Install it with as a launchd daemon
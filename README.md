# [NZBGet](https://github.com/nzbget/NZBGet), WireGuard and OpenVPN
[![Docker Pulls](https://img.shields.io/docker/pulls/dyonr/nzbgetvpn)](https://hub.docker.com/r/dyonr/nzbgetvpn)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/dyonr/nzbgetvpn)](https://hub.docker.com/r/dyonr/nzbgetvpn)

Docker container which runs the latest [NZBGet](https://github.com/nzbget/NZBGet) client while connecting to WireGuard or OpenVPN with iptables killswitch to prevent IP leakage when the tunnel goes down.


## Docker Features
* Base: Debian 10-slim
* [NZBGet](https://github.com/nzbget/NZBGet) compiled from source
* Selectively enable or disable WireGuard or OpenVPN support
* IP tables killswitch to prevent IP leaking when VPN connection fails
* Specify name servers to add to container
* Configure UID and GID for config files and /downloads for NZBGet
* Created with [Unraid](https://unraid.net/) in mind

# Run container from Docker registry
The container is available from the Docker registry and this is the simplest way to get it  
To run the container use this command, with additional parameters, please refer to the Variables, Volumes, and Ports section:

```
$ docker run --privileged  -d \
              -v /your/config/path/:/config \
              -v /your/downloads/path/:/downloads \
              -e "VPN_ENABLED=yes" \
              -e "VPN_TYPE=wireguard" \
              -e "LAN_NETWORK=192.168.0.0/24" \
              -e "NAME_SERVERS=1.1.1.1,1.0.0.1" \
              -p 6789:6789 \
              -p 6791:6791 \
              --restart unless-stopped \
              dyonr/nzbgetvpn
```

# Variables, Volumes, and Ports
## Environment Variables
| Variable | Required | Function | Example | Default |
|----------|----------|----------|----------|----------|
|`VPN_ENABLED`| Yes | Enable VPN (yes/no)?|`VPN_ENABLED=yes`|`yes`|
|`VPN_TYPE`| Yes | WireGuard or OpenVPN (wireguard/openvpn)?|`VPN_TYPE=wireguard`|`openvpn`|
|`VPN_USERNAME`| No | If username and password provided, configures ovpn file automatically |`VPN_USERNAME=ad8f64c02a2de`||
|`VPN_PASSWORD`| No | If username and password provided, configures ovpn file automatically |`VPN_PASSWORD=ac98df79ed7fb`||
|`LAN_NETWORK`| Yes (atleast one) | Comma delimited local Network's with CIDR notation |`LAN_NETWORK=192.168.0.0/24,10.10.0.0/24`||
|`ENABLE_SSL`| No | Let the container handle SSL (yes/no)? |`ENABLE_SSL=yes`|`yes`|
|`WEBUI_USERNAME`| Yes | Username used to connect to the WebUI|`WEBUI_USERNAME=nzbget`|`nzbget`|
|`WEBUI_PASSWORD`| Yes | Password used to connect to the WebUI |`WEBUI_PASSWORD=tegbzn6789`|`tegbzn6789`|
|`NAME_SERVERS`| No | Comma delimited name servers |`NAME_SERVERS=1.1.1.1,1.0.0.1`|`1.1.1.1,1.0.0.1`|
|`PUID`| No | UID applied to /config files and /downloads |`PUID=99`|`99`|
|`PGID`| No | GID applied to /config files and /downloads  |`PGID=100`|`100`|
|`UMASK`| No | |`UMASK=002`|`002`|
|`HEALTH_CHECK_HOST`| No |This is the host or IP that the healthcheck script will use to check an active connection|`HEALTH_CHECK_HOST=one.one.one.one`|`one.one.one.one`|
|`HEALTH_CHECK_INTERVAL`| No |This is the time in seconds that the container waits to see if the internet connection still works (check if VPN died)|`HEALTH_CHECK_INTERVAL=300`|`300`|
|`HEALTH_CHECK_SILENT`| No |Set to `1` to supress the 'Network is up' message. Defaults to `1` if unset.|`HEALTH_CHECK_SILENT=1`|`1`|
|`DISABLE_IPV6`\*| No |Setting the value of this to `0` will **enable** IPv6 in sysctl. `1` will disable IPv6 in sysctl.|`DISABLE_IPV6=1`|`1`|
|`ADDITIONAL_PORTS`| No |Adding a comma delimited list of ports will allow these ports via the iptables script.|`ADDITIONAL_PORTS=1234,8112`||

\*This option was initially added as a way to fix problems with VPN providers that support IPv6 and might not work at all. I am unable to test this since my VPN provider does not support IPv6, nor I have an IPv6 connection.


## Volumes
| Volume | Required | Function | Example |
|----------|----------|----------|----------|
| `config` | Yes | NZBGet, WireGuard and OpenVPN config files | `/your/config/path/:/config`|
| `downloads` | No | Default downloads path for saving downloads | `/your/downloads/path/:/downloads`|

## Ports
| Port | Proto | Required | Function | Example |
|----------|----------|----------|----------|----------|
| `6789` | TCP | Yes | NZBGet WebUI (HTTP) | `6789:6789`|
| `6791` | TCP | Yes | NZBGet WebUI (HTTPS) | `6791:6791`|

# Access the WebUI
Access http://IPADDRESS:PORT from a browser on the same network. (for example: http://192.168.0.90:6789)

## Default Credentials

| Credential | Default Value |
|----------|----------|
|`Username`| `nzbget` |
|`Password`| `tegbzn6789` |

# How to use WireGuard 
The container will fail to boot if `VPN_ENABLED` is set and there is no valid .conf file present in the /config/wireguard directory. Drop a .conf file from your VPN provider into /config/wireguard and start the container again. The file must have the name `wg0.confg`. 

# How to use OpenVPN
The container will fail to boot if `VPN_ENABLED` is set and there is no valid .ovpn file present in the /config/openvpn directory. Drop a .ovpn file from your VPN provider into /config/openvpn and start the container again. You may need to edit the ovpn configuration file to load your VPN credentials from a file by setting `auth-user-pass`.

**Note:** The script will use the first ovpn file it finds in the /config/openvpn directory. Adding multiple ovpn files will not start multiple VPN connections.

## Example auth-user-pass option for .ovpn files
`auth-user-pass credentials.conf`

## Example credentials.conf
```
username
password
```

## PUID/PGID
User ID (PUID) and Group ID (PGID) can be found by issuing the following command for the user you want to run the container as:

```
id <username>
```

## Known issue IPv6
There is a known issue with VPN providers that support IPv6.  
To workaround this issue, you need to add the folling lines to your .ovpn file:
```
pull-filter ignore 'route-ipv6'
pull-filter ignore 'ifconfig-ipv6'
```
Thanks to [Technikte](https://github.com/Technikte) in [Issue #19](https://github.com/DyonR/docker-Jackettvpn/issues/19).

# Issues
If you are having issues with this container please submit an issue on GitHub.
Please provide logs, docker version and other information that can simplify reproducing the issue.
Using the latest stable verison of Docker is always recommended. Support for older version is on a best-effort basis.

# frp Install Script
This is a simple script to install frp server

frp is a fast reverse proxy to help you expose a local server behind a NAT or firewall to the internet.

It comes from [https://github.com/fatedier/frp](https://github.com/fatedier/frp)

And this script adds a system service to manage Frp more easily.

## Install

```bash
wget --no-check-certificate https://raw.githubusercontent.com/WingLim/frp_install_script/master/frps.sh
chmod +x frps.sh
./frps.sh 2>&1 | tee frps.log
```



## Usage

```bash
systemctl start frps
systemctl stop frps
systemctl status frps
```



## Uninstall

```bash
./frps.sh uninstall
```



## Notice

**This script is tested under CentOS 7 and Ubuntu 18.04.1 LTS**



## Config

There is more config in ``/usr/local/frp/frp/frps_full.ini`` or you can see more in [frps full configuration file](https://github.com/fatedier/frp/blob/master/conf/frps_full.ini)

Where is config?``/usr/local/frp/config/frps.ini``

Where is frp? ``/usr/local/frp``

Where is frps.service? ``/lib/systemd/system/frps.service``



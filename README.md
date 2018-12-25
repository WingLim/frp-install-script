# Frp Install Script
This is a simple script to install frp

Frp is a fast reverse proxy to help you expose a local server behind a NAT or firewall to the internet.

It comes from [https://github.com/fatedier/frp](https://github.com/fatedier/frp)

This script will install frp in ``/usr/local/frp``

And it adds a system service to manage Frp more easily.

It is located at ``/lib/systemd/system/frps.service``

## Notice

**This script is only tested under CentOS 7**



## Usage

```bash
wget --no-check-certificate https://raw.githubusercontent.com/WingLim/frp_install_script/master/frps.sh
chmod +x frps.sh
./frps.sh 2>&1 | tee frps.log
```



## Uninstall

```bash
./frps.sh uninstall
```



## Where is config

``/usr/local/frp/config/frps.ini``



## Start&Stop&Status

```bash
systemctl start frps
systemctl stop frps
systemctl status frps
```
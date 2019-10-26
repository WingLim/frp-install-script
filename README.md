# frps Install Script
一个安装 frp 服务端的脚本

frp 是一个可用于内网穿透的高性能的反向代理应用，支持 tcp, udp 协议，为 http 和 https 应用协议提供了额外的能力，且尝试性支持了点对点穿透。

项目地址： [https://github.com/fatedier/frp](https://github.com/fatedier/frp)

这个脚本是用来安装最新 frp 服务端，并且添加了 systemd service 来管理开关以及自启

**注意：这个脚本只在 CentOS 7 和 Ubuntu 18.04.1 LTS 下测试过**

## 安装

```bash
wget --no-check-certificate https://raw.githubusercontent.com/WingLim/frp_install_script/master/frps.sh
chmod +x frps.sh
./frps.sh 2>&1 | tee frps.log
```

## 配置

配置文件位于 ``/usr/local/frp/config/frps.ini``

想要配置更多内容请参考 [frps full configuration file](https://github.com/fatedier/frp/blob/master/conf/frps_full.ini)

frps 安装在 ``/usr/local/frp``

frps.service 安装在 ``/lib/systemd/system/frps.service``

## 使用

```bash
systemctl start frps
systemctl stop frps
systemctl status frps
```



## 卸载

```bash
./frps.sh uninstall
```

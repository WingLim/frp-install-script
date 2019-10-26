#!/usr/bin/env bash

# Color
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Make sure only root can run our script
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] 当前账号非ROOT(或没有ROOT权限)，无法继续操作!" && exit 1

check_frp_ver(){
	echo -e "开始获取 frp 最新版本..."
	frp_ver=$(wget -qO- "https://github.com/fatedier/frp/tags"|grep "/fatedier/frp/releases/tag/"|head -1|sed -r 's/.*tag\/(.+)\">.*/\1/')
	[[ -z ${frp_ver} ]] && frp_ver=${frp_ver}
	echo -e "frp 最新版本为 ${frp_ver} !"
}

# Download frp
download_frp(){
    check_frp_ver
    frp_ver_name="frp_"$(echo ${frp_ver}|sed -r "s/v//g")"_linux_amd64"
    frp_url=https://github.com/fatedier/frp/releases/download/${frp_ver}/${frp_ver_name}.tar.gz
    if ! wget -P /usr/local ${frp_url}; then
	    echo -e "[${red}Error${plain}] Failed to download ${frp_ver_name}.tar.gz!"
	    exit 1
    fi
}

# Unzip to /usr/local/frp
unzip_frp(){
    tar -xvf /usr/local/${frp_ver_name}.tar.gz -C /usr/local
    rm -rf /usr/local/${frp_ver_name}.tar.gz
    mv /usr/local/${frp_ver_name} /usr/local/frp
}

# Get public IP address
get_ip(){
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    [ ! -z ${IP} ] && echo ${IP} || echo
}

# Configure frp and output frps.ini
pre_install(){
	clear
    mkdir /usr/local/frp/config
    echo -e "Please enter a port for frp:"
    read -p "(Default port: 7000):" bind_port
    [ -z "${bind_port}" ] && bind_port="7000"

    echo -e "Please enter a dashboard port for frp:"
    read -p "(Default dashboard port: 7500):" dashboard_port
    [ -z "${dashboard_port}" ] && dashboard_port="7500"

    echo -e "Please enter a user for dashboard:"
    read -p "(Default user: admin):" dashboard_user
    [ -z "${dashboard_user}" ] && dashboard_user="admin"

    echo -e "Please enter a password for dashboard:"
    read -p "(Default password: admin):" dashboard_pwd
    [ -z "${dashboard_pwd}" ] && dashboard_pwd="admin"
}

# Get version
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}

# 设置 防火墙规则
add_iptables(){
	if [[ ! -z "${bind_port}" && "${dashboard_port}" ]]; then
        iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${bind_port} -j ACCEPT
        iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${dashboard_port} -j ACCEPT
	fi
}
del_iptables(){
	if [[ ! -z "${bind_port}" && "${dashboard_port}" ]]; then
		iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${bind_port} -j ACCEPT
        iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${dashboard_port} -j ACCEPT
	fi
}
save_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
	else
		iptables-save > /etc/iptables.up.rules
	fi
}
set_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		chkconfig --level 2345 iptables on
	else
		iptables-save > /etc/iptables.up.rules
		echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
		chmod +x /etc/network/if-pre-up.d/iptables
	fi
}

# Add frp to system service
add_frp_service(){
    cat > /lib/systemd/system/frps.service<<-EOF
[Unit]
Description=frps - A fast reverse proxy
Documentation=https://github.com/fatedier/frp
After=network.target syslog.target
Wants=network.target

[Service]
Type=simple
ExecStart=/usr/local/frp/frps -c /usr/local/frp/config/frps.ini
ExecStop=/bin/kill -s QUIT \$MAINPID
StandardOutput=syslog

[Install]
WantedBy=multi-user.target
EOF
}
# Install frp
install(){
    cat > /usr/local/frp/config/frps.ini<<-EOF
[common]
bind_port = ${bind_port}
dashboard_port = ${dashboard_port}
dashboard_user = ${dashboard_user}
dashboard_pwd = ${dashboard_pwd}
EOF
    systemctl start frps
    systemctl enable frps

    clear
    echo
    echo -e "Congratulations, frp server install completed!"
    echo -e "Your Server IP          : ${green} $(get_ip) ${plain}"
    echo -e "Your frp Port           : ${green} ${bind_port} ${plain}"
    echo -e "Your Dashboard User     : ${green} ${dashboard_user} ${plain}"
    echo -e "Your Dashboard Password : ${green} ${dashboard_pwd} ${plain}"
    echo -e "Now you can reach Dashboard at ${green}http://$(get_ip):${dashboard_port} ${plain}"
    echo
}

install_frp(){
    download_frp
    unzip_frp
    pre_install
    add_frp_service
    set_iptables
    add_iptables
    save_iptables
    install
}

uninstall_frp(){
    printf "Are you sure uninstall frp? (y/n)"
    printf "\n"
    read -p "(Default: n):" answer
    [ -z ${answer} ] && answer="n"
    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
        systemctl stop frps
        systemctl disable frps
        rm -rf /usr/local/frp
        rm -rf /lib/systemd/system/frps.service
        del_iptables
        save_iptables
        echo "frp uninstall success!"
    else
        echo "Uninstall cancelled, nothing to do..."
    fi
}

# Initialization step
action=$1
[ -z $1 ] && action=install
case "$action" in
    install|uninstall)
        ${action}_frp
        ;;
    *)
        echo "Arguments error! [${action}]"
        echo "Usage: `basename $0` [install|uninstall]"
        ;;
esac

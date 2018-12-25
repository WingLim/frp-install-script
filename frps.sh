#!/usr/bin/env bash

# Color
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Make sure only root can run our script
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] This script must be run as root!" && exit 1

# Download frp
frpurl=https://github.com/fatedier/frp/releases/download/v0.22.0/frp_0.22.0_linux_amd64.tar.gz
frp_v=frp_0.22.0_linux_amd64
download_frp(){
    if ! wget -P /usr/local ${frpurl}; then
	    echo -e "[${red}Error${plain}] Failed to download ${frp_v}.tar.gz!"
	    exit 1
    fi
}

# Unzip to /usr/local/frp
unzip_frp(){
    tar -xvf /usr/local/${frp_v}.tar.gz -C /usr/local
    rm -rf /usr/local/${frp_v}.tar.gz
    mv /usr/local/${frp_v} /usr/local/frp
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
getversion(){
    if [[ -s /etc/redhat-release ]]; then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}

# CentOS version
centosversion(){
    local code=$1
    local version="$(getversion)"
    local main_ver=${version%%.*}
    if [ "$main_ver" == "$code" ]; then
        return 0
    else
        return 1
    fi
}

# Firewall set
firewall_set(){
    echo -e "[${green}Info${plain}] firewall set start..."
    if centosversion 6; then
        /etc/init.d/iptables status > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            iptables -L -n | grep -i ${bind_port} > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${bind_port} -j ACCEPT
                iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${dashboard_port} -j ACCEPT
                /etc/init.d/iptables save
                /etc/init.d/iptables restart
            else
                echo -e "[${green}Info${plain}] port ${bind_port} and ${dashboard_port} has been set up."
            fi
        else
            echo -e "[${yellow}Warning${plain}] iptables looks like shutdown or not installed, please manually set it if necessary."
        fi
    elif centosversion 7; then
        systemctl status firewalld > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            firewall-cmd --permanent --zone=public --add-port=${bind_port}/tcp
            firewall-cmd --permanent --zone=public --add-port=${dashboard_port}/tcp
            firewall-cmd --reload
        else
            echo -e "[${yellow}Warning${plain}] firewalld looks like not running or not installed, please enable port ${shadowsocksport} manually if necessary."
        fi
    fi
    echo -e "[${green}Info${plain}] firewall set completed..."
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

# Install frp
install_frp(){
    download_frp
    unzip_frp
    pre_install
    add_frp_service
    firewall_set
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

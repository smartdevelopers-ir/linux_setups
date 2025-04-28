#!/bin/bash

ssh_attack_blocker(){
iptables -A INPUT -p tcp -m tcp --dport 8522 -m state --state NEW -m recent --set --name DEFAULT --rsource
iptables -N LOG_AND_DROP
iptables -A INPUT  -p tcp -m tcp --dport 8522 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 --name DEFAULT --rsource -j LOG_AND_DROP
iptables -A INPUT  -p tcp -m tcp --dport 8522 -j ACCEPT
iptables -A LOG_AND_DROP -j LOG --log-prefix "iptables deny: " --log-level 7
iptables -A LOG_AND_DROP -j DROP
echo -e ':msg,contains,"iptables deny: " /var/log/iptables.log\n& ~' > /etc/rsyslog.d/iptables.conf
echo -e '/var/log/iptables.log
{
  rotate 7
  daily
  missingok
  notifempty
  delaycompress
  compress
  postrotate
      invoke-rc.d rsyslog reload > /dev/null
  endscript
}' > /etc/logrotate.d/iptables
systemctl restart rsyslog
}
install_xray_usermanage(){
mkdir /opt/javas 2> /dev/null
wget -O /opt/javas/xray-user-manager.jar https://github.com/mostafa3dmax/smart_tunnel/raw/main/xray-user-manager.jar
cat > /usr/local/bin/xray-user-manager <<'EOF'
#!/bin/bash
/bin/java -jar /opt/javas/xray-user-manager.jar "$@"
EOF
chmod 700 /usr/local/bin/xray-user-manager

}
install_smartws(){
APPNAME="smartws"
SERVER_NAME=""
SERVER_PORT=""
while [ -z "$SERVER_NAME" ]; do
	read -p "$Enter server domain : " SERVER_NAME
done
while [ -z "$SERVER_PORT" ]; do
	read -p "$Enter ssh port : " SERVER_PORT
done
# install xray-core
# installed: /etc/systemd/system/xray.service
# installed: /etc/systemd/system/xray@.service
# 
# installed: /usr/local/bin/xray
# installed: /usr/local/etc/xray/*.json
# 
# installed: /usr/local/share/xray/geoip.dat
# installed: /usr/local/share/xray/geosite.dat
# 
# installed: /var/log/xray/access.log
# installed: /var/log/xray/error.log
if ! ls /etc/systemd/system/xray.service &> /dev/null; then
	bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
fi
# download smartws zip and extract it to /opt/smartws/
if ls /tmp/$APPNAME.zip &> /dev/null ; then
	read -p "$APPNAME.zip is already exists. Do you want to download it again ? y(es),n(o)" dowload_zip_again
	if [[ "${dowload_zip_again,,}" == "y" ]] || [[ "${dowload_zip_again,,}" == "yes" ]]; then
		wget -O /tmp/$APPNAME.zip https://github.com/mostafa3dmax/smart_tunnel/raw/main/smartws.zip
	fi
else
	wget -O /tmp/$APPNAME.zip https://github.com/mostafa3dmax/smart_tunnel/raw/main/smartws.zip
fi

rm -r /opt/$APPNAME &> /dev/null
unzip /tmp/$APPNAME.zip -d /opt/$APPNAME 1> /dev/null
chown root /opt/$APPNAME
# make config folder
mkdir /etc/opt/$APPNAME &> /dev/null

# copy smartws config to /opt/$APPNAME/config/
if ls /etc/opt/$APPNAME/config &> /dev/null; then
	read -p "$APPNAME config file is already exists. Do you want reaplace it ? y(es),n(o)" replace_config
	if [[ "${replace_config,,}" == "y" ]] || [[ "${replace_config,,}" == "yes" ]]; then
		cp /opt/$APPNAME/config/config /etc/opt/$APPNAME/config
	fi
else
	cp /opt/$APPNAME/config/config /etc/opt/$APPNAME/config
fi
cp /opt/$APPNAME/config/limited /etc/opt/$APPNAME/limited

# copy xray config to /usr/local/etc/xray/*
cp /opt/$APPNAME/config/xray_config.json /usr/local/etc/xray/config.json

# link new smartws script to /usr/local/bin
ln -f -s /opt/$APPNAME/script/smartws /usr/local/bin/smartws
ln -f -s /opt/$APPNAME/script/smartws_add_plan /usr/local/bin/smartws_add_plan
ln -f -s /opt/$APPNAME/script/smartws_change_plan /usr/local/bin/smartws_change_plan
ln -f -s /opt/$APPNAME/script/smartws_delete_plan /usr/local/bin/smartws_delete_plan
ln -f -s /opt/$APPNAME/script/smartws_shutdown /usr/local/bin/smartws_shutdown
ln -f -s /opt/$APPNAME/script/smartws_delete_user /usr/local/bin/smartws_delete_user
ln -f -s /opt/$APPNAME/script/smartws_get_plans /usr/local/bin/smartws_get_plans
ln -f -s /opt/$APPNAME/script/smartws_online_users /usr/local/bin/smartws_online_users
chmod +x /usr/local/bin/smartws
chmod +x /usr/local/bin/smartws_add_plan
chmod +x /usr/local/bin/smartws_change_plan
chmod +x /usr/local/bin/smartws_delete_plan
chmod +x /usr/local/bin/smartws_shutdown
chmod +x /usr/local/bin/smartws_delete_user
chmod +x /usr/local/bin/smartws_get_plans
chmod +x /usr/local/bin/smartws_online_users
chown root /usr/local/bin/smartws
chown root /usr/local/bin/smartws_add_plan
chown root /usr/local/bin/smartws_change_plan
chown root /usr/local/bin/smartws_delete_plan
chown root /usr/local/bin/smartws_shutdown
chown root /usr/local/bin/smartws_delete_user
chown root /usr/local/bin/smartws_get_plans
chown root /usr/local/bin/smartws_online_users
groupadd smartws 2> /dev/null
ln -f -s /opt/$APPNAME/service/smartws.service /etc/systemd/system/smartws.service
ln -f -s /opt/$APPNAME/service/smartws@.service /etc/systemd/system/smartws@.service
# copy nginx config
cp /opt/$APPNAME/config/nginx/nginx_config /etc/nginx/sites-available/$SERVER_NAME
mkdir /etc/nginx/locations
cp /opt/$APPNAME/config/nginx/locations/domain /etc/nginx/locations/$SERVER_NAME
cp /opt/$APPNAME/config/nginx/locations/ws /etc/nginx/locations/ws
# change nginx config 
sed -i -e 's#sh3.goolha.tk#'$SERVER_NAME'#' /etc/nginx/sites-available/$SERVER_NAME
echo "nginx config updated"

# modify xray service user
sed -i -e 's/User=nobody/User=root/' /etc/systemd/system/xray.service
echo "xray service user updated"
# change smartws config parameters 
sed -i -e 's#"port": 2232#"port": '"$SERVER_PORT"'#' /etc/opt/$APPNAME/config
sed -i -e 's#"port": 2232#"port": '"$SERVER_PORT"'#' /etc/opt/$APPNAME/limited
sed -i -e 's#"sh3.goolha.tk#'"$SERVER_NAME"'#' /etc/opt/$APPNAME/config
sed -i -e 's#"sh3.goolha.tk#'"$SERVER_NAME"'#' /etc/opt/$APPNAME/limited
ln -s /etc/nginx/sites-available/$SERVER_NAME /etc/nginx/sites-enabled/$SERVER_NAME
echo "smartws config updated"
comment_nginx_ssl
certbot certonly --nginx
uncomment_nginx_ssl
systemctl daemon-reload

rm /tmp/$APPNAME.zip
systemctl enable smartws.service
systemctl enable smartws@limited.service
systemctl stop smartws.service
systemctl start smartws.service
systemctl start smartws@limited.service
systemctl enable xray.service
systemctl stop xray.service
systemctl start xray.service
systemctl restart nginx.service
}
comment_nginx_ssl(){

sed -i -e 's@listen [::]:8443 ssl ipv6@listen [::]:8443 ipv6@' /etc/nginx/sites-available/$SERVER_NAME
sed -i -e 's@listen 8443 ssl;@listen 8443 ;@' /etc/nginx/sites-available/$SERVER_NAME
sed -i -e 's@ssl_certificate@#ssl_certificate@' /etc/nginx/sites-available/$SERVER_NAME
sed -i -e 's@ssl_certificate_key@#ssl_certificate_key@' /etc/nginx/sites-available/$SERVER_NAME
sed -i -e 's@include /etc/letsencrypt@#include /etc/letsencrypt@' /etc/nginx/sites-available/$SERVER_NAME
sed -i -e 's@ssl_dhparam@#ssl_dhparam@' /etc/nginx/sites-available/$SERVER_NAME
}
uncomment_nginx_ssl(){
sed -i -e 's@listen [::]:8443 ipv6@listen [::]:8443 ssl ipv6@' /etc/nginx/sites-available/$SERVER_NAME
sed -i -e 's@listen 8443 ;@listen 8443 ssl;@' /etc/nginx/sites-available/$SERVER_NAME
sed -i -e 's@#ssl_certificate@ssl_certificate@' /etc/nginx/sites-available/$SERVER_NAME
sed -i -e 's@#ssl_certificate_key@ssl_certificate_key@' /etc/nginx/sites-available/$SERVER_NAME
sed -i -e 's@#include /etc/letsencrypt@include /etc/letsencrypt@' /etc/nginx/sites-available/$SERVER_NAME
sed -i -e 's@#ssl_dhparam@ssl_dhparam@' /etc/nginx/sites-available/$SERVER_NAME
}
disable_ssh_tty(){
cat >> /etc/ssh/sshd_config << 'EOF'
Match Group twologin
        PermitTTY no
Match Group threelogin
        PermitTTY no
Match Group noexpire
        PermitTTY no
Match Group onelogin
		PermitTTY no
EOF
}
install_lock_user_script(){
cat > /usr/local/bin/lock_user << 'EOF'
#! /bin/bash
kill_proc(){
local username=$1
PIDS_STRING=$(ps -C dropbear | grep dropbear | awk '{print $1}');
PID_ARRAY=($PIDS_STRING);
declare -A USERS
for i in ${PID_ARRAY[@]}
do
	LINE=$(grep -a "\\[$i\\]" /var/log/auth.log | awk '/Password auth succeeded for/{print}')
	TMP_USER=$(echo "$LINE" | awk '{print $10}')
	if [[ ! -z $TMP_USER ]]
	then
		#remove single cotation from user name and put to users array
		USERS["$i"]="${TMP_USER//[^a-zA-Z0-9_]/''}"
	fi
	
done
PIDS_STRING="${!USERS[*]}"
SORTED_PIDS=($(echo -e "${PIDS_STRING//' '/'\n'}" | sort -n))
#echo "SORTED_PIDS = " "${SORTED_PIDS[@]}"
for PID in ${SORTED_PIDS[@]}
do
	#echo "current pid = $PID"
	usr=${USERS[$PID]}
	if [[ "$usr" == "$username" ]]
	then
		kill $PID
		unset USERS[$PID]
	fi
	
done
}
lock_user(){
USERNAME=$1
if [[ "$USERNAME" == "root" ]]; then
	return 1
fi
sudo usermod -L $USERNAME
XRAY_COUNT=$(/usr/local/bin/xray-user-manager -lock "$USERNAME")
if [[ $XRAY_COUNT -gt 0 ]]; then
systemctl restart xray;
fi
kill_proc "$USERNAME"
}

lock_user "$1"

EOF
}

install_unlock_user_script(){
cat > /usr/local/bin/unlock_user << 'EOF'
#! /bin/bash
unlock_user(){
USERNAME=$1
if [[ "$USERNAME" == "root" ]]; then
	return 1
fi
sudo usermod -U $USERNAME
XRAY_COUNT=$(/usr/local/bin/xray-user-manager -unlock "$USERNAME")
if [[ $XRAY_COUNT -gt 0 ]]; then
systemctl restart xray;
fi

}
unlock_user "$1"
EOF
}

apt update
apt upgrade -y
timedatectl set-timezone Asia/Tehran
apt install vim -y
apt install inotify-tools -y
apt install dropbear -y
apt install ufw -y
ssh_attack_blocker
apt install iptables-persistent -y
apt install dante-server -y
apt install nginx -y
apt install snapd -y
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot
apt install openjdk-17-jre-headless -y
install_smartws
install_xray_usermanage
wget -O /usr/local/bin/banner "https://raw.githubusercontent.com/smartdevelopers-ir/linux_setups/main/banner.html"
chmod 755 /usr/local/bin/banner
read -p "Enter Dropbear port : " D_PORT
sed -i -e 's/^NO_START=1$/NO_START=0/' -e 's/DROPBEAR_PORT=22/DROPBEAR_PORT=442/' -e 's#DROPBEAR_BANNER=""#DROPBEAR_BANNER="/usr/local/bin/banner"#' -e 's/^DROPBEAR_EXTRA_ARGS=$/DROPBEAR_EXTRA_ARGS="-g -k -p '"$D_PORT"'"/' /etc/default/dropbear
ufw allow 442
ufw allow $D_PORT
systemctl enable --now dropbear
systemctl start dropbear
groupadd twologin
groupadd threelogin
groupadd onelogin
groupadd noexpire
echo -e "@twologin\t-\tmaxlogins\t2" >>  /etc/security/limits.conf
disable_ssh_tty
systemctl restart sshd
systemctl restart dropbear
#install screen and badvpn-udpgw
apt install screen -y
OS=`uname -m`;
if [[ "$OS" = "x86_64" ]]
then
  wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/daybreakersx/premscript/master/badvpn-udpgw64"
else
	wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/daybreakersx/premscript/master/badvpn-udpgw"
fi
touch /usr/local/bin/startup.sh
chmod 755 /usr/local/bin/startup.sh
chmod +x /usr/local/bin/startup.sh
echo '#!/bin/bash' > /usr/local/bin/startup.sh
echo -e "screen -AmdS badvpn7300 badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 100" >> /usr/local/bin/startup.sh
echo -e "screen -AmdS badvpn7500 badvpn-udpgw --listen-addr 127.0.0.1:7500 --max-clients 100" >> /usr/local/bin/startup.sh
# echo -e "screen -AmdS expire_date_reporter java -jar  /usr/local/bin/acc_expire_reporter.jar --allow 127.0.0.1,5.45.64.41 6161" >> /usr/local/bin/startup.sh
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn7300 badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 100
screen -AmdS badvpn7500 badvpn-udpgw --listen-addr 127.0.0.1:7500 --max-clients 100
# add dropbear login watcher script to /usr/local/bin/startup.sh
echo -e "screen -AmdS loginwatcher bash /usr/local/bin/ssh_login_watcher.sh" >> /usr/local/bin/startup.sh

#Download and put ssh_login_watcher.sh in /user/local/bin
wget -O /usr/local/bin/ssh_login_watcher.sh "https://raw.githubusercontent.com/smartdevelopers-ir/linux_setups/main/ssh_login_watcher.sh"
chmod +x /usr/local/bin/ssh_login_watcher.sh
chmod 755 /usr/local/bin/ssh_login_watcher.sh
#Download ssh_session_check.sh to /usr/local/bin/
wget -O /usr/local/bin/ssh_session_check.sh "https://raw.githubusercontent.com/smartdevelopers-ir/linux_setups/main/ssh_session_check.sh"
chmod +x /usr/local/bin/ssh_session_check.sh
chmod 755 /usr/local/bin/ssh_session_check.sh
#Run ssh_session_watcher in screen
screen -AmdS loginwatcher bash /usr/local/bin/ssh_login_watcher.sh
#Add job to crontab for run at startup
if ! crontab -l | grep "@reboot bash /usr/local/bin/startup.sh" 
then
	(crontab -l ; echo "@reboot bash /usr/local/bin/startup.sh") | crontab -
fi
if ! crontab -l | grep "/usr/local/bin/acc_expire_check" 
then
	(crontab -l ; echo "/usr/local/bin/acc_expire_check") | crontab -
fi
if ! crontab -l | grep "/usr/local/bin/login_watcher_running_check" 
then
	(crontab -l ; echo "15 0 * * * bash /usr/local/bin/login_watcher_running_check") | crontab -
fi

#install easymesh
bash <(curl -Ls --ipv4 https://github.com/Musixal/easy-mesh/raw/main/easymesh_v2.sh)

service cron restart
#add userpass script for simplly add user
mkdir /etc/acc-expire
wget -O /usr/local/bin/userpass "https://raw.githubusercontent.com/smartdevelopers-ir/linux_setups/main/userpass"
chmod +x /usr/local/bin/userpass
chmod 755 /usr/local/bin/userpass
wget -O /usr/local/bin/acc_expire_check "https://raw.githubusercontent.com/smartdevelopers-ir/linux_setups/main/acc_expire_check"
chmod +x /usr/local/bin/acc_expire_check
chmod 755 /usr/local/bin/acc_expire_check
wget -O /usr/local/bin/update_acc_expire "https://raw.githubusercontent.com/smartdevelopers-ir/linux_setups/main/update_acc_expire"
chmod +x /usr/local/bin/update_acc_expire
chmod 755 /usr/local/bin/update_acc_expire
# block IR spy aplications
wget -O /usr/local/bin/spy_net_blocker "https://raw.githubusercontent.com/smartdevelopers-ir/linux_setups/main/spy_net_blocker"
chmod +x /usr/local/bin/spy_net_blocker
chmod 755 /usr/local/bin/spy_net_blocker
bash /usr/local/bin/spy_net_blocker
# login watcher runnin check
wget -O /usr/local/bin/login_watcher_running_check "https://raw.githubusercontent.com/smartdevelopers-ir/linux_setups/main/login_watcher_running_check"
chmod +x /usr/local/bin/login_watcher_running_check
chmod 755 /usr/local/bin/login_watcher_running_check
# dante proxy server config
systemctl stop danted
wget -O /etc/danted.conf "https://raw.githubusercontent.com/smartdevelopers-ir/linux_setups/main/danted.conf"
systemctl start danted
# ncat - expire date reporter
wget -O /usr/local/bin/edr "https://raw.githubusercontent.com/smartdevelopers-ir/linux_setups/main/expire_date_reported.sh"
chmod +x /usr/local/bin/edr
chmod 755 /usr/local/bin/edr
# lock_user_script
install_lock_user_script
chmod +x /usr/local/bin/lock_user
chmod 755 /usr/local/bin/lock_user
# unlock_user_script
install_unlock_user_script
chmod +x /usr/local/bin/unlock_user
chmod 755 /usr/local/bin/unlock_user

#screen -AmdS expire_date_reporter ncat -k -l 127.0.0.1 6161 -c 'bash /usr/local/bin/edr'

# acc_axpire_reporter jar file
# wget -O /usr/local/bin/acc_expire_reporter.jar "https://raw.githubusercontent.com/smartdevelopers-ir/linux_setups/main/acc_expire_reporter.jar"
# screen -AmdS expire_date_reporter java -jar  /usr/local/bin/acc_expire_reporter.jar --allow 127.0.0.1,5.45.64.41 6161

# acc_axpire_reporter python file
wget -O /usr/local/bin/acc_expire_reporter.py "https://raw.githubusercontent.com/smartdevelopers-ir/linux_setups/main/acc_expire_reporter.py"
chmod 755 /usr/local/bin/acc_expire_reporter.py
# acc_axpire_reporter service
wget -O /etc/systemd/system/acc-expire-reporter.service "https://raw.githubusercontent.com/smartdevelopers-ir/linux_setups/main/acc-expire-reporter.service"
systemctl daemon-reload
systemctl enable acc-expire-reporter.service
systemctl start acc-expire-reporter.service


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
# apt install openjdk-17-jre-headless -y
wget -O /usr/local/bin/banner "https://raw.githubusercontent.com/smartdevelopers-ir/linux_setups/main/banner.html"
chmod 755 /usr/local/bin/banner
read -p "Enter Dropbear port : " D_PORT
sed -i -e 's/^NO_START=1$/NO_START=0/' -e 's/DROPBEAR_PORT=22/DROPBEAR_PORT=442/' -e 's#DROPBEAR_BANNER=""#DROPBEAR_BANNER="/usr/local/bin/banner"#' -e 's/^DROPBEAR_EXTRA_ARGS=$/DROPBEAR_EXTRA_ARGS="-g -p '"$D_PORT"'"/' /etc/default/dropbear
ufw allow 442
ufw allow $D_PORT
systemctl enable --now dropbear
systemctl start dropbear
groupadd twologin
echo -e "@twologin\t-\tmaxlogins\t2" >>  /etc/security/limits.conf
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
if ! crontab -l | grep "0 0 * * * bash /usr/local/bin/acc_expire_check" 
then
	(crontab -l ; echo "0 0 * * * bash /usr/local/bin/acc_expire_check") | crontab -
fi
if ! crontab -l | grep "0 0 * * * bash /usr/local/bin/login_watcher_running_check" 
then
	(crontab -l ; echo "0 0 * * * bash /usr/local/bin/login_watcher_running_check") | crontab -
fi

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


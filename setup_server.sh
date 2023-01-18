#!/bin/sh
apt update
apt upgrade -y
apt install vim -y
apt install inotify-tools -y
apt install dropbear -y
apt install ufw -y
wget -O /usr/local/bin/banner "https://raw.githubusercontent.com/smartdevelopers-ir/linux_setups/main/banner.html"
chmod 755 /usr/local/bin/banner
sed -i -e 's/^NO_START=1$/NO_START=0/' -e 's/DROPBEAR_PORT=22/DROPBEAR_PORT=442/' -e 's#DROPBEAR_BANNER=""#DROPBEAR_BANNER="/usr/local/bin/banner"#' -e 's/^DROPBEAR_EXTRA_ARGS=$/DROPBEAR_EXTRA_ARGS="-g"/' /etc/default/dropbear
ufw allow 442
systemctl enable --now dropbear
systemctl start dropbear
groupadd twologin
echo -e "@twologin\t-\tmaxlogins\t2" >>  /etc/security/limits.conf
systemctl restart sshd
systemctl restart dropbear
#install screen and badvpn-udpgw
apt install screen -y
OS=`uname -m`;
if [ "$OS" == "x86_64" ]
then
  wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/daybreakersx/premscript/master/badvpn-udpgw64"
else
	wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/daybreakersx/premscript/master/badvpn-udpgw"
fi
touch /usr/local/bin/startup.sh
chmod 755 /usr/local/bin/startup.sh
chmod +x /usr/local/bin/startup.sh
echo '#!/bin/sh' > /usr/local/bin/startup.sh
echo -e "screen -AmdS badvpn7300 badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 100" >> /usr/local/bin/startup.sh
echo -e "screen -AmdS badvpn7500 badvpn-udpgw --listen-addr 127.0.0.1:7500 --max-clients 100" >> /usr/local/bin/startup.sh
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn7300 badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 100
screen -AmdS badvpn7500 badvpn-udpgw --listen-addr 127.0.0.1:7500 --max-clients 100
# add dropbear login watcher script to /usr/local/bin/startup.sh
echo -e "screen -AmdS login_watcher bash /usr/local/bin/ssh_login_watcher.sh" >> /usr/local/bin/startup.sh

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
(crontab -l 2>/dev/null; echo "@reboot bash /usr/local/bin/startup.sh") | crontab -

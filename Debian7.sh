#
#!/bin/bash
#

ipAddress=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
if [[ "$ipAddress" = "" ]]; then
	ipAddress=$(wget -qO- ipv4.icanhazip.com)
fi

cd ~

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# set time GMT +8
ln -fs /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime

# sources list
wget -O /etc/apt/sources.list "https://raw.githubusercontent.com/zero9911/vps/master/Configs/sources.list"
wget "http://www.dotdeb.org/dotdeb.gpg"1
wget "http://www.webmin.com/jcameron-key.asc"
apt-key add dotdeb.gpg && rm dotdeb.gpg
apt-key add jcameron.asc && rm jcameron.asc

# remove unused
apt-get -y purge samba && apt-get -y purge apache2 && apt-get -y purge sendmail && apt-get -y purge bind9 && apt-get -y purge exim4
apt-get -y autoremove

# update
apt-get update && apt-get -y upgrade

# install essential package
apt-get -y install openvpn && apt-get -y install dropbear && apt-get -y install squid3 && apt-get -y install fail2ban && apt-get -y install webmin && apt-get -y install nginx && apt-get -y install php5-fpm && apt-get -y install php5-cli
apt-get -y install iptables && apt-get -y install htop && apt-get -y install slurm && apt-get -y install zlib1g-dev
apt-get -y install build-essential

# update zLib
~# wget "https://raw.githubusercontent.com/zero9911/vps/master/Pakages/zlib-1.2.11.tar.gz"
~# tar -xf zlib-1.2.11.tar.gz
~# cd zlib-1.2.11
~# ./configure --prefix=/usr ----sysconfdir=/usr/include && make && make install

# update OpenSSL
wget "https://raw.githubusercontent.com/zero9911/vps/master/Pakages/openssl-1.1.0f.tar.gz"
tar -xf openssl-1.1.0f.tar.gz
cd openssl-1.1.0f
./configure --prefix=/usr --sysconfdir=/etc/ssl --libdir=lib && make && make test && make install
make MANSUFFIX=ssl install && mv -v /usr/share/doc/openssl{,-1.1.0f} && cp -vfr doc/* /usr/share/doc/openssl-1.1.0f

# update OpenSSH
wget "https://raw.githubusercontent.com/zero9911/vps/master/Pakages/openssh-7.5p1-openssl-1.1.0-1.patch"
wget "https://raw.githubusercontent.com/zero9911/vps/master/Pakages/openssh-7.5p1.tar.gz"
tar -xf openssh-7.5p1.tar.gz
cd openssh-7.5p1
patch -Np1 -i ../openssh-7.5p1-openssl-1.1.0-1.patch && ./configure --prefix=/usr --sysconfdir=/etc/ssh --with-md5-passwords && make && make install
# configure ssh
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
sed -i 's/Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 2020' /etc/ssh/sshd_config

# configure openvpn server
wget -O /etc/openvpn/openvpn.tar "https://raw.githubusercontent.com/zero9911/vps/master/Configs/vpnKeys.tar"
cd /etc/openvpn/
tar xf openvpn.tar
wget -O /etc/openvpn/server.conf "https://raw.githubusercontent.com/zero9911/vps/master/Configs/vpnServer.conf"
service openvpn restart
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
# configure openvpn client
cd /etc/openvpn/
wget -O /etc/openvpn/client.ovpn "https://raw.githubusercontent.com/zero9911/vps/master/Configs/vpnClient.conf"
sed -i $ipAddress /etc/openvpn/client.ovpn
cp client.ovpn /home/mksshvpn.my/public_html/

#update DropBear
wget https://matt.ucc.asn.au/dropbear/releases/dropbear-2017.75.tar.bz2
bzip2 -cd dropbear-2017.75.tar.bz2  | tar xvf -
cd dropbear-2017.75
./configure && make && make install
mv /usr/sbin/dropbear /usr/sbin/dropbear1
ln /usr/local/sbin/dropbear /usr/sbin/dropbear
service dropbear restart
# configure dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=443/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 4343"/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells

# configure squid3
wget -O /etc/squid3/squid.conf "https://raw.githubusercontent.com/zero9911/vps/master/Configs/squid3.conf"
sed -i $ipAddress /etc/squid3/squid.conf

# configure webserver
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/zero9911/vps/master/Configs/nginx.conf"
mkdir -p /home/mksshvpn.my/public_html
echo "<pre>MKSSHVPN | @mk_let</pre>" > /home/mksshvpn.my/public_html/index.html
echo "<?php phpinfo(); ?>" > /home/mksshvpn.my/public_html/info.php
wget -O /etc/nginx/conf.d/domain.conf "https://raw.githubusercontent.com/zero9911/vps/master/Configs/domain.conf"
sed -i 's/listen = \/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/g' /etc/php5/fpm/pool.d/www.conf
chown -R www-data:www-data /home/mksshvpn.my/public_html

# configure webmin
sed -i 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf

# Instal & configure DDOS Flate
if [ -d '/usr/local/ddos' ]; then
	echo "Please un-install the previous version first"
	exit 0
else
	mkdir /usr/local/ddos
fi
wget -q -O /usr/local/ddos/ddos.conf http://www.inetbase.com/scripts/ddos/ddos.conf
wget -q -O /usr/local/ddos/ignore.ip.list http://www.inetbase.com/scripts/ddos/ignore.ip.list
wget -q -O /usr/local/ddos/ddos.sh http://www.inetbase.com/scripts/ddos/ddos.sh
chmod 0755 /usr/local/ddos/ddos.sh
cp -s /usr/local/ddos/ddos.sh /usr/local/sbin/ddos
/usr/local/ddos/ddos.sh --cron > /dev/null 2>&1

# Configure Iptables
iptables -t nat -I POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

## Drop torrents
iptables -A OUTPUT -p tcp --dport 6881:6889 -j DROP
iptables -A OUTPUT -p udp --dport 1024:65534 -j DROP

## Set more radius (alt) ports
iptables -l INPUT -p udp --dport 1645 -j ACCEPT
iptables -l INPUT -p udp --dport 1646 -j ACCEPT

## Try torrent name filters
iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP

## Trying forward
iptables -A FORWARD -p tcp --dport 6881:6889 -j DROP
iptables -A FORWARD -p udp --dport 1024:65534 -j DROP

## Found on web
iptables -N LOGDROP > /dev/null 2> /dev/null
iptables -F LOGDROP
iptables -A LOGDROP -j DROP

## Torrent
iptables -D FORWARD -m string --algo bm --string "BitTorrent" -j LOGDROP
iptables -D FORWARD -m string --algo bm --string "BitTorrent protocol" -j LOGDROP
iptables -D FORWARD -m string --algo bm --string "peer_id" -j LOGDROP
iptables -D FORWARD -m string --algo bm --string ".torrent" -j LOGDROP
iptables -D FORWARD -m string --algo bm --string "announce.php?passkey=" -j LOGDROP
iptables -D FORWARD -m string --algo bm --string "torrent" -j LOGDROP
iptables -D FORWARD -m string --algo bm --string "announce" -j LOGDROP
iptables -D FORWARD -m string --algo bm --string "info_hash" -j LOGDROP

## DHT keyword
iptables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
iptables -A FORWARD -m string --string "announce_peer" --algo bm -j LOGDROP
iptables -A FORWARD -m string --string "find_node" --algo bm -j LOGDROP

## Modified debian commands
iptables -A FORWARD -p udp -m string --algo bm --string "BitTorrent" -j DROP
iptables -A FORWARD -p udp -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -A FORWARD -p udp -m string --algo bm --string "peer_id" -j DROP
iptables -A FORWARD -p udp -m string --algo bm --string ".torrent" -j DROP
iptables -A FORWARD -p udp -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -A FORWARD -p udp -m string --algo bm --string "torrent" -j DROP
iptables -A FORWARD -p udp -m string --algo bm --string "announce" -j DROP
iptables -A FORWARD -p udp -m string --algo bm --string "info_hash" -j DROP
iptables -A FORWARD -p udp -m string --algo bm --string "tracker" -j DROP

iptables -A INPUT -p udp -m string --algo bm --string "BitTorrent" -j DROP
iptables -A INPUT -p udp -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -A INPUT -p udp -m string --algo bm --string "peer_id" -j DROP
iptables -A INPUT -p udp -m string --algo bm --string ".torrent" -j DROP
iptables -A INPUT -p udp -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -A INPUT -p udp -m string --algo bm --string "torrent" -j DROP
iptables -A INPUT -p udp -m string --algo bm --string "announce" -j DROP
iptables -A INPUT -p udp -m string --algo bm --string "info_hash" -j DROP
iptables -A INPUT -p udp -m string --algo bm --string "tracker" -j DROP

iptables -l INPUT -p udp -m string --algo bm --string "BitTorrent" -j DROP
iptables -l INPUT -p udp -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -l INPUT -p udp -m string --algo bm --string "peer_id" -j DROP
iptables -l INPUT -p udp -m string --algo bm --string ".torrent" -j DROP
iptables -l INPUT -p udp -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -l INPUT -p udp -m string --algo bm --string "torrent" -j DROP
iptables -l INPUT -p udp -m string --algo bm --string "announce" -j DROP
iptables -l INPUT -p udp -m string --algo bm --string "info_hash" -j DROP
iptables -l INPUT -p udp -m string --algo bm --string "tracker" -j DROP

iptables -D INPUT -p udp -m string --algo bm --string "BitTorrent" -j DROP
iptables -D INPUT -p udp -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -D INPUT -p udp -m string --algo bm --string "peer_id" -j DROP
iptables -D INPUT -p udp -m string --algo bm --string ".torrent" -j DROP
iptables -D INPUT -p udp -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -D INPUT -p udp -m string --algo bm --string "torrent" -j DROP
iptables -D INPUT -p udp -m string --algo bm --string "announce" -j DROP
iptables -D INPUT -p udp -m string --algo bm --string "info_hash" -j DROP
iptables -D INPUT -p udp -m string --algo bm --string "tracker" -j DROP

iptables -l OUTPUT -p udp -m string --algo bm --string "BitTorrent" -j DROP
iptables -l OUTPUT -p udp -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -l OUTPUT -p udp -m string --algo bm --string "peer_id" -j DROP
iptables -l OUTPUT -p udp -m string --algo bm --string ".torrent" -j DROP
iptables -l OUTPUT -p udp -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -l OUTPUT -p udp -m string --algo bm --string "torrent" -j DROP
iptables -l OUTPUT -p udp -m string --algo bm --string "announce" -j DROP
iptables -l OUTPUT -p udp -m string --algo bm --string "info_hash" -j DROP
iptables -l OUTPUT -p udp -m string --algo bm --string "tracker" -j DROP

## Delete
iptables -D INPUT -m string --algo bm --string "BitTorrent" -j DROP
iptables -D INPUT -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -D INPUT -m string --algo bm --string "peer_id" -j DROP
iptables -D INPUT -m string --algo bm --string ".torrent" -j DROP
iptables -D INPUT -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -D INPUT -m string --algo bm --string "torrent" -j DROP
iptables -D INPUT -m string --algo bm --string "announce" -j DROP
iptables -D INPUT -m string --algo bm --string "info_hash" -j DROP
iptables -D INPUT -m string --algo bm --string "tracker" -j DROP

iptables -D OUTPUT -m string --algo bm --string "BitTorrent" -j DROP
iptables -D OUTPUT -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -D OUTPUT -m string --algo bm --string "peer_id" -j DROP
iptables -D OUTPUT -m string --algo bm --string ".torrent" -j DROP
iptables -D OUTPUT -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -D OUTPUT -m string --algo bm --string "torrent" -j DROP
iptables -D OUTPUT -m string --algo bm --string "announce" -j DROP
iptables -D OUTPUT -m string --algo bm --string "info_hash" -j DROP
iptables -D OUTPUT -m string --algo bm --string "tracker" -j DROP

iptables -D FORWARD -m string --algo bm --string "BitTorrent" -j DROP
iptables -D FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -D FORWARD -m string --algo bm --string "peer_id" -j DROP
iptables -D FORWARD -m string --algo bm --string ".torrent" -j DROP
iptables -D FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -D FORWARD -m string --algo bm --string "torrent" -j DROP
iptables -D FORWARD -m string --algo bm --string "announce" -j DROP
iptables -D FORWARD -m string --algo bm --string "info_hash" -j DROP
iptables -D FORWARD -m string --algo bm --string "tracker" -j DROP

iptables-save > /etc/newIptables.conf
wget -O /etc/network/if-up.d/iptables "https://raw.githubusercontent.com/zero9911/vps/master/Configs/iptables"
chmod +x /etc/network/if-up.d/iptables

# command script
wget -O /usr/bin/menu "https://raw.githubusercontent.com/zero9911/vps/master/bashScripts/mainMenu.sh"
wget -O /usr/bin/01 "https://raw.githubusercontent.com/zero9911/vps/master/bashScripts/trialUserAccount.sh"
wget -O /usr/bin/02 "https://raw.githubusercontent.com/zero9911/vps/master/bashScripts/genAccount.sh"
wget -O /usr/bin/03 "https://raw.githubusercontent.com/zero9911/vps/master/bashScripts/CreateUSerAccount.sh"
wget -O /usr/bin/04 "https://raw.githubusercontent.com/zero9911/vps/master/bashScripts/renewUserAccount.sh"
wget -O /usr/bin/05 "https://raw.githubusercontent.com/zero9911/vps/master/bashScripts/changePasswordAccount.sh"
wget -O /usr/bin/06 "https://raw.githubusercontent.com/zero9911/vps/master/bashScripts/LockUserAccount.sh"
wget -O /usr/bin/07 "https://raw.githubusercontent.com/zero9911/vps/master/bashScripts/unlockUserAccount.sh"
wget -O /usr/bin/08 "https://raw.githubusercontent.com/zero9911/vps/master/bashScripts/deleteUserAccount.sh"
wget -O /usr/bin/09 "https://raw.githubusercontent.com/zero9911/vps/master/bashScripts/listAccounts.sh"
wget -O /usr/bin/10 "https://raw.githubusercontent.com/zero9911/vps/master/bashScripts/OnlineUserAccounts.sh"
wget -O /usr/bin/11 "https://raw.githubusercontent.com/zero9911/vps/master/bashScripts/monitorBandwidth.sh"
wget -O /usr/bin/12 "https://raw.githubusercontent.com/zero9911/vps/master/bashScripts/monitorServerPerformance.sh"
wget -O /usr/bin/13 "https://raw.githubusercontent.com/zero9911/vps/master/bashScripts/speedTest.sh"
wget -O /usr/bin/14 "https://raw.githubusercontent.com/zero9911/vps/master/bashScripts/detailsServerVPS.sh"
wget -O /usr/bin/15 "https://raw.githubusercontent.com/zero9911/vps/master/bashScripts/servicesRestart.sh"

chmod +x /usr/bin/menu
chmod +x /usr/bin/01
chmod +x /usr/bin/02
chmod +x /usr/bin/03
chmod +x /usr/bin/04
chmod +x /usr/bin/05
chmod +x /usr/bin/06
chmod +x /usr/bin/07
chmod +x /usr/bin/08
chmod +x /usr/bin/09
chmod +x /usr/bin/10
chmod +x /usr/bin/11
chmod +x /usr/bin/12
chmod +x /usr/bin/13
chmod +x /usr/bin/14

# restart pakages service
service ssh restart
service openvpn restart
service dropbear restart
service squid3 restart
service fail2ban restart
service nginx restart
service php-fpm restart
service webmin restart

rm -f /root/debian7.sh

# final step
echo "You need [reboot] your server to complete this setup."

echo "###################################"
echo "MKSSHVPN | @mk_let"
echo "###################################"

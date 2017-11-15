#
#!/bin/bash
#upgrade dropbear 2017
#

cd ~
#apt-get -y install zlib1g-dev #If you have Error with the installation, you need to install this pakage first. and start installing dropbear again.
wget https://matt.ucc.asn.au/dropbear/releases/dropbear-2017.75.tar.bz2
bzip2 -cd dropbear-2017.75.tar.bz2  | tar xvf -
cd dropbear-2017.75
./configure && make && make install
mv /usr/sbin/dropbear /usr/sbin/dropbear1
ln /usr/local/sbin/dropbear /usr/sbin/dropbear
service dropbear restart
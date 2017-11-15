#
#!/bin/sh
#upgrade OpenSSH 7.5
#

# OpenSSH 7.5p1
cd ~
wget http://www.linuxfromscratch.org/patches/blfs/svn/openssh-7.5p1-openssl-1.1.0-1.patch
wget http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-7.5p1.tar.gz
tar -xf openssh-7.5p1.tar.gz
cd openssh-7.5p1
patch -Np1 -i ../openssh-7.5p1-openssl-1.1.0-1.patch && ./configure --prefix=/usr --sysconfdir=/etc/ssh --with-md5-passwords && make && make install

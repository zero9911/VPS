#
#!/bin/sh
#upgrade OpenSSL
#

# OpenSSL 1.1.0f
cd ~
wget https://www.openssl.org/source/openssl-1.1.0f.tar.gz
tar -xf openssl-1.1.0f.tar.gz
cd openssl-1.1.0f
./configure --prefix=/usr --sysconfdir=/etc/ssl --libdir=lib && make && make test && make install
make MANSUFFIX=ssl install && mv -v /usr/share/doc/openssl{,-1.1.0f} && cp -vfr doc/* /usr/share/doc/openssl-1.1.0f

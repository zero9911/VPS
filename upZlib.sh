#
#!/bin/sh
#install zLib
#

# zLib 1.2.11
~# cd ~
~# wget http://www.zlib.net/zlib-1.2.11.tar.gz
~# tar -xf zlib-1.2.11.tar.gz
~# cd zlib-1.2.11
~# ./configure --prefix=/usr ----sysconfdir=/usr/include && make && make install

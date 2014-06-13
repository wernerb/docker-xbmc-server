# docker-xbmc-server
#
# Setup: Clone repo then checkout appropriate version
#   For Frodo:
#     $ git checkout frodo
#   For Gotham
#     $ git checkout gotham
#   For Master (currently gotham)
#     $ git checkout master
#
# Create your own Build:
# 	$ docker build --rm=true -t $(whoami)/docker-xbmc-server .
#
# Run your build:
# There are two choices   
#   - UPnP server and webserver in the background: (replace ip and xbmc data location)
#	  $ docker run -d --net=host --privileged -v /directory/with/xbmcdata:/opt/xbmc-server/portable_data $(whoami)/docker-xbmc-server
#
#   - Run only the libraryscan and quit: 
#	  $ docker run -v /directory/with/xbmcdata:/opt/xbmc-server/portable_data --entrypoint=/opt/xbmc-server/xbmcVideoLibraryScan $(whoami)/docker-xbmc-server --no-test --nolirc -p
#
# See README.md.
# Source: https://github.com/wernerb/docker-xbmc-server

from ubuntu:12.10
maintainer Werner Buck "email@wernerbuck.nl"

# Set locale to UTF8
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
RUN locale-gen en_US en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8
RUN dpkg-reconfigure locales

# Install java
RUN apt-get update && apt-get -y install git openjdk-7-jre-headless

#Download XBMC, pick version from github
RUN git clone https://github.com/xbmc/xbmc.git -b Frodo --depth=1

# Install xbmc dependencies
RUN (apt-get install -y build-essential gawk pmount libtool nasm yasm automake cmake gperf zip unzip bison libsdl-dev libsdl-image1.2-dev libsdl-gfx1.2-dev libsdl-mixer1.2-dev libfribidi-dev liblzo2-dev libfreetype6-dev libsqlite3-dev libogg-dev libasound2-dev python-sqlite libglew-dev libcurl3 libcurl4-gnutls-dev libxrandr-dev libxrender-dev libmad0-dev libogg-dev libvorbisenc2 libsmbclient-dev libmysqlclient-dev libpcre3-dev libdbus-1-dev libhal-dev libhal-storage-dev libjasper-dev libfontconfig-dev libbz2-dev libboost-dev libenca-dev libxt-dev libxmu-dev libpng-dev libjpeg-dev libpulse-dev mesa-utils libcdio-dev libsamplerate-dev libmpeg3-dev libflac-dev libiso9660-dev libass-dev libssl-dev fp-compiler gdc libmpeg2-4-dev libmicrohttpd-dev libmodplug-dev libssh-dev gettext cvs python-dev libyajl-dev libboost-thread-dev libplist-dev libusb-dev libudev-dev libtinyxml-dev libcap-dev autopoint libltdl-dev swig libgtk2.0-bin libtag1-dev libtiff-dev libnfs1 libnfs-dev wget)

ADD src/fixcrash.diff xbmc/fixcrash.diff
ADD src/make_xbmc-server xbmc/xbmc/make_xbmc-server
ADD src/xbmc-server.cpp xbmc/xbmc/xbmc-server.cpp
ADD src/make_xbmcVideoLibraryScan xbmc/xbmc/make_xbmcVideoLibraryScan
ADD src/xbmcVideoLibraryScan.cpp xbmc/xbmc/xbmcVideoLibraryScan.cpp

#Apply fix for crashing in UPnP
RUN (cd xbmc && git apply fixcrash.diff) 

#Configure, make, clean
RUN (cd xbmc && ./bootstrap && ./configure --enable-nfs --enable-upnp --enable-shared-lib --disable-debug --disable-vdpau  --disable-vaapi --disable-crystalhd  --disable-vdadecoder  --disable-vtbdecoder  --disable-openmax  --disable-joystick --disable-xrandr  --disable-rsxs  --disable-projectm --disable-rtmp  --disable-airplay --disable-airtunes --disable-dvdcss --disable-optical-drive  --disable-libbluray --disable-libusb  --disable-libcec  --disable-libmp3lame  --disable-libcap --disable-dbus && make -j2 && cp libxbmc.so /lib && ldconfig && cd xbmc && make -f make_xbmc-server all && make -f make_xbmcVideoLibraryScan all && mkdir -p /opt/xbmc-server/portable_data/ && cp xbmc-server xbmcVideoLibraryScan /opt/xbmc-server && cd .. && cp -R addons language media sounds system userdata /opt/xbmc-server/ && cd / && rm -rf /xbmc)

#Fix for XBMC not being able to choose its own network binding interface. Will force the webserver/eventserver/upnpserver to use the specified ip if LD_PRELOAD and BIND_ADDR are given as environment variables. See README.MD for further info
RUN (cd /opt/xbmc-server && wget http://www.ryde.net/code/bind.c.txt -O bind.c && gcc -nostartfiles -fpic -shared bind.c -o bind.so -ldl -D_GNU_SOURCE)

#remove everything, clean cache, remove java.
RUN (apt-get purge -y --auto-remove git openjdk* build-essential gcc gawk pmount libtool nasm yasm automake cmake gperf zip unzip bison libsdl-dev libsdl-image1.2-dev libsdl-gfx1.2-dev libsdl-mixer1.2-dev libfribidi-dev liblzo2-dev libfreetype6-dev libsqlite3-dev libogg-dev libasound2-dev python-sqlite libglew-dev libcurl3 libcurl4-gnutls-dev libxrandr-dev libxrender-dev libmad0-dev libogg-dev libvorbisenc2 libsmbclient-dev libmysqlclient-dev libpcre3-dev libdbus-1-dev libhal-dev libhal-storage-dev libjasper-dev libfontconfig-dev libbz2-dev libboost-dev libenca-dev libxt-dev libxmu-dev libpng-dev libjpeg-dev libpulse-dev mesa-utils libcdio-dev libsamplerate-dev libmpeg3-dev libflac-dev libiso9660-dev libass-dev libssl-dev fp-compiler gdc libmpeg2-4-dev libmicrohttpd-dev libmodplug-dev libssh-dev gettext cvs python-dev libyajl-dev libboost-thread-dev libplist-dev libusb-dev libudev-dev libtinyxml-dev libcap-dev autopoint libltdl-dev swig libgtk2.0-bin libtag1-dev libtiff-dev libnfs-dev && apt-get -y autoremove) 

#install only dependencies for running xbmc. Taken out of the list: libbluetooth3 libbluray1. Put in the list: libssh-4 libtag1c2a libcurl3-gnutls libnfs1
RUN (apt-get install -y fonts-liberation libaacs0 libasound2 libass4 libasyncns0 libavcodec53 libavfilter2 libavformat53 libavutil51 libcaca0 libcap2 libcdio13 libcec1 libcrystalhd3 libdrm-nouveau2 libenca0 libflac8 libfontenc1 libgl1-mesa-dri libgl1-mesa-glx libglapi-mesa libglew1.8 libglu1-mesa libgsm1 libhal-storage1 libhal1 libice6 libjson0 liblcms1 libllvm3.1 liblzo2-2 libmad0 libmicrohttpd10 libmikmod2 libmodplug1 libmp3lame0 libmpeg2-4 libmysqlclient18 liborc-0.4-0 libpcrecpp0 libplist1 libpostproc52 libpulse0 libpython2.7 libschroedinger-1.0-0 libsdl-mixer1.2 libsdl1.2debian libshairport1 libsm6 libsmbclient libsndfile1 libspeex1 libswscale2 libtalloc2 libtdb1 libtheora0 libtinyxml2.6.2 libtxc-dxtn-s2tc0 libva-glx1 libva-x11-1 libva1 libvdpau1 libvorbisfile3 libvpx1 libwbclient0 libwrap0 libx11-xcb1 libxaw7 libxcb-glx0 libxcb-shape0 libxmu6 libxpm4 libxt6 libxtst6 libxv1 libxxf86dga1 libxxf86vm1 libyajl2 mesa-utils mysql-common python-cairo python-gobject-2 python-gtk2 python-imaging python-support tcpd ttf-liberation libssh-4 libtag1c2a libcurl3-gnutls libnfs1 && apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists /usr/share/man /usr/share/doc)

#Eventserver and webserver respectively.
EXPOSE 9777/udp 8089/tcp

#Preload bind which is used to bind xbmc to $BIND_ADDR. Use in combination with -e BIND_ADDR=ipaddress when running docker.
#ENV LD_PRELOAD /opt/xbmc-server/bind.so
#ENV BIND_ADDR 192.168.1.50

ENTRYPOINT ["/opt/xbmc-server/xbmc-server","--no-test","--nolirc","-p"]

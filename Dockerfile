# docker-xbmc-server
#
# Setup: Clone repo then checkout appropriate version
#   For stable (Gotham)
#     $ git checkout master
#   For experimental (Helix/Kodi)
#     $ git checkout experimental
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
RUN locale-gen --no-purge en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8
RUN dpkg-reconfigure locales
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Set Terminal to non interactive
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Install java, git wget and supervisor
RUN sed -i -e 's/archive.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list && \
    apt-get update && \
	apt-get -y install git openjdk-7-jre-headless supervisor

# Download XBMC, pick version from github
RUN git clone https://github.com/xbmc/xbmc.git --depth=1

# Add patches and xbmc-server files
ADD src/fixcrash.diff xbmc/fixcrash.diff
ADD src/make_xbmc-server xbmc/xbmc/make_xbmc-server
ADD src/xbmc-server.cpp xbmc/xbmc/xbmc-server.cpp
ADD src/make_xbmcVideoLibraryScan xbmc/xbmc/make_xbmcVideoLibraryScan
ADD src/xbmcVideoLibraryScan.cpp xbmc/xbmc/xbmcVideoLibraryScan.cpp
ADD src/wsnipex-fix-ede443716d0f3e5174674ddad8c5678691143b1b.diff xbmc/wsnipex-fix-ede443716d0f3e5174674ddad8c5678691143b1b.diff
ADD src/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Apply patches:
#	fixrash.diff : Fixes crashing in UPnP 
#	wsnipex-fix-ede443716d0f3e5174674ddad8c5678691143b1b.diff : Fixes shared library compilation on gotham 
RUN cd xbmc && \
 git apply fixcrash.diff && \
 git apply wsnipex-fix-ede443716d0f3e5174674ddad8c5678691143b1b.diff

# Installs xbmc dependencies, configure, make, clean.
# Taken out of the list of dependencies: libbluetooth3. Put in the list: libssh-4 libtag1c2a libcurl3-gnutls libnfs1
RUN apt-get install -y build-essential gawk pmount libtool nasm yasm automake cmake gperf zip unzip bison libsdl-dev libsdl-image1.2-dev libsdl-gfx1.2-dev libsdl-mixer1.2-dev libfribidi-dev liblzo2-dev libfreetype6-dev libsqlite3-dev libogg-dev libasound2-dev python-sqlite libglew-dev libcurl3 libcurl4-gnutls-dev libxrandr-dev libxrender-dev libmad0-dev libogg-dev libvorbisenc2 libsmbclient-dev libmysqlclient-dev libpcre3-dev libdbus-1-dev libhal-dev libhal-storage-dev libjasper-dev libfontconfig-dev libbz2-dev libboost-dev libenca-dev libxt-dev libxmu-dev libpng-dev libjpeg-dev libpulse-dev mesa-utils libcdio-dev libsamplerate-dev libmpeg3-dev libflac-dev libiso9660-dev libass-dev libssl-dev fp-compiler gdc libmpeg2-4-dev libmicrohttpd-dev libmodplug-dev libssh-dev gettext cvs python-dev libyajl-dev libboost-thread-dev libplist-dev libusb-dev libudev-dev libtinyxml-dev libcap-dev autopoint libltdl-dev swig libgtk2.0-bin libtag1-dev libtiff-dev libnfs1 libnfs-dev libxslt-dev libbluray-dev && \
	cd xbmc && \
	./bootstrap && \
	./configure \
		--enable-nfs \
		--enable-upnp \
		--enable-shared-lib \
		--enable-ssh \
		--enable-libbluray \
		--disable-debug \
		--disable-vdpau \
		--disable-vaapi \
		--disable-crystalhd \ 
		--disable-vdadecoder \
		--disable-vtbdecoder \
		--disable-openmax \
		--disable-joystick \
		--disable-xrandr \
		--disable-rsxs \
		--disable-projectm \
		--disable-rtmp \
		--disable-airplay \
		--disable-airtunes \
		--disable-dvdcss \
		--disable-optical-drive \
		--disable-libusb \
		--disable-libcec \
		--disable-libmp3lame \
		--disable-libcap \
		--disable-udev \
		--disable-libvorbisenc \
		--disable-asap-codec \
		--disable-afpclient \
		--disable-goom \
		--disable-fishbmc \
		--disable-spectrum \
		--disable-waveform \
		--disable-avahi \
		--disable-non-free \
		--disable-texturepacker \
		--disable-pulse \
		--disable-dbus \
		--disable-alsa \
		--disable-hal && \
	make -j2 && \
	cp libxbmc.so /lib && \
	ldconfig && \
	cd xbmc && \
	make -f make_xbmc-server all && \
	make -f make_xbmcVideoLibraryScan all && \
	mkdir -p /opt/xbmc-server/portable_data/ && \
	cp xbmc-server xbmcVideoLibraryScan /opt/xbmc-server && \
	cd .. && \
	cp -R addons language media sounds system userdata /opt/xbmc-server/ && \
	cd / && \
	rm -rf /xbmc && \
	apt-get purge -y --auto-remove git openjdk* build-essential gcc gawk pmount libtool nasm yasm automake cmake gperf zip unzip bison libsdl-dev libsdl-image1.2-dev libsdl-gfx1.2-dev libsdl-mixer1.2-dev libfribidi-dev liblzo2-dev libfreetype6-dev libsqlite3-dev libogg-dev libasound2-dev python-sqlite libglew-dev libcurl3 libcurl4-gnutls-dev libxrandr-dev libxrender-dev libmad0-dev libogg-dev libvorbisenc2 libsmbclient-dev libmysqlclient-dev libpcre3-dev libdbus-1-dev libhal-dev libhal-storage-dev libjasper-dev libfontconfig-dev libbz2-dev libboost-dev libenca-dev libxt-dev libxmu-dev libpng-dev libjpeg-dev libpulse-dev mesa-utils libcdio-dev libsamplerate-dev libmpeg3-dev libflac-dev libiso9660-dev libass-dev libssl-dev fp-compiler gdc libmpeg2-4-dev libmicrohttpd-dev libmodplug-dev libssh-dev gettext cvs python-dev libyajl-dev libboost-thread-dev libplist-dev libusb-dev libudev-dev libtinyxml-dev libcap-dev autopoint libltdl-dev swig libgtk2.0-bin libtag1-dev libtiff-dev libnfs-dev libbluray-dev && \
	apt-get -y autoremove && \
	apt-get install -y fonts-liberation libaacs0 libbluray1 libasound2 libass4 libasyncns0 libavcodec53 libavfilter2 libavformat53 libavutil51 libcaca0 libcap2 libcdio13 libcec1 libcrystalhd3 libdrm-nouveau2 libenca0 libflac8 libfontenc1 libgl1-mesa-dri libgl1-mesa-glx libglapi-mesa libglew1.8 libglu1-mesa libgsm1 libhal-storage1 libhal1 libice6 libjson0 liblcms1 libllvm3.1 liblzo2-2 libmad0 libmicrohttpd10 libmikmod2 libmodplug1 libmp3lame0 libmpeg2-4 libmysqlclient18 liborc-0.4-0 libpcrecpp0 libplist1 libpostproc52 libpulse0 libpython2.7 libschroedinger-1.0-0 libsdl-mixer1.2 libsdl1.2debian libshairport1 libsm6 libsmbclient libsndfile1 libspeex1 libswscale2 libtalloc2 libtdb1 libtheora0 libtinyxml2.6.2 libtxc-dxtn-s2tc0 libva-glx1 libva-x11-1 libva1 libvdpau1 libvorbisfile3 libvpx1 libwbclient0 libwrap0 libx11-xcb1 libxaw7 libxcb-glx0 libxcb-shape0 libxmu6 libxpm4 libxt6 libxtst6 libxv1 libxxf86dga1 libxxf86vm1 libyajl2 mesa-utils mysql-common python-cairo python-gobject-2 python-gtk2 python-imaging python-support tcpd ttf-liberation libssh-4 libtag1c2a libcurl3-gnutls libnfs1 && \
	apt-get -y autoremove && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists /usr/share/man /usr/share/doc

#Eventserver and webserver respectively.
EXPOSE 9777/udp 8089/tcp

ENTRYPOINT ["/usr/bin/supervisord"]

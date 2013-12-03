# Tested with docker v0.7
# Build: docker build -rm=true -t xbmc-server .
# Run: ./startXbmc.sh

from ubuntu:12.10
maintainer Werner Buck "email@wernerbuck.nl"

# Install java & git
RUN (apt-get install software-properties-common git-core -y && apt-add-repository ppa:webupd8team/java -y && apt-get update && echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections && apt-get install oracle-java7-installer -y)

# RUN wget https://github.com/xbmc/xbmc/archive/12.2-Frodo.tar.gz && tar xvzf 12.2-Frodo.tar.gz && mv xbmc-12.2-Frodo/xbmc . && rm -rf 12.2-Frodo.tar.gz xbmc-12.2-Frodo
# Use following to launch from git
RUN git clone https://github.com/xbmc/xbmc.git -b Frodo --depth=1

# Install xbmc dependencies
RUN (apt-get install -y build-essential gawk pmount libtool nasm yasm automake cmake gperf zip unzip bison libsdl-dev libsdl-image1.2-dev libsdl-gfx1.2-dev libsdl-mixer1.2-dev libfribidi-dev liblzo2-dev libfreetype6-dev libsqlite3-dev libogg-dev libasound2-dev python-sqlite libglew-dev curl libcurl3 libcurl4-gnutls-dev libxrandr-dev libxrender-dev libmad0-dev libogg-dev libvorbisenc2 libsmbclient-dev libmysqlclient-dev libpcre3-dev libdbus-1-dev libhal-dev libhal-storage-dev libjasper-dev libfontconfig-dev libbz2-dev libboost-dev libenca-dev libxt-dev libxmu-dev libpng-dev libjpeg-dev libpulse-dev mesa-utils libcdio-dev libsamplerate-dev libmpeg3-dev libflac-dev libiso9660-dev libass-dev libssl-dev fp-compiler gdc libmpeg2-4-dev libmicrohttpd-dev libmodplug-dev libssh-dev gettext cvs python-dev libyajl-dev libboost-thread-dev libplist-dev libusb-dev libudev-dev libtinyxml-dev libcap-dev autopoint libltdl-dev swig libgtk2.0-bin doxygen libtag1-dev libtiff4-dev libnfs1 libnfs-dev)

ADD src/make_xbmc-server xbmc/xbmc/make_xbmc-server
ADD src/xbmc-server.cpp xbmc/xbmc/xbmc-server.cpp

#Configure, make, clean
RUN (cd xbmc && ./bootstrap && ./configure  --enable-shared-lib  --enable-nfs --enable-upnp --disable-debug --disable-vdpau  --disable-vaapi --disable-crystalhd  --disable-vdadecoder  --disable-vtbdecoder  --disable-openmax  --disable-joystick --disable-xrandr  --disable-rsxs  --disable-projectm --disable-rtmp  --disable-airplay --disable-airtunes --disable-dvdcss --disable-optical-drive  --disable-libbluray --disable-libusb  --disable-libcec  --disable-libmp3lame  --disable-libcap --disable-ssh --disable-udev --disable-libvorbisenc --disable-asap-codec --disable-afpclient --disable-goom --disable-non-free && make -j2 && cp libxbmc.so /lib && ldconfig && cd xbmc && make -f make_xbmc-server all && mkdir -p /opt/xbmc-server && cp xbmc-server /opt/xbmc-server && cd .. && cp -R addons language media sounds system userdata /opt/xbmc-server/ && cd / && rm -rf /xbmc)
RUN mkdir -p /opt/xbmc-server/portable_data/userdata/

#Move config files to use.
ADD userdata/guisettings.xml /opt/xbmc-server/portable_data/userdata/
ADD userdata/advancedsettings.xml /opt/xbmc-server/portable_data/userdata/

#Eventserver and webserver respectively.
EXPOSE 9777/udp 8080/tcp

ENTRYPOINT ["/opt/xbmc-server/xbmc-server","--no-test","--nolirc","-p"]

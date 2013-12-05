# Tested with docker v0.7
# Build: docker build -rm=true -t xbmc-server .
# Run: ./startXbmc.sh

from ubuntu:12.10
maintainer Werner Buck "email@wernerbuck.nl"

# Install java
RUN apt-get update
RUN apt-get -y install git openjdk-7-jre-headless

#Download XBMC, pick version from github
#RUN (curl -L https://github.com/xbmc/xbmc/archive/Frodo.tar.gz | tar zx && mv xbmc-Frodo xbmc && rm -f Frodo.tar.gz)  
RUN git clone https://github.com/xbmc/xbmc.git -b Frodo --depth=1

# Install xbmc dependencies
RUN (apt-get install -y build-essential gawk pmount libtool nasm yasm automake cmake gperf zip unzip bison libsdl-dev libsdl-image1.2-dev libsdl-gfx1.2-dev libsdl-mixer1.2-dev libfribidi-dev liblzo2-dev libfreetype6-dev libsqlite3-dev libogg-dev libasound2-dev python-sqlite libglew-dev libcurl3 libcurl4-gnutls-dev libxrandr-dev libxrender-dev libmad0-dev libogg-dev libvorbisenc2 libsmbclient-dev libmysqlclient-dev libpcre3-dev libdbus-1-dev libhal-dev libhal-storage-dev libjasper-dev libfontconfig-dev libbz2-dev libboost-dev libenca-dev libxt-dev libxmu-dev libpng-dev libjpeg-dev libpulse-dev mesa-utils libcdio-dev libsamplerate-dev libmpeg3-dev libflac-dev libiso9660-dev libass-dev libssl-dev fp-compiler gdc libmpeg2-4-dev libmicrohttpd-dev libmodplug-dev libssh-dev gettext cvs python-dev libyajl-dev libboost-thread-dev libplist-dev libusb-dev libudev-dev libtinyxml-dev libcap-dev autopoint libltdl-dev swig libgtk2.0-bin doxygen libtag1-dev libtiff-dev libnfs1 libnfs-dev)

ADD src/fixcrash.diff xbmc/fixcrash.diff
ADD src/make_xbmc-server xbmc/xbmc/make_xbmc-server
ADD src/xbmc-server.cpp xbmc/xbmc/xbmc-server.cpp
ADD src/make_xbmcVideoLibraryScan xbmc/xbmc/make_xbmcVideoLibraryScan
ADD src/xbmcVideoLibraryScan.cpp xbmc/xbmc/xbmcVideoLibraryScan.cpp

#Apply fix for crashing in UPnP
RUN (cd xbmc && git apply fixcrash.diff) 

#Configure, make, clean
RUN (cd xbmc && ./bootstrap && ./configure --enable-nfs --enable-upnp --enable-shared-lib --enable-debug --disable-vdpau  --disable-vaapi --disable-crystalhd  --disable-vdadecoder  --disable-vtbdecoder  --disable-openmax  --disable-joystick --disable-xrandr  --disable-rsxs  --disable-projectm --disable-rtmp  --disable-airplay --disable-airtunes --disable-dvdcss --disable-optical-drive  --disable-libbluray --disable-libusb  --disable-libcec  --disable-libmp3lame  --disable-libcap && make -j2 && cp libxbmc.so /lib && ldconfig && cd xbmc && make -f make_xbmc-server all && make -f make_xbmcVideoLibraryScan all && mkdir -p /opt/xbmc-server/portable_data/userdata/ && cp xbmc-server xbmcVideoLibraryScan /opt/xbmc-server && cd .. && cp -R addons language media sounds system userdata /opt/xbmc-server/ && cd / && rm -rf /xbmc)


#remove headers
RUN (apt-get remove -y libsdl-dev libsdl-image1.2-dev libsdl-gfx1.2-dev libsdl-mixer1.2-dev libfribidi-dev liblzo2-dev libfreetype6-dev libsqlite3-dev libogg-dev libasound2-dev libglew-dev libcurl3 libcurl4-gnutls-dev libxrender-dev libmad0-dev libogg-dev libsmbclient-dev libmysqlclient-dev libpcre3-dev libdbus-1-dev libhal-dev libhal-storage-dev libjasper-dev libfontconfig-dev libbz2-dev libboost-dev libenca-dev libxt-dev libxmu-dev libpng-dev libjpeg-dev libpulse-dev mesa-utils libcdio-dev libsamplerate-dev libmpeg3-dev libflac-dev libiso9660-dev libass-dev libssl-dev libmpeg2-4-dev libmicrohttpd-dev libmodplug-dev python-dev libyajl-dev libboost-thread-dev libplist-dev libtinyxml-dev libcap-dev libltdl-dev  libtiff-dev libnfs-dev) 
#RUN (apt-get remove -y libtag1-dev)

#clean java crap
RUN (apt-get clean && rm -rf /usr/lib/jvm/*)

#Move confi files to use.
ADD userdata/advancedsettings.xml /opt/xbmc-server/portable_data/userdata/

#Initialize all the settings for xbmc by running and killing it.
RUN (/opt/xbmc-server/xbmc-server --no-test --nolirc -p & VAR=$! ; sleep 15 ; kill $VAR)

#Eventserver and webserver respectively.
EXPOSE 9777/udp 8080/tcp

ENTRYPOINT ["/opt/xbmc-server/xbmc-server","--no-test","--nolirc","-p"]

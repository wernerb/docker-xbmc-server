# docker-xbmc-server

**/!\ WARNING: Kodi portable_data dir change. Its now /opt/kodi-server/share/kodi/portable_data**

This will allow you to serve files through the kodi UPnP Library to your UPnP client/players (such as Kodi or Chromecast). 

Docker is used to compile and run the latest stable headless version of XBMC/Kodi (There is also an experimental branch that tracks the development of xbmc) 

This also includes some custom patches that will fix crashes. See the FAQ section for details.

### Preqrequisites:
* Docker version 0.12+ (Follow the [installation instructions](https://docs.docker.com/))

### Quick start

1. Clone the repository:
        
        $ git clone git@github.com:wernerb/docker-xbmc-server.git

2. open `xbmcdata/userdata/advancedsettings.xml` and change the following information to reflect your installation:

        <videodatabase>
                <type>mysql</type>
                <host>192.168.1.50</host>
                <port>3306</port>
                <user>xbmc</user>
                <pass>xbmc</pass>
        </videodatabase>
        <musicdatabase>
                <type>mysql</type>
                <host>192.168.1.50</host>
                <port>3306</port>
                <user>xbmc</user>
                <pass>xbmc</pass>
        </musicdatabase>
        
    The ip,port,user and password refers to your xbmc mysql database.

3. You now are ready to pull and run XBMC/kodi server with docker.

    Run the following command to spawn a docker container running xbmc headless with UPnP:

        $ docker run -d --net=host --privileged -v /directory/with/xbmcdata:/opt/kodi-server/share/kodi/portable_data wernerb/docker-xbmc-server
    
    * Replace `wernerb/docker-xbmc-server` with `wernerb/docker-xbmc-server:experimental` if you want to use the latest unreleased xbmc version
    * Replace `/directory/with/xbmcdata` with the folder where you would like to store the xbmc data. Point it to the full path to the xbmcdata folder of this repository.
    * If you need to mount extra folders, just use `-v /local/folder/:/remotefolder`. For example, in my case I use `-v /media:/media` 
    * The webserver is automatically configured and started on port `8089` with the username/password configurable in `userdata/advancedsettings.xml`.
    
### Build the container yourself
  
    $ git checkout experimental 
    $ docker build --rm=true -t $(whoami)/docker-xbmc-server .

### F.A.Q.

__Why Docker?__ 
Docker ensures that xbmc-server can be run on multiple operating systems, as well as making xbmc-server portable. In the case of xbmc-server, a lot of people are having trouble compiling it to work in headless mode for different distributions. The steps to compile xbmc can be viewed in `Dockerfile` and lists the best practises found in this [xbmc forum thread](http://forum.xbmc.org/showthread.php?tid=132919).

__What do the patches do?__
I discovered that the UPnP server in XBMC was very unstable, and crashed when browsing the library in headless mode. The problem was with thumbnail generation for some videos. The patches provided in this repo are automatically applied when compiling for headless mode, and allows xbmc to run without crashing.   

# docker-xbmc-server

This will allow you to serve files through the XBMC UPnP Library to your UPnP client/players (such as Xbmc or Chromecast). 

Docker is used to compile and run the latest headless version of XBMC Frodo

This has been inspired by [Plex media server in Docker](http://blog.ostanin.org/2013/09/14/plex-media-server-in-docker/)

This also includes some custom patches that will fix crashes. See the FAQ section for details.

If you are running Docker 0.9+ look at the FAQ

### Preqrequisites:
* Docker version 0.8+ (See FAQ for 0.9+)
* Optional, for UPnP to work: Set up a bridge. Your docker container must run on an IP that reaches your media players. See the [Setting up a network bridge section on this blog](http://blog.ostanin.org/2013/09/14/plex-media-server-in-docker/)

### Quick start

1. Clone this repository:
        
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

3. You now are ready to pull and run XBMC. There are two possible ways to use this container. You can either have it run as a daemon serving your xbmc library through UPnP as well as being capable of updating your library, or you can simply run the container and only update the xbmc library.  
    * __Just Update the Xbmc library__: 
                        
        Simply run docker with the following command each time you want the library to be updated:
        
            $ sudo docker run -v /directory/with/xbmcdata:/opt/xbmc-server/portable_data --entrypoint=/opt/xbmc-server/xbmcVideoLibraryScan xbmc-server --no-test --nolirc -p
        
        Replace `/directory/with/xbmcdata` with the folder where you would like to store the xbmc data. Point it to the full path to the xbmcdata folder of this repository.

        Use this command in your automation scripts or in a crontab. Keep in mind that a library scan can take some time.

    * __UPnP Server__:  
        Required: See [Plex media server in Docker](http://blog.ostanin.org/2013/09/14/plex-media-server-in-docker/) on how to set up a bridge.
        
        Pull from docker and run:

            $ sudo docker run -d --networking=false \
              -v /directory/with/xbmcdata:/opt/xbmc-server/portable_data \
              --lxc-conf="lxc.network.type = veth" \
              --lxc-conf="lxc.network.flags = up" \
              --lxc-conf="lxc.network.link = br0" \
              --lxc-conf="lxc.network.ipv4 = 192.168.1.49" \
              --lxc-conf="lxc.network.ipv4.gateway=192.168.1.1" \
              wernerb/docker-xbmc-server
        
        Ps. Replace `br0`, `192.168.1.48` and `192.168.1.1` with the bridge interface, desired ip for container and your network gateway IP. Replace `/directory/with/xbmcdata` with the folder where you would like to store the xbmc data. Point it to the full path to the xbmcdata folder of this repository.
    
        
### Build the container yourself
Execute:
    
    docker build --rm=true -t wernerb/xbmc-server .
    
Then proceed with the Quick start section.

### F.A.Q.

__Why Docker?__ 
Docker ensures that xbmc-server can be run on multiple operating systems, as well as making xbmc-server portable. In the case of xbmc-server, a lot of people are having trouble compiling it to work in headless mode for different distributions. The steps to compile xbmc can be viewed in `Dockerfile` and lists the best practises found in this [xbmc forum thread](http://forum.xbmc.org/showthread.php?tid=132919).

__What do the patches do?__
I discovered that the UPnP server in XBMC was very unstable, and crashed when browsing the library in headless mode. The problem was with thumbnail generation for some videos. The patches provided in this repo are automatically applied when compiling for headless mode, and allows xbmc to run without crashing.

__Getting veth errors?__
You are most likely running docker 0.9 or higher that uses libcontainer and not lxc. Until lxc-conf veth commands work you can work around this by running docker with the following additonal arguments `-e lxc`.

* For Arch linux: you can find the file to add the arguments at:

        /etc/systemd/system/multi-user.target.wants/docker.service
    
* For Ubuntu: open `/etc/docker/default` and uncomment and edit the following:
    
        #DOCKER_OPTS="-dns 8.8.8.8 -dns 8.8.4.4"
    to reflect:
    
        DOCKER_OPTS="-e lxc" 
    

__What versions did you test this with?__

* Docker v0.9: XBMC (12.3 Git:20131212-9ed3e58)
* Docker v0.7: XBMC (12.2 Git:20131204-5151fa8)

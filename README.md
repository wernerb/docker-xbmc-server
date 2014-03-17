# Xbmc Server Gotham with Docker

This will allow you to serve files through UPnP to your UPnP clients (such as Xbmc). 
Docker is used to compile and run the headless version of xbmc.

This has been inspired by [Plex media server in Docker](http://blog.ostanin.org/2013/09/14/plex-media-server-in-docker/)

### Why docker?
Docker ensures that xbmc-server can be run on multiple operating systems, as well as making xbmc-server portable. In the case of xbmc-server, a lot of people are having trouble compiling it to work in headless mode for different distributions. The steps to compile xbmc can be viewed in `Dockerfile` and lists the best practises found in this [xbmc forum thread](http://forum.xbmc.org/showthread.php?tid=132919).

### Custom patches
I discovered that the UPnP server in XBMC was very unstable, and crashed when browsing the library in headless mode. The problem was with thumbnail generation for some videos. The patches provided in this repo are automatically applied when compiling for headless mode, and allows xbmc to run without crashing.

### Requirements:
* Docker version 0.7 or higher
* Ability to set-up a network bridge (if you want to use xbmc with UPnP server)

## How to use

1. Install [docker](https://www.docker.io/gettingstarted/) for your unix distribution or vagrant.
2. Make sure your installation is correct by executing `docker ps`. You may or may not have to use `sudo`.
4. Important. If you are running docker version `docker --version`: `>= 0.9.0` and you wish to use the UPnP server of Xbmc, then you need to start the docker daemon with `docker -d -e lxc`. If you are running an older version you can skip this step.

    Make sure to add "-e lxc" to the arguments that starts docker
    
    In arch linux you can find the file in:
    
        /etc/systemd/system/multi-user.target.wants/docker.service
        
    In ubuntu open `/etc/docker/default` and uncomment and edit the following:
        
        #DOCKER_OPTS="-dns 8.8.8.8 -dns 8.8.4.4"
    to reflect:
    
        DOCKER_OPTS="-e lxc" 

5. Clone this repository:
        
        $ git clone git@github.com:wernerb/docker-xbmc-server.git

6. open `xbmcdata/userdata/advancedsettings.xml` and change the following information to reflect your installation:

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

7. Next we are going to build compile xbmc. This is an automatic process that can take some time. Use the following command in the location where you cloned this repository:
    
        docker build --rm=true -t xbmc-server .

    * the option `--rm=true` can be removed if you want to debug, but will cost you some diskspace.


If the container builds succesfully you are done, and xbmc will have compiled and will be ready to run. See the next section "Run Modes".

## Run modes
You can use this container to either run continuously and serve files, or only run for a brief time and execute a library scan.   It should be noted that if run continuously you can also update the library through the API.

#### 1. Daemon mode with UPnP Server

If you would like to use UPnP You need to set up a bridge. See [Plex media server in Docker](http://blog.ostanin.org/2013/09/14/plex-media-server-in-docker/) for how to set-up a bridge, or refer to the internet.

Replace the IP address with the IP you would like to give the container. Set the correct gateway. Also replace `/directory/with/xbmcdata` with the folder where you would like to store the xbmc data. Point it to the full path to the xbmcdata folder of this repository.

Use the following command to run xbmc as a daemon in a container. It will automatically restart when restarting your computer.

    docker run -d --networking=false \
      -v /directory/with/xbmcdata:/opt/xbmc-server/portable_data \
      --lxc-conf="lxc.network.type = veth" \
      --lxc-conf="lxc.network.flags = up" \
      --lxc-conf="lxc.network.link = br0" \
      --lxc-conf="lxc.network.ipv4 = 192.168.1.49" \
      --lxc-conf="lxc.network.ipv4.gateway=192.168.1.1" \
      xbmc-server
          
You can also edit and execute the script `./startXbmc.sh`

#### 2. Only run a library scan when needed.
If you only want to update your library when, for example, something new has been downloaded you should use this mode.
It also does not require setting up a bridge or changing your docker settings.

Replace `/directory/with/xbmcdata` with the folder where you would like to store the xbmc data. Point it to the full path to the xbmcdata folder of this repository.

Simply run docker with the following command each time you want the library to be updated.

    docker run -v /directory/with/xbmcdata:/opt/xbmc-server/portable_data --entrypoint=/opt/xbmc-server/xbmcVideoLibraryScan xbmc-server --no-test --nolirc -p

Use this command in your automation scripts or in a crontab. Keep in mind that a library scan can take some time.

### Tested successfully with:
* Docker v0.7: XBMC (12.2 Git:20131204-5151fa8)
* Docker v0.9: XBMC (12.3 Git:20131212-9ed3e58)

# docker-xbmc-server

This will allow you to serve files through the XBMC UPnP Library to your UPnP client/players (such as Xbmc or Chromecast). 

Docker is used to compile and run the latest headless version of XBMC Gotham/Frodo

This also includes some custom patches that will fix crashes. See the FAQ section for details.

### Preqrequisites:
* Docker version 0.12+ (Follow the [installation instructions](https://docs.docker.com/))

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

3. You now are ready to pull and run XBMC. You can either run as a daemon serving your xbmc library through UPnP as well as being capable of updating your library, or you can simply run the container and only update the xbmc library.  
    Before pulling the image and running check what version you need (gotham/frodo)

    * __Daemon__:  

        Run the following command to spawn a docker container running xbmc with UPnP:

            $ docker run -d --net=host --privileged -v /directory/with/xbmcdata:/opt/xbmc-server/portable_data wernerb/docker-xbmc-server:gotham
        
        * Replace `wernerb/docker-xbmc-server:gotham` with `wernerb/docker-xbmc-server:frodo` if you use frodo!
        * Replace `/directory/with/xbmcdata` with the folder where you would like to store the xbmc data. Point it to the full path to the xbmcdata folder of this repository.
        * If you need to mount extra folders, just use `-v /local/folder/:/remotefolder`. For example, in my case I use `-v /media:/media` 
        * The webserver is automatically configured and started on port `8089` with the username/password configurable in `userdata/advancedsettings.xml`.
        
        Extra note:

        * Advanced: If you have problems reaching the web-server then xbmc is binding to the wrong address. Try adding the following after `--privileged`: `-e BIND_ADDR=ipaddress -e LD_PRELOAD=/opt/xbmc-server/bind.so`

    
    * __Single run__: 
                        
        Run docker with the following command each time you want the library to be updated:
        
            $ sudo docker run -v /directory/with/xbmcdata:/opt/xbmc-server/portable_data --entrypoint=/opt/xbmc-server/xbmcVideoLibraryScan wernerb/docker-xbmc-server:gotham --no-test --nolirc -p
        
        Replace `/directory/with/xbmcdata` with the folder where you would like to store the xbmc data. Point it to the full path to the xbmcdata folder of this repository.

        Replace `wernerb/docker-xbmc-server:gotham` with `wernerb/docker-xbmc-server:frodo` if you use frodo!

        Use this command in your automation scripts or in a crontab. Keep in mind that a library scan can take some time.

        
### Build the container yourself
Replace gotham with master or frodo accordingly if necessary:
    
    $ git checkout gotham
    $ docker build --rm=true -t $(whoami)/docker-xbmc-server .
    
Then proceed with the Quick start section.

### F.A.Q.

__Why Docker?__ 
Docker ensures that xbmc-server can be run on multiple operating systems, as well as making xbmc-server portable. In the case of xbmc-server, a lot of people are having trouble compiling it to work in headless mode for different distributions. The steps to compile xbmc can be viewed in `Dockerfile` and lists the best practises found in this [xbmc forum thread](http://forum.xbmc.org/showthread.php?tid=132919).

__What do the patches do?__
I discovered that the UPnP server in XBMC was very unstable, and crashed when browsing the library in headless mode. The problem was with thumbnail generation for some videos. The patches provided in this repo are automatically applied when compiling for headless mode, and allows xbmc to run without crashing.   

__What versions did you test this with?__

* Docker v0.12: XBMC (13.2ALPHA1 Git:20140607-96b4c73) Gotham
* Docker v0.12: XBMC (12.3 Git:20131212-9ed3e58) Frodo

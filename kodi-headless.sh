#!/bin/bash
#
# Kodi Headless
#
# Control one or more Kodi Headless docker instances.
#
# The MIT License (MIT)
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

source $(dirname $0)/kodi-headless.conf

function usage()
{
   cat <<EOF
usage: $(basename $0) list | run|start|stop|kill|rm|update|clean [container] | shell <container>
   
   list   : show list of created containers
   *      : * all or one container
   shell  : start shell into container. Kodi userdata in:
            /opt/kodi-server/share/kodi/portable_data/userdata/

   update : update database with new episodes/movies
   clean  : cleanup database by removing non-existant episodes/movies
   version: API version

   run  = create 
   rm   = remove

   Script to create, start, stop list multiple Kodi docker instances. Comes
   in handy in multi-profile environments where each user has its own Kodi
   database which needs to be updated. Allows sending database clean/update
   signal to each Kodi docker instance. Comes in handy also when just using
   one Kodi docker instance. Add instances to 'kodi-homes' by creating new
   directories and copy the default xbmcdata/userdata directory in it. For
   exampe see kodi-homes/default. Add instance to kodi-headless.conf. Manage
   the instances using kodi-headless.sh. Require docker and curl.

   Example usage:

   1) ./kodi-headless.sh run default - Create and start docker container for
      default instance.
   2) ./kodi-headless.sh list        - List all docker container instances and
      check up status of each Kodi headless instance running in the container
   3) ./kodi-headless.sh stop        - Stop *ALL* docker container instances

EOF
   exit 1
}

function dcr()
{
   local action=${1}
   local container=${2}
   local list=
   local dir=$(readlink -f $(dirname $0))

   if [ -n "${container}" ]
   then 
      list=${container}
   else
      list=${INSTANCES}
   fi

   for instance in ${list}
   do
      case ${action} in
         run) docker run -d \
                         --name ${instance} \
                         --net=host \
                         --privileged \
                         -v ${dir}/kodi-homes/${instance}:/opt/kodi-server/share/kodi/portable_data \
                         wernerb/docker-xbmc-server;;
           *) docker ${action} ${instance} ;;
      esac
   done
}

function shell()
{
   local container=${1}

   if [ -z ${container} ]
   then
      usage
   fi

   docker exec -it ${container} /bin/bash  
}

function list()
{
   local dir=$(readlink -f $(dirname $0))

   for instance in ${INSTANCES}
   do
      port=$(grep webserverport ${dir}/kodi-homes/${instance}/userdata/advancedsettings.xml | sed 's/[^0-9]//g')
      rpc version ${instance} 2>/dev/null| grep -q '{"version":'
      if [ $? -eq 0 ]
      then
         up="yes"
      else
         up="no"
      fi
      echo "${instance}> up: ${up}, URL: http://$(hostname -f):${port}/"
   done

   echo

   docker ps -a
}

function rpc()
{
   local action=${1}
   local container=${2}
   local list=
   local dir=$(readlink -f $(dirname $0))

   if [ -n "${container}" ]
   then 
      list=${container}
   else
      list=${INSTANCES}
   fi

   method=
   case ${action} in
      update)  method="VideoLibrary.Scan";;
      clean)   method="VideoLibrary.Clean";;
      version) method="JSONRPC.Version";;
      *)       usage;;
   esac

   for instance in ${list}
   do
      echo -n "${instance}: "
      port=$(grep webserverport ${dir}/kodi-homes/${instance}/userdata/advancedsettings.xml | sed 's/[^0-9]//g')
      url="http://$(hostname -f):${port}/jsonrpc"

      curl --user "${KODI_USER}:${KODI_PASSWORD}" \
           --header 'Content-Type: application/json' \
           --data-binary '{"jsonrpc":"2.0","method":"'${method}'","id":"1"}' ${url}

      echo
   done
}

action=${1}
container=${2}
case ${action} in
   list)                   list;;
   run|start|stop|kill|rm) dcr ${action} ${container};;
   update|clean|version)   rpc ${action} ${container};;
   shell)                  shell ${container};;
   *) usage;;
esac


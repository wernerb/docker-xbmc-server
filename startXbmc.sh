docker run -d --networking=false \
  -v /directory/with/xbmcdata:/opt/xbmc-server/portable_data \
  --lxc-conf="lxc.network.type = veth" \
  --lxc-conf="lxc.network.flags = up" \
  --lxc-conf="lxc.network.link = br0" \
  --lxc-conf="lxc.network.ipv4 = 192.168.1.49" \
  --lxc-conf="lxc.network.ipv4.gateway=192.168.1.1" \
  xbmc-server

docker run -d -n=false \
  -lxc-conf="lxc.network.type = veth" \
  -lxc-conf="lxc.network.flags = up" \
  -lxc-conf="lxc.network.link = br0" \
  -lxc-conf="lxc.network.ipv4 = 192.168.1.49" \
  -lxc-conf="lxc.network.ipv4.gateway=192.168.1.1" \
  wernerb/xbmc-server

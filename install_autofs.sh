#install autofs

sudo apt install autofs -y

#PAM von sssd beenden

sudo systemctl disable sssd-pam.socket
sudo systemctl stop sssd-pam.socket
sudo systemctl restart sssd

#autofs /etc/auto.smbcredentials

sudo cat <<EOF > /etc/auto.smbcredentials
username=Administrator
password=P0pAI330VcBF
domain=EIER.SCHAUKELN
EOF


sudo cat <<EOF > /etc/auto.master
#
# Sample auto.master file
# This is a 'master' automounter map and it has the following format:
# mount-point [map-type[,format]:]map [options]
# For details of the format look at auto.master(5).
#
#/misc  /etc/auto.misc
#
# NOTE: mounts done from a hosts map will be mounted with the
#       "nosuid" and "nodev" options unless the "suid" and "dev"
#       options are explicitly given.
#
#/net   -hosts
#
# Include /etc/auto.master.d/*.autofs
# To add an extra map using this mechanism you will need to add
# two configuration items - one /etc/auto.master.d/extra.autofs file
# (using the same line format as the auto.master file)
# and a separate mount map (e.g. /etc/auto.extra or an auto.extra NIS map)
# that is referred to by the extra.autofs file.
#
+dir:/etc/auto.master.d
#
# If you have fedfs set up and the related binaries, either
# built as part of autofs or installed from another package,
# uncomment this line to use the fedfs program map to access
# your fedfs mounts.
#/nfs4  /usr/sbin/fedfs-map-nfs4 nobind
#
# Include central master map if it can be found using
# nsswitch sources.
#
# Note that if there are entries for /net or /misc (as
# above) in the included master map any keys that are the
# same will not be seen as the first read key seen takes
# precedence.
#
+auto.master
/home /etc/auto.home
EOF

sudo cat <<EOF > /etc/auto.home
* -rw,soft,intr fs01.eier.schaukeln:/export/home/&
EOF

#autofs /etc/auto.smbhome 
sudo cat <<EOF > /etc/auto.smbhome
* -fstype=cifs,rw,uid=&,gid=users,credentials=/etc/smb.credentials ://fs01/homes/&
EOF

# restart all services

sudo systemctl restart sssd
sudo systemctl restart autofs


mount | grep /home

# Linux Level 3 Dokumentation

## Active Directory Setup 

### Netzwerkkonfiguration

```bash
nano /etc/network/interfaces      # Netzwerkschnittstellen bearbeiten
service networking restart        # Netzwerkdienste neu starten
ip a                              # IP-Adressen und Netzwerkschnittstellen anzeigen
ping 8.8.8.8                      # Verbindung zu Google DNS prüfen
hostname -A                      # Vollständigen Hostnamen anzeigen
nano /etc/hostname               # Hostnamen konfigurieren
cat /etc/hostname                # Hostnamen anzeigen
nano /etc/hosts                  # Lokale Hostdatei bearbeiten
```

### SSH-Konfiguration

```bash
nano /etc/ssh/sshd_config        # SSH-Serverkonfiguration bearbeiten
service sshd restart             # SSH-Dienst neu starten
```

### Paketverwaltung

```bash
apt update                       # Paketliste aktualisieren
apt upgrade -y                   # Systempakete aktualisieren
sudo apt-get update              # Alternative zu apt update
apt-get update                   # Noch eine Variante
apt install sudo                 # sudo installieren (wenn nicht vorhanden)
```

### DNS und Namensauflösung

```bash
ping -c1 dc01.eier.schaukeln     # DNS-Auflösung testen
nslookup                         # DNS-Abfrage starten
nslookup dns.google              # DNS-Serverabfrage
nslookup dns.google 1.1.1.1      # DNS-Abfrage über spezifischen Server
unlink /etc/resolv.conf          # DNS-Konfigurationsdatei entfernen
sudo unlink /etc/resolv.conf     # Mit Root-Rechten entfernen
nano /etc/resolv.conf            # DNS-Konfiguration bearbeiten
sudo nano /etc/resolv.conf       # Als Root bearbeiten
```

### systemd-resolved deaktivieren

```bash
sudo systemctl disable --now systemd-resolved   # Dienst sofort stoppen und deaktivieren
systemctl disable --now systemd-resolved
systemctl disable systemd-resolved
systemctl disable resolved
systemctl stop systemd-resolved
```

### Netzwerke neu starten

```bash
service systemd-networkd restart    # systemd-Netzwerkdienst neu starten
service networking restart          # Netzwerkdienste neu starten
```

### UFW – Firewallstatus prüfen

```bash
ufw status                         # Status der UFW-Firewall anzeigen
```

### Samba Active Directory Einrichtung

```bash
sudo apt install -y acl attr samba samba-dsdb-modules samba-vfs-modules \
smbclient winbind libpam-winbind libnss-winbind libpam-krb5 krb5-config \
krb5-user dnsutils chrony net-tools
```

```bash
sudo systemctl disable --now smbd nmbd winbind   # Alte Samba-Dienste stoppen
sudo systemctl unmask samba-ad-dc                # AD-Modus freischalten
sudo systemctl enable samba-ad-dc                # AD-Dienst aktivieren
sudo mv /etc/samba/smb.conf /etc/samba/smb.conf.bak   # Alte Konfig sichern
sudo mv /etc/krb5.conf /etc/krb5.conf.bak
sudo samba-tool domain provision --use-rfc2307 --interactive  # AD Domain einrichten
sudo cp /var/lib/samba/private/krb5.conf /etc/krb5.conf       # Neue Kerberos-Datei übernehmen
sudo systemctl start samba-ad-dc
sudo systemctl status samba-ad-dc
```

### Samba testen

```bash
smbclient //localhost/netlogon -U Administrator -c 'ls'  # Verbindung testen
```

### DNS-Tests & Kerberos

```bash
host -t SRV _ldap._tcp.eier.schaukeln
host -t SRV _kerberos._udp.eier.schaukeln
host -t A dc01.eier.schaukeln
kinit administrator        # Kerberos-Ticket abrufen
klist                      # Kerberos-Tickets anzeigen
```

### Benutzer- & Gruppenverwaltung

```bash
sudo samba-tool user create konsti Konsti-9012!
sudo samba-tool user list
sudo samba-tool user edit konsti
sudo samba-tool user setpassword konsti
sudo samba-tool user add leon
sudo samba-tool user add ben
```

```bash
sudo samba-tool group list
sudo samba-tool group add FileAdmin
sudo samba-tool group add Admins
sudo samba-tool group add VPNAdmin
sudo samba-tool group add GatewayAdmin
sudo samba-tool group addmembers Admins konsti
sudo samba-tool group addmembers Domain\ Admins konsti
sudo samba-tool group addmember GatewayAdmins ben
```

### AD-Objekte & GPO-Verwaltung

```bash
sudo samba-tool computer list
sudo samba-tool ou list
sudo samba-tool gpo list
sudo samba-tool gpo create sudoersfile
sudo samba-tool gpo manage sudoers add domain\ admins ALL ALL
sudo samba-tool gpo manage sudoers list
```

### Sonstige Tools & Tests

```bash
pam-auth-update --help     # PAM-Authentifizierungs-Hilfe anzeigen
realm                      # Domain-Join Informationen anzeigen
exit                       # Sitzung verlassen
```




## VPN Server Setup

### Install OpenVPN

```bash
apt update
apt upgrade -y
make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa
/etc/openvpn/easy-rsa/easyrsa build-ca
/etc/openvpn/easy-rsa/easyrsa build-server-full server
/etc/openvpn/easy-rsa/easyrsa gen-dh
openvpn --genkey secret /etc/openvpn/server/ta.key
```

### IP Forwarding (/etc/sysctl.conf)

```text
net.ipv4.ip_forward=1
```

### Create Client Files

```bash
/etc/openvpn/easy-rsa/easyrsa gen-req {client} nopass
/etc/openvpn/easy-rsa/easyrsa sign-req client {client}
```

### Client Files Location on Server after Creation

```text
/etc/openvpn/easy-rsa/pki/ca.crt
/etc/openvpn/server/ta.key
/etc/openvpn/easy-rsa/pki/issued/{client}.crt
/etc/openvpn/easy-rsa/pki/private/{client}.key
```

### Server Config File (/etc/openvpn/server.conf)

```text
port 1194
proto udp
dev tun

ca      /etc/openvpn/easy-rsa/pki/ca.crt
cert    /etc/openvpn/easy-rsa/pki/issued/server.crt
key     /etc/openvpn/easy-rsa/pki/private/server.key  # keep secret
dh      /etc/openvpn/easy-rsa/pki/dh.pem

topology subnet

server 10.9.8.0 255.255.255.0  # internal tun0 connection IP
ifconfig-pool-persist ipp.txt

push "route 192.168.0.0 255.255.255.0"
push "redirect-gateway def1 bypass-dhcp"

keepalive 10 120

tls-auth /etc/openvpn/server/ta.key 0
auth-nocache

cipher AES-256-CBC
data-ciphers AES-256-CBC

persist-key
persist-tun

status /var/log/openvpn/openvpn-status.log

verb 3  # verbose mode

client-to-client
explicit-exit-notify 1
```

### Client Config File (/etc/openvpn/client.conf)

```text
##############################################
# Sample client-side OpenVPN 2.0 config file #
# for connecting to multi-client server.     #
#                                            #
# This configuration can be used by multiple #
# clients, however each client should have   #
# its own cert and key files.                #
#                                            #
# On Windows, you might want to rename this  #
# file so it has a .ovpn extension           #
##############################################

# Specify that we are a client and that we
# will be pulling certain config file directives
# from the server.
client

# Use the same setting as you are using on
# the server.
# On most systems, the VPN will not function
# unless you partially or fully disable
# the firewall for the TUN/TAP interface.
;dev tap
dev tun

# Windows needs the TAP-Win32 adapter name
# from the Network Connections panel
# if you have more than one.  On XP SP2,
# you may need to disable the firewall
# for the TAP adapter.
;dev-node MyTap

# Are we connecting to a TCP or
# UDP server?  Use the same setting as
# on the server.
;proto tcp
proto udp

# The hostname/IP and port of the server.
# You can have multiple remote entries
# to load balance between the servers.
remote 10.132.112.179 1194
;remote my-server-2 1194

# Choose a random host from the remote
# list for load-balancing.  Otherwise
# try hosts in the order specified.
;remote-random

# Keep trying indefinitely to resolve the
# host name of the OpenVPN server.  Very useful
# on machines which are not permanently connected
# to the internet such as laptops.
resolv-retry infinite

# Most clients don't need to bind to
# a specific local port number.
nobind

# Downgrade privileges after initialization (non-Windows only)
;user openvpn
;group openvpn

# Try to preserve some state across restarts.
persist-key
persist-tun

# If you are connecting through an
# HTTP proxy to reach the actual OpenVPN
# server, put the proxy server/IP and
# port number here.  See the man page
# if your proxy server requires
# authentication.
;http-proxy-retry # retry on connection failures
;http-proxy [proxy server] [proxy port #]

# Wireless networks often produce a lot
# of duplicate packets.  Set this flag
# to silence duplicate packet warnings.
;mute-replay-warnings

# SSL/TLS parms.
# See the server config file for more
# description.  It's best to use
# a separate .crt/.key file pair
# for each client.  A single ca
# file can be used for all clients.
ca ca.crt
cert client.crt
key client.key

# Verify server certificate by checking that the
# certificate has the correct key usage set.
# This is an important precaution to protect against
# a potential attack discussed here:
#  http://openvpn.net/howto.html#mitm
#
# To use this feature, you will need to generate
# your server certificates with the keyUsage set to
#   digitalSignature, keyEncipherment
# and the extendedKeyUsage to
#   serverAuth
# EasyRSA can do this for you.
remote-cert-tls server

# If a tls-auth key is used on the server
# then every client must also have the key.
tls-auth ta.key 1

# Select a cryptographic cipher.
# If the cipher option is used on the server
# then you must also specify it here.
# Note that v2.4 client/server will automatically
# negotiate AES-256-GCM in TLS mode.
# See also the data-ciphers option in the manpage
cipher AES-256-CBC

# Enable compression on the VPN link.
# Don't enable this unless it is also
# enabled in the server config file.
#comp-lzo

# Set log file verbosity.
verb 3

# Silence repeating messages
;mute 20
```

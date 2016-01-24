# The Zero image for Pignus
# Build with: appliance-creator -c pignus-zero.ks

%include rpi.ks

selinux --permissive
bootloader --append="console=ttyAMA0 console=tty0"

%post --erroronfail

set -x
set -e

cat >/etc/modules-load.d/libcomposite.conf <<'EOF'
libcomposite
EOF

cat >/etc/udev/rules.d/90-pi.rules  <<'EOF'
SUBSYSTEM=="net", ACTION=="add|change", ENV{DEVTYPE}=="gadget", ENV{NM_UNMANAGED}="0"
SUBSYSTEM=="udc", ACTION=="add|change", TAG+="systemd", ENV{SYSTEMD_WANTS}+="usb-gadget-bind@$env{USB_UDC_NAME}.service"
SUBSYSTEM=="tty", ACTION=="add|change", KERNEL=="ttyGS0", ENV{ID_MM_CANDIDATE}="0", TAG+="systemd", ENV{SYSTEMD_WANTS}+="serial-getty@%k.service"
EOF

cat >/etc/systemd/system/usb-gadget-bind\@.service <<'EOF'
[Unit]
Description=Bind the USB gadget device
After=systemd-modules-load.service
After=sys-kernel-config.mount

[Service]
Type=oneshot
RemainAfterExit=yes

ExecStart=/bin/mkdir /sys/kernel/config/usb_gadget/%I.g1
ExecStart=/bin/sh -c 'echo 0x0525 >/sys/kernel/config/usb_gadget/%I.g1/idVendor'
ExecStart=/bin/sh -c 'echo 0xa4aa >/sys/kernel/config/usb_gadget/%I.g1/idProduct'
ExecStart=/bin/mkdir /sys/kernel/config/usb_gadget/%I.g1/functions/ecm.usb1
ExecStart=/bin/mkdir /sys/kernel/config/usb_gadget/%I.g1/functions/acm.usb1
ExecStart=/bin/mkdir /sys/kernel/config/usb_gadget/%I.g1/configs/c.1
ExecStart=/bin/ln -s /sys/kernel/config/usb_gadget/%I.g1/functions/ecm.usb1 /sys/kernel/config/usb_gadget/%I.g1/configs/c.1
ExecStart=/bin/ln -s /sys/kernel/config/usb_gadget/%I.g1/functions/acm.usb1 /sys/kernel/config/usb_gadget/%I.g1/configs/c.1
ExecStart=/bin/sh -c 'echo %I >/sys/kernel/config/usb_gadget/%I.g1/UDC'

ExecStop=/bin/sh -c 'echo >/sys/kernel/config/usb_gadget/%I.g1/UDC'
ExecStop=/bin/rm /sys/kernel/config/usb_gadget/%I.g1/configs/c.1/ecm.usb1
ExecStop=/bin/rm /sys/kernel/config/usb_gadget/%I.g1/configs/c.1/acm.usb1
ExecStop=/bin/rmdir /sys/kernel/config/usb_gadget/%I.g1/configs/c.1
ExecStop=/bin/rmdir /sys/kernel/config/usb_gadget/%I.g1/functions/ecm.usb1
ExecStop=/bin/rmdir /sys/kernel/config/usb_gadget/%I.g1/functions/acm.usb1
ExecStop=/bin/rmdir /sys/kernel/config/usb_gadget/%I.g1

[Install]
WantedBy=multi-user.target
EOF

cat >/etc/sysconfig/network-scripts/ifcfg-usb0 <<'EOF'
DEVICE=usb0
TYPE=Ethernet
BOOTPROTO=shared
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=usb0
UUID=94a2b569-0897-4a12-99d4-40db2ca3ec17
DEVICE=usb0
ONBOOT=yes
IPV6_PEERDNS=yes
IPV6_PEERROUTES=yes
EOF

%end

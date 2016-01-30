# The Minimal image for Pignus
# Build with: appliance-creator -c pignus-minimal.ks

lang en_US.UTF-8
keyboard us
timezone US/Eastern
auth --useshadow --passalgo sha256
firewall --enabled --service=mdns
xconfig --startxonboot
selinux --enforcing
bootloader --append="console=ttyAMA0 console=tty0 rhgb"

part /boot --size=256 --fstype vfat --label boot
part / --size=2048 --grow --fstype ext4

services --enabled=NetworkManager --disabled=network,firewalld

repo --name=koji --baseurl=https://pignus.computer/pub/linux/pignus/releases/$releasever/Everything/$basearch/os/

%packages
@core
pignus-release
kernel
uboot-tools
uboot-images-armv7
vc4-firmware
extlinux-bootloader
plymouth-theme-spinner
NetworkManager-wifi
# Not strictly needed, but useful: Out boot is a msdos filesystem and this
# is useful for automated systemd-triggered check
dosfstools
# The device has no RTC
chrony
%end

%post --erroronfail
# Add drivers to initrd
V=$(ls /lib/modules)
cat >/etc/dracut.conf.d/bcm2835.conf <<EOF
add_drivers+="sdhci_bcm2835 sdhci_pltfm"
EOF
dracut -v -f /boot/initramfs-$V.img $V

# Install VideoCore firmware
cp -a /usr/share/vc4-firmware/* /boot

# Install bootloader
cp /usr/share/uboot/rpi/u-boot.bin /boot/kernel.img
cp /usr/share/uboot/rpi_2/u-boot.bin /boot/kernel7.img

# Support more boards
for K in /boot/*/bcm2835-rpi-b.dtb
do
	for M in rpi-a-plus rpi-b-rev2 rpi-a
	do
		D=$(echo $K |sed s/rpi-b.dtb\$/$M.dtb/)
		[ -f $D ] || cp $K $D
	done
done

# Remove root password
passwd -d root
%end

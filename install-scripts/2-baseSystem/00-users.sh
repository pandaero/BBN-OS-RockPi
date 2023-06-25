#!/bin/bash -e
apt-get -y -q install sudo policykit-1

## Force keyboard layout to be EN US by default.
sed -i "s/XKBLAYOUT=.*/XKBLAYOUT=\"us\"/g" /etc/default/keyboard

## Set root password.
echo 'root:changeme' | chpasswd

DPASS=$(echo 'changeme' | openssl passwd -6 -stdin)
echo "user:$DPASS" > /boot/userconf.txt

## Remove default user (if any).
oldUser=$(grep 1000:1000 /etc/passwd | cut -f1 -d:)
if [[ -n $oldUser ]]; then
	echo "Removing user $oldUser"
	userdel -r -f "$oldUser"
else
	echo "No default user found !"
fi

## Add default user.
adduser --uid 1000 --home /home/user --quiet --disabled-password -gecos "lysmarine" user
echo 'user:changeme' | chpasswd
echo "user ALL=(ALL:ALL) ALL" >> /etc/sudoers

groupadd -r -f bluetooth
groupadd -r -f i2c
groupadd -r -f spi
groupadd -r -f gpio

usermod -a -G netdev user
usermod -a -G adm user
usermod -a -G tty user
usermod -a -G i2c user
usermod -a -G spi user
usermod -a -G gpio user
usermod -a -G sudo user
usermod -a -G video user
usermod -a -G input user     # for evdev-rce
usermod -a -G audio user
usermod -a -G dialout user
usermod -a -G lp user
#usermod -a -G scanner user
usermod -a -G cdrom user
usermod -a -G plugdev user
usermod -a -G fax user
usermod -a -G voice user
usermod -a -G bluetooth user
usermod -a -G games user
usermod -a -G users user


groupadd -r lirc
useradd -r -g lirc -d /var/lib/lirc -s /usr/bin/nologin -c "LIRC daemon user" lirc
usermod -a -G input lirc

## Manage the permissions and privileges.
if [[ -d /etc/polkit-1 ]]; then
	echo "polkit found, adding rules"
	install -d "/etc/polkit-1/localauthority/50-local.d"
	install -v "$FILE_FOLDER"/mount.pkla  "/etc/polkit-1/localauthority/50-local.d/"
	install -v "$FILE_FOLDER"/all_all_users_to_shutdown_reboot.pkla "/etc/polkit-1/localauthority/50-local.d/"
	install -d "/etc/polkit-1/localauthority/10-vendor.d"
	install -v "$FILE_FOLDER"/org.freedesktop.NetworkManager.pkla  "/etc/polkit-1/localauthority/10-vendor.d/"
fi

if [[ -f /etc/sudoers.d/010_pi-nopasswd ]]; then # Remove no-pwd sudo to user pi.
	rm /etc/sudoers.d/010_pi-nopasswd
fi

echo 'PATH="/sbin:/usr/sbin:$PATH"' >> /home/user/.profile # Give user capability to halt and reboot.

if [ -f /root/.not_logged_in_yet ]; then # Disable first login script.
	rm /root/.not_logged_in_yet
fi

## Prevent the creation of useless home folders on first boot.
if [ -f /etc/xdg/user-dirs.defaults ]; then
  sed -i 's/^TEMPLATES=/#&/'   /etc/xdg/user-dirs.defaults
  sed -i 's/^PUBLICSHARE=/#&/' /etc/xdg/user-dirs.defaults
#  sed -i 's/^DESKTOP=/#&/'     /etc/xdg/user-dirs.defaults
#  sed -i 's/^MUSIC=/#&/'       /etc/xdg/user-dirs.defaults
#  sed -i 's/^PICTURES=/#&/'    /etc/xdg/user-dirs.defaults
#  sed -i 's/^VIDEOS=/#&/'      /etc/xdg/user-dirs.defaults
fi

ln -s /root /home/root # for openplotter

#!/bin/bash -e

## Needed to allow the service file start X
install  -v "$FILE_FOLDER"/Xwrapper.config "/etc/X11/"

arch=$(dpkg --print-architecture)

if [ "$LMOS" == Raspbian ]; then
  apt-get -q -y install xserver-xorg-video-fbturbo
fi

if [ "$LMOS" == Armbian ]; then
	apt-get -q -y install xserver-xorg-legacy
fi

# Install touchscreen drivers, etc
apt-get -q -y install xserver-xorg-input-libinput xinput libinput-tools xinput-calibrator  \
 budgie-desktop budgie-weathershow-applet budgie-rotation-lock-applet \
 gstreamer1.0-x gstreamer1.0-omx gstreamer1.0-plugins-base \
 gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-alsa \
 gstreamer1.0-libav alsa-utils libavahi-compat-libdnssd-dev git \
 xbacklight lxappearance gmrun xsettingsd xserver-xorg \
 xinit cpanminus perl-base wmctrl openbox arandr gnome-clocks gnome-todo \
 dialog lxterminal network-manager-gnome system-config-printer \
 lxterminal gpsbabel file-roller lxtask thunar git adapta-gtk-theme \
 libqt5quickwidgets5 libqt5widgets5 libqt5gui5 libqt5webkit5 \
 libqt5sql5 libqt5printsupport5 libqt5network5 libqt5serialport5 \
 libqt5svg5 libqt5opengl5 libqt5test5 libqt5xml5 libqt5qml5 qml-module-qtquick-controls libsndfile1


install -o 1000 -g 1000 -d /home/user/.local
install -o 1000 -g 1000 -d /home/user/.local/share
install -o 1000 -g 1000 -d /home/user/.local/share/desktop-directories
install -o 1000 -g 1000 -d /home/user/.local/share/applications
install -o 1000 -g 1000 -d /home/user/.local/share/icons
install -o 1000 -g 1000 -d /home/user/.local/share/sounds

# Openbox
install -o 1000 -g 1000 -d /home/user/.config
install -o 1000 -g 1000 -d /home/user/.config/openbox
install -o 1000 -g 1000 -v "$FILE_FOLDER"/autostart /home/user/.config/openbox/

# Thunar file manager
install -o 1000 -g 1000 -d /home/user/.config/xfce4
install -o 1000 -g 1000 -d /home/user/.config/xfce4/xfconf
install -o 1000 -g 1000 -d /home/user/.config/xfce4/xfconf/xfce-perchannel-xml
install -o 1000 -g 1000 -v "$FILE_FOLDER"/thunar.xml /home/user/.config/xfce4/xfconf/xfce-perchannel-xml/

# Menus
install -o 1000 -g 1000 -d /home/user/.config/menus
install -o 1000 -g 1000 -v "$FILE_FOLDER"/gnome-applications.menu /home/user/.config/menus/gnome-applications.menu-orig
install -o 1000 -g 1000 -v "$FILE_FOLDER"/lysmarine-applications.menu /home/user/.config/menus/lysmarine-applications.menu-orig
install -o 1000 -g 1000 -v "$FILE_FOLDER"/lysmarine-applications.menu /home/user/.config/menus/gnome-applications.menu
install -o 1000 -g 1000 -v "$FILE_FOLDER"/navigation.directory /home/user/.local/share/desktop-directories/
install -o 1000 -g 1000 -v "$FILE_FOLDER"/openplotter.directory /home/user/.local/share/desktop-directories/

install -m 755 -v "$FILE_FOLDER"/bbn-commands.sh /usr/local/bin/bbn-commands

install -d /usr/local/share/applications
install -v "$FILE_FOLDER"/commands.desktop /usr/local/share/applications/

install -d /etc/budgie-desktop
install -m 644 -v "$FILE_FOLDER"/panel.ini /etc/budgie-desktop/


# Make some room for the rest of the build script
apt-get clean

## Install base desktop apps.
if [ "$LMOS" == Raspbian ]; then
	apt-get install -y -q chromium-browser
else
	apt-get install -y -q chromium
fi

# Adobe Flash Player. Copyright 1996-2015. Adobe Systems Incorporated. All Rights Reserved.
# TODO:
#DEBIAN_FRONTEND=noniterractive apt-get -o Dpkg::Options:=="--force-confnew" -q -y install rpi-chromium-mods

apt-get install -y -q lxterminal gpsbabel file-roller lxtask thunar

#apt-get install -y -q pcmanfm mousepad

# force polkit agent to start with openbox (this is needed for nm-applet hotspot)
sed -i '/^OnlyShowIn=/ s/$/GNOME;/' /etc/xdg/autostart/polkit-gnome-authentication-agent-1.desktop

install -v "$FILE_FOLDER"/scale-up.desktop /usr/local/share/applications/
install -v "$FILE_FOLDER"/scale-down.desktop /usr/local/share/applications/

install -v -m 755 "$FILE_FOLDER"/scale-up /usr/local/bin/
install -v -m 755 "$FILE_FOLDER"/scale-down /usr/local/bin/

install -v -m 755 "$FILE_FOLDER"/twofing-detect.sh /usr/local/sbin/twofing-detect

#!/bin/bash -e


## Create pypilot user to run the services.
if [ ! -d /home/pypilot ]; then
	echo "Creating pypilot user"
	adduser --home /home/pypilot --gecos --system --disabled-password --disabled-login pypilot
	chmod 775 /home/pypilot
fi

usermod -a -G tty pypilot
usermod -a -G i2c pypilot
usermod -a -G spi pypilot
usermod -a -G gpio pypilot
usermod -a -G dialout pypilot
usermod -a -G plugdev pypilot
usermod -a -G pypilot user

# Op way
apt-get install -y -q --no-install-recommends git  build-essential python3 python3-pip python3-dev python3-setuptools libpython3-dev \
  python3-wheel python3-numpy python3-scipy swig python3-ujson \
  python3-serial python3-pyudev python3-pil python3-flask python3-engineio \
  python3-opengl python3-wxgtk4.0 \
  libffi-dev python3-gevent python3-zeroconf watchdog lirc gpiod lm-sensors ir-keytable \
  python3-opengl \
  python3-rpi.gpio apt-offline \
  libelf1 libftdi1-2 libhidapi-libusb0 libusb-0.1-4 libusb-1.0-0 \
  meson cmake make acl octave # https://kingtidesailing.blogspot.com/2016/02/how-to-setup-mpu-9250-on-raspberry-pi_25.html

systemctl disable watchdog
systemctl disable lircd

usermod -a -G lirc user
usermod -a -G lirc pypilot

install -v -m 0644 "$FILE_FOLDER"/60-watchdog.rules "/etc/udev/rules.d/60-watchdog.rules"

# performance of the build, make parallel jobs
export MAKEFLAGS='-j 4'

if [ "$LMARCH" == 'arm64' ]; then
  pip3 install pywavefront pyglet gps gevent-websocket websocket-client importlib_metadata \
    python-socketio flask-socketio wmm2020 
else
  apt-get install -y -q python3-flask-socketio
  pip3 install pywavefront pyglet gps gevent-websocket importlib_metadata "python-socketio<5" wmm2020
fi

if [ "$LMOS" == 'Raspbian' ] && [ "$LMARCH" == 'armhf' ]; then
  wget https://project-downloads.drogon.net/wiringpi-latest.deb
  dpkg -i wiringpi-latest.deb && rm wiringpi-latest.deb
fi

#if [ $LMARCH == 'arm64' ]; then
#  wget https://github.com/guation/WiringPi-arm64/releases/download/2.61-g/wiringpi-2.61-g.deb
#  dpkg -i wiringpi-2.61-g.deb && rm wiringpi-2.61-g.deb
#fi

pushd ./stageCache
  # Install RTIMULib2 as it's a dependency of pypilot
  if [[ ! -d ./RTIMULib2 ]]; then
    git clone --depth=1 https://github.com/seandepagnier/RTIMULib2
  fi
  echo "Build and install RTIMULib2"

  pushd ./RTIMULib2/Linux/RTIMULibCal
    curl -o Makefile https://raw.githubusercontent.com/bareboat-necessities/my-bareboat/master/RTIMULibCal/Makefile
    make -j 4
    cp Output/RTIMULibCal /usr/local/bin/
    make clean
    install -v -o user -g pypilot -m 0775 -d "/home/user/kts"
    cp -r ../../RTEllipsoidFit /home/user/kts/
    #git clone --depth=1 https://github.com/bareboat-necessities/kts-scripts
    #cp -r kts-scripts /home/user/kts/scripts
    #rm -rf kts-scripts
    chown -R user:pypilot /home/user/kts
  popd

  pushd ./RTIMULib2/Linux/python
    python3 setup.py install
    python3 setup.py clean --all
  popd

#  apt-get install -yq python3-rtimulib2-pypilot

# TODO:
  if [ 1 == 0 ]; then
  
  echo "Get pypilot"
  if [[ ! -d ./pypilot ]]; then
    git clone https://github.com/pypilot/pypilot.git
    cd pypilot
    git checkout 8b40189875c3f947e7a893a1a987e837b3dbc104 # Jan 11, 2023
    cd ..
    git clone --depth=1 https://github.com/pypilot/pypilot_data.git
    cp -rv ./pypilot_data/* ./pypilot
    rm -rf ./pypilot_data
    pushd ./pypilot
      sed -i 's/from importlib.metadata/from importlib_metadata/' dependencies.py || true
      sed -i "s/ugfx_libraries=\[\]/ugfx_libraries=\['wiringPi'\]/" setup.py
      sed -i "s/ugfx_defs = \[\]/ugfx_defs = \['-DWIRINGPI'\]/" setup.py 
      git clone --depth=1 https://github.com/wiringPi/wiringPi
      cd wiringPi
      ./build
      cd ..
      python3 setup.py build
    popd
  fi
  pushd /usr/local/lib/python3.9/dist-packages/wmm2020
    mkdir build
    cd build
    cmake ..
    make -j 4
    rm -f ./*.o
    cd ..
  popd
  ## Build and install pypilot
  pushd ./pypilot
    python3 setup.py install
    python3 setup.py clean --all
  popd

  fi # TODO
popd

# TODO
if [ 1 == 0 ]; then

## Install the service files
install -v -m 0644 "$FILE_FOLDER"/pypilot@.service "/etc/systemd/system/"
install -v -m 0644 "$FILE_FOLDER"/pypilot_boatimu.service "/etc/systemd/system/"
install -v -m 0644 "$FILE_FOLDER"/pypilot_web.service "/etc/systemd/system/"
install -v -m 0644 "$FILE_FOLDER"/pypilot_hat.service "/etc/systemd/system/"
install -v -m 0644 "$FILE_FOLDER"/pypilot_detect.service "/etc/systemd/system/"

sed -i 's/_http._tcp.local./_signalk-http._tcp.local./' "$(find /usr/local/lib -name signalk.py)" || true
#sed -i 's/ttyAMA0/serial1/' "$(find /usr/local/lib -name serialprobe.py)" || true
#sed -i "s/'ttyAMA'//" "$(find /usr/local/lib -name serialprobe.py)" || true

#cp "$FILE_FOLDER"/wind.py "$(find /usr/local/lib -name wind.py)" || true

systemctl disable pypilot_boatimu.service
systemctl disable pypilot_hat.service
systemctl enable pypilot@pypilot.service                               # listens on tcp 20220 and 23322
systemctl enable pypilot_web.service                                   # listens on tcp 8080
systemctl enable pypilot_detect.service                                # tries to detect pypilot hardware (hat)

fi # TODO

## Install the user config files
install -v -o pypilot -g pypilot -m 0775 -d "/home/pypilot/.pypilot"
install -v -o pypilot -g pypilot -m 0775 -d "/home/pypilot/.pypilot/ugfxfonts"
install -v -o pypilot -g pypilot -m 0775 -d "/home/tc"
ln -s /home/pypilot/.pypilot "/home/user/.pypilot"
ln -s /home/pypilot/.pypilot "/home/tc/.pypilot"
setfacl -d -m g:pypilot:rw "/home/pypilot"
setfacl -d -m g:pypilot:rw "/home/pypilot/.pypilot"
setfacl -d -m g:pypilot:rw "/home/pypilot/.pypilot/ugfxfonts"
setfacl -d -m g:pypilot:rw "/home/tc"

install -v -o pypilot -g pypilot -m 0664 "$FILE_FOLDER"/signalk.conf "/home/pypilot/.pypilot/"
install -v -o pypilot -g pypilot -m 0664 "$FILE_FOLDER"/webapp.conf "/home/pypilot/.pypilot/"
install -v -o pypilot -g pypilot -m 0664 "$FILE_FOLDER"/pypilot_client.conf "/home/pypilot/.pypilot/"
install -v -o pypilot -g pypilot -m 0664 "$FILE_FOLDER"/pypilot.conf "/home/pypilot/.pypilot/"
install -v -o pypilot -g pypilot -m 0664 "$FILE_FOLDER"/hat.conf "/home/pypilot/.pypilot/"
install -v -o pypilot -g pypilot -m 0664 "$FILE_FOLDER"/blacklist_serial_ports "/home/pypilot/.pypilot/"
install -v -o pypilot -g pypilot -m 0664 "$FILE_FOLDER"/serial_ports "/home/pypilot/.pypilot/serial_ports.sample"
install -v -o pypilot -g pypilot -m 0664 "$FILE_FOLDER"/servodevice "/home/pypilot/.pypilot/servodevice.sample"
install -v -o pypilot -g pypilot -m 0664 "$FILE_FOLDER"/nmea0device "/home/pypilot/.pypilot/nmea0device.sample"


if [[ -f /home/pypilot/.pypilot/pypilot.conf ]]; then
  chmod 664 /home/pypilot/.pypilot/pypilot.conf
  chown pypilot:pypilot /home/pypilot/.pypilot/pypilot.conf
fi

install -v -g pypilot -m 0664 "$FILE_FOLDER"/lircd.conf "/etc/lirc/lircd.conf.d/lircd-pypilot.conf"

## Install The .desktop files
install -d /usr/local/share/applications
install -v "$FILE_FOLDER"/pypilot_calibration.desktop "/usr/local/share/applications/"
install -v "$FILE_FOLDER"/pypilot_control.desktop "/usr/local/share/applications/"

install -m 755 "$FILE_FOLDER"/pypilot-restart "/usr/local/sbin/pypilot-restart"
install -m 755 "$FILE_FOLDER"/pypilot_detect.sh "/usr/local/sbin/pypilot_detect"

## Give permission to sudo chrt without a password for the user pypilot.
{
  echo ""
  echo 'pypilot ALL=(ALL) NOPASSWD: /usr/bin/chrt'
  echo 'pypilot ALL=(ALL) NOPASSWD: /usr/bin/stty'
  echo 'user ALL=(ALL) NOPASSWD: /usr/local/sbin/pypilot-restart'
} >>/etc/sudoers

## Reduce excessive logging
sed '1 i :msg, contains, "autopilot failed to read imu at time" stop' -i /etc/rsyslog.conf
sed '1 i :msg, contains, "No IMU detected" stop' -i /etc/rsyslog.conf
sed '1 i :msg, contains, "No IMU Detected" stop' -i /etc/rsyslog.conf
sed '1 i :msg, contains, "Failed to open I2C bus" stop' -i /etc/rsyslog.conf
sed '1 i :msg, contains, "Using fusion algorithm Kalman" stop' -i /etc/rsyslog.conf

# prevent pypilot from changing port
if [ -f  /etc/systemd/system/pypilot_web.service ]; then
  sed -i 's/8000/8080/' /etc/systemd/system/pypilot_web.service || true
fi

# TODO: temp patch
install -m 644 "$FILE_FOLDER"/wind.py "$(find /usr/local/lib -name wind.py)"

# TODO: not needed after changing pypilot service working directory
echo > /RTIMULib.ini
chown pypilot:pypilot /RTIMULib.ini
chmod 664 /RTIMULib.ini

wget https://github.com/bareboat-necessities/lysmarine_gen/releases/download/vTest/avrdude_7.0-20221004-1_arm64.deb
dpkg -i avrdude_7*.deb
rm -f avrdude_7*.deb
ln -s /etc/avrdude.conf /usr/local/etc/avrdude.conf

# Fix displaying 3D boat in pypilot calibration tool
pip3 install pyglet==1.5.27

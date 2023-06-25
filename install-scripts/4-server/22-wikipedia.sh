#!/bin/bash -e

apt-get install -y liblzma5 libicu67 libzstd1 libxapian30 libcurl3-gnutls libpugixml1v5 aria2

if [ "$LMARCH" == 'arm64' ]; then
  wget https://github.com/bareboat-necessities/lysmarine_gen/releases/download/vTest/libzim7_7.2.0.0_arm64.deb
  wget https://github.com/bareboat-necessities/lysmarine_gen/releases/download/vTest/libkiwix10_10.1.1.0_arm64.deb
  wget https://github.com/bareboat-necessities/lysmarine_gen/releases/download/vTest/kiwix-tools_3.3.0.0_arm64.deb
  dpkg -i libzim7_*.deb libkiwix10_*.deb kiwix-tools_*.deb
  rm libzim7_*.deb libkiwix10_*.deb kiwix-tools_*.deb
fi

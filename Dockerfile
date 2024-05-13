FROM atrkulja/x86_64-on-arm64
VOLUME ["/mnt/vrising/server", "/mnt/vrising/persistentdata"]

# install dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y curl apt-utils

# install necessary libs for crossplay
RUN apt-get install -y libpulse0 libpulse-dev libatomic1 libc6

WORKDIR /home/wine-build
# install wine
COPY wine-stable-amd64_9.0.0.0~bookworm-1_amd64.deb .
COPY wine-stable_9.0.0.0~bookworm-1_amd64.deb .
COPY wine-stable-i386_9.0.0.0~bookworm-1_i386.deb .
RUN dpkg-deb -x wine-stable-amd64_9.0.0.0~bookworm-1_amd64.deb wine-installer && \
    dpkg-deb -x wine-stable_9.0.0.0~bookworm-1_amd64.deb wine-installer && \
    dpkg-deb -x wine-stable-i386_9.0.0.0~bookworm-1_i386.deb wine-installer && \
    mv wine-installer/opt/wine* /home/wine

# download wine dependencies
RUN dpkg --add-architecture armhf &&  apt-get update # enable multi-arch && \
    apt-get install -y libasound2:armhf libc6:armhf libglib2.0-0:armhf libgphoto2-6:armhf libgphoto2-port12:armhf \
    libgstreamer-plugins-base1.0-0:armhf libgstreamer1.0-0:armhf libldap-2.4-2:armhf libopenal1:armhf libpcap0.8:armhf \
    libpulse0:armhf libsane1:armhf libudev1:armhf libusb-1.0-0:armhf libvkd3d1:armhf libx11-6:armhf libxext6:armhf \
    libasound2-plugins:armhf ocl-icd-libopencl1:armhf libncurses6:armhf libncurses5:armhf libcap2-bin:armhf libcups2:armhf \
    libdbus-1-3:armhf libfontconfig1:armhf libfreetype6:armhf libglu1-mesa:armhf libglu1:armhf libgnutls30:armhf \
    libgssapi-krb5-2:armhf libkrb5-3:armhf libodbc1:armhf libosmesa6:armhf libsdl2-2.0-0:armhf libv4l-0:armhf \
    libxcomposite1:armhf libxcursor1:armhf libxfixes3:armhf libxi6:armhf libxinerama1:armhf libxrandr2:armhf \
    libxrender1:armhf libxxf86vm1 libc6:armhf libcap2-bin:armhf # to run wine-i386 through box86:armhf on aarch64

RUN apt-get install -y libasound2:arm64 libc6:arm64 libglib2.0-0:arm64 libgphoto2-6:arm64 libgphoto2-port12:arm64 \
    libgstreamer-plugins-base1.0-0:arm64 libgstreamer1.0-0:arm64 libldap-2.4-2:arm64 libopenal1:arm64 libpcap0.8:arm64 \
    libpulse0:arm64 libsane1:arm64 libudev1:arm64 libunwind8:arm64 libusb-1.0-0:arm64 libvkd3d1:arm64 libx11-6:arm64 libxext6:arm64 \
    ocl-icd-libopencl1:arm64 libasound2-plugins:arm64 libncurses6:arm64 libncurses5:arm64 libcups2:arm64 \
    libdbus-1-3:arm64 libfontconfig1:arm64 libfreetype6:arm64 libglu1-mesa:arm64 libgnutls30:arm64 \
    libgssapi-krb5-2:arm64 libjpeg62-turbo:arm64 libkrb5-3:arm64 libodbc1:arm64 libosmesa6:arm64 libsdl2-2.0-0:arm64 libv4l-0:arm64 \
    libxcomposite1:arm64 libxcursor1:arm64 libxfixes3:arm64 libxi6:arm64 libxinerama1:arm64 libxrandr2:arm64 \
    libxrender1:arm64 libxxf86vm1:arm64 libc6:arm64 libcap2-bin:arm64

RUN apt-get install libstb0 -y && \
    apt-get install -y wget && \
    apt-get install -y xvfb && \
    mkdir /home/Downloads && \
    cd /home/Downloads && \
    wget -r -l1 -np -nd -A "libfaudio0_*~bpo10+1_i386.deb" http://ftp.us.debian.org/debian/pool/main/f/faudio/ # Download libfaudio i386 no matter its version number && \
    dpkg-deb -xv libfaudio0_*~bpo10+1_i386.deb libfaudio && \
    cp -TRv libfaudio/usr/ /usr/ && \
    rm libfaudio0_*~bpo10+1_i386.deb && \
    rm -rf libfaudio 

# Install symlinks
RUN ln -s /home/wine/bin/wine /usr/local/bin/wine && \
    ln -s /home/wine/bin/wine64 /usr/local/bin/wine64 && \
    ln -s /home/wine/bin/wineboot /usr/local/bin/wineboot && \
    ln -s /home/wine/bin/winecfg /usr/local/bin/winecfg && \
    ln -s /home/wine/bin/wineserver /usr/local/bin/wineserver && \
    chmod +x /usr/local/bin/wine /usr/local/bin/wine64 /usr/local/bin/wineboot /usr/local/bin/winecfg /usr/local/bin/wineserver 

# setup steam user
#RUN useradd -m steam
WORKDIR /home/steam
#USER steam

# download steamcmd
RUN mkdir steamcmd && cd steamcmd && \
    curl "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# start steamcmd to force it to update itself
RUN ./steamcmd/steamcmd.sh +quit && \
    mkdir -pv /home/steam/.steam/sdk32/ && \
    ln -s /home/steam/steamcmd/linux32/steamclient.so /home/steam/.steam/sdk32/steamclient.so

COPY start.sh /start.sh
RUN chmod +x /start.sh
CMD ["/start.sh"]

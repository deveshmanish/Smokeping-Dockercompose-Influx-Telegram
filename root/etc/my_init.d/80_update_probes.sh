#!/bin/bash

SMOKELIB=/opt/smokeping/lib/Smokeping

logger -s -t $0 "Updating probes..."
curl -L -o /tmp/speedtest.pm https://github.com/mad-ady/smokeping-speedtest/raw/master/speedtest.pm
curl -L -o /tmp/speedtestcli.pm https://github.com/mad-ady/smokeping-speedtest/raw/master/speedtestcli.pm
curl -L -o /tmp/YoutubeDL.pm https://github.com/mad-ady/smokeping-youtube-dl/raw/master/YoutubeDL.pm
curl -L -o /tmp/WifiParam.pm https://github.com/mad-ady/smokeping-wifi-param/raw/master/WifiParam.pm

for file in speedtest.pm speedtestcli.pm YoutubeDL.pm WifiParam.pm;
do
    if [ -s "/tmp/$file" ]; then
        mv "/tmp/$file" "$SMOKELIB/probes/$file"
    fi
done

logger -s -t $0 "Updating youtube-dl..."
curl -L -o /tmp/youtube-dl https://yt-dl.org/downloads/latest/youtube-dl

for file in youtube-dl;
do
    if [ -s "/tmp/$file" ]; then
        mv "/tmp/$file" "/usr/local/bin/$file"
        chmod a+x /usr/local/bin/$file
    fi
done

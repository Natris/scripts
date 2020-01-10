#!/bin/bash

eval GATHER="~/Documents/avast_gather"

rm -rf "$GATHER"
mkdir -p "$GATHER"

exec &> >(tee -a "$GATHER/gather.log")



echo "sampling avast processes"
sudo /usr/bin/sample com.avast.proxy -f "$GATHER/avast_proxy.sample"
sudo /usr/bin/sample com.avast.fileshield -f "$GATHER/avast_fileshield.sample"
sudo /usr/bin/sample com.avast.service -f "$GATHER/avast_service.sample"
sudo /usr/bin/sample com.avast.daemon -f "$GATHER/avast_daemon.sample"

#sample browser processes
for i in $(ps -e|grep "Contents/MacOS/Google Chrome"|grep -v " grep "|awk '{print $1}'); do echo "sampling google chrome $i:"; sudo /usr/bin/sample $i 3 -f "$GATHER/google_chrome$i.sample";  done
for i in $(ps -e|grep Firefox|grep "Contents/MacOS/firefox"|grep -v " grep "|awk '{print $1}'); do echo "sampling firefox $i:"; sudo /usr/bin/sample $i 3 -f "$GATHER/firefox$i.sample";  done
for i in $(ps -e|grep Firefox|grep "Contents/MacOS/plugin-container.app/Contents/MacOS/plugin-container"|grep -v " grep "|awk '{print $1}'); do echo "sampling firefox plugin container $i:"; sudo /usr/bin/sample $i 3 -f "$GATHER/firefox_plugin_cont$i.sample";  done
for i in $(ps -e|grep "Contents/MacOS/Safari"|grep -v " grep "|awk '{print $1}'); do echo "sampling safari $i:"; sudo /usr/bin/sample $i 3 -f "$GATHER/safari$i.sample";  done
for i in $(ps -e|grep "Contents/MacOS/com.apple.WebKit"|grep -v " grep "|awk '{print $1}'); do echo "sampling webkit $i:"; sudo /usr/bin/sample $i 3 -f "$GATHER/webkit$i.sample";  done

#sample Finder
for i in $(ps -e|grep "Contents/MacOS/Finder"|grep -v " grep "|awk '{print $1}'); do echo "sampling Finder $i:"; sudo /usr/bin/sample $i 3 -f "$GATHER/finder$i.sample";  done

#generate support package
SUPPORT_PKG="$(/Applications/Avast.app/Contents/Backend/scripts/com.avast.supportpkg)"
if [ -f "$SUPPORT_PKG" ]; then mv "$SUPPORT_PKG" "$GATHER/support_from_gather.zip"; fi


echo "script gather.sh has finished gathering data"

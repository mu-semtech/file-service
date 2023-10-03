#!/bin/bash

# Workaround for outdated Debian distro
rm -rf /etc/apt/sources.list
echo "deb [trusted=yes] http://archive.debian.org/debian/ stretch main" >> /etc/apt/sources.list
echo "deb-src [trusted=yes] http://archive.debian.org/debian/ stretch main" >> /etc/apt/sources.list
echo "deb [trusted=yes] http://archive.debian.org/debian/ stretch-backports main" >> /etc/apt/sources.list
echo "deb [trusted=yes] http://archive.debian.org/debian-security/ stretch/updates main" >> /etc/apt/sources.list
echo "deb-src [trusted=yes] http://archive.debian.org/debian-security/ stretch/updates main" >> /etc/apt/sources.list

apt-get update && apt-get install -y libmagic-dev

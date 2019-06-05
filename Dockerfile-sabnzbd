FROM linuxserver/sabnzbd:latest
MAINTAINER xzKinGzxBuRnzx

ARG DEBIAN_FRONTEND=noninteractive

RUN \
  apt-get update && \
  apt-get -y install ffmpeg && \
  apt-get clean && \
  mkdir -p /config/scripts /app/M4V-Converter

COPY M4V-Converter.sh default.conf README.md LICENSE docker/sabnzbd/sabnzbd.sh /app/M4V-Converter/
COPY docker/sabnzbd/root /
COPY docker/sabnzbd/sabnzbd.ini /defaults/

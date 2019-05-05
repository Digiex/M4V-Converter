FROM linuxserver/nzbget:latest
MAINTAINER xzKinGzxBuRnzx

RUN \
  apk add --no-cache --update ffmpeg && \
  mkdir -p /app/M4V-Converter && \
  sed -i -e "s#\(ScriptDir=\).*#\1/config/scripts#g" /app/nzbget/share/nzbget/nzbget.conf

COPY M4V-Converter.sh /app/M4V-Converter/
COPY default.conf /app/M4V-Converter/
COPY README.md /app/M4V-Converter/
COPY LICENSE /app/M4V-Converter/

COPY docker/nzbget/root /

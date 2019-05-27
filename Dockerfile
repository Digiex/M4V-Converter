FROM alpine:3.9
MAINTAINER xzKinGzxBuRnzx

RUN \
  mkdir -p /app/M4V-Converter && \
  apk add --no-cache bash ffmpeg

COPY M4V-Converter.sh default.conf README.md LICENSE /app/M4V-Converter/
ENTRYPOINT ["/app/M4V-Converter/M4V-Converter.sh"]

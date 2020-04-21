FROM alpine:latest
MAINTAINER xzKinGzxBuRnzx

RUN \
  mkdir /mp4 && \
  apk add --no-cache bash jq bc mediainfo ffmpeg

COPY mp4.sh README.md LICENSE /mp4/
ENTRYPOINT ["/mp4/mp4.sh"]

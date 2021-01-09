FROM alpine:latest
MAINTAINER xzKinGzxBuRnzx

RUN \
  mkdir /mp4 && \
  apk add --no-cache bash jq ffmpeg

COPY mp4.sh README.md LICENSE /mp4/

RUN chmod +x /mp4/mp4.sh

ENTRYPOINT ["/mp4/mp4.sh"]

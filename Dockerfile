FROM alpine:latest
MAINTAINER xzKinGzxBuRnzx

RUN apk add --no-cache bash jq ffmpeg

COPY mp4.sh /

RUN chmod +x /mp4.sh

ENTRYPOINT ["/mp4.sh"]

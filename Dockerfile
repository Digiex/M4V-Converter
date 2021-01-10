FROM alpine:latest
MAINTAINER xzKinGzxBuRnzx

ENV NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"

RUN apk add --no-cache bash jq ffmpeg

COPY mp4.sh /

RUN chmod +x /mp4.sh

ENTRYPOINT ["/mp4.sh"]

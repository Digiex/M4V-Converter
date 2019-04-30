FROM jrottenberg/ffmpeg
MAINTAINER xzKinGzxBuRnzx

RUN mkdir -p /app/M4V-Converter

COPY M4V-Converter.sh /app/M4V-Converter/
COPY default.conf /app/M4V-Converter/
COPY README.md /app/M4V-Converter/
COPY LICENSE /app/M4V-Converter/

ENTRYPOINT ["/app/M4V-Converter/M4V-Converter.sh", "-i", "/process"]

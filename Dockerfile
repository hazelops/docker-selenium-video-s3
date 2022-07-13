FROM selenium/video:ffmpeg-4.3.1-20220706
LABEL authors="Dmitry Kireev <dmitry@hazelops.com>"

ARG PROJECT_PATH=./

ENV S3_BUCKET_NAME=""
ENV CUSTOM_TAG_NAME="selenium"

# Install extra tools
RUN \
  apt-get -qqy update && \
  apt-get -qqy --no-install-recommends install \
    curl unzip jq && \
  rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Install AWS Cli
RUN \
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" > /dev/null && \
  unzip awscliv2.zip && \
  ./aws/install

COPY $PROJECT_PATH/video.sh /opt/bin/

EXPOSE 9000

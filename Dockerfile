FROM debian:jessie

RUN \
  apt-get update -yq && \
  apt-get install -yq --no-install-recommends \
    build-essential \
    ca-certificates \
    curl
WORKDIR /app

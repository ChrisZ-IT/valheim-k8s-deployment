FROM debian:stable-slim

RUN <<EOF
apt-get update && apt-get upgrade -y
apt-get install curl libatomic1 libpulse-dev libpulse0 -y
rm -rf /var/lib/apt/lists/*
EOF

RUN useradd --no-log-init -u 1026 -g 100 -m -s /usr/sbin/nologin serviceuser

USER 1026:100
WORKDIR /data

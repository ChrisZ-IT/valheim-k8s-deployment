FROM ubuntu:26.04

RUN <<EOF
apt-get update
apt-get upgrade -y
apt-get install -y curl libatomic1 libpulse-dev libpulse0
EOF

USER 1000
WORKDIR /home/ubuntu